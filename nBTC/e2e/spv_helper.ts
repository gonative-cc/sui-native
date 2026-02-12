import { SuiClient } from "@mysten/sui/client";
import { fromHex } from "@mysten/sui/utils";
import { Transaction } from "@mysten/sui/transactions";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import { Transaction as BtcTransaction } from "bitcoinjs-lib";
import { BitcoinMerkleTree } from "./merkle";
import {
	readDeployInformation,
	DeployInformation,
} from "../../scripts/config";

export interface SpvProof {
	proof: string[];
	height: number;
	txIndex: number;
	txId: string;
	txHex: string;
}

export interface LightClientInfo {
	lcId: string;
	bitcoinLibPkg: string;
	spvPkg: string;
	currentHeight: number;
}

export interface IndexerConfig {
	baseUrl: string;
}

export class SpvHelper {
	private suiClient: SuiClient;
	private signer: Ed25519Keypair;
	private indexer: IndexerConfig;
	private lcInfo: LightClientInfo;

	constructor(
		suiClient: SuiClient,
		signer: Ed25519Keypair,
		lcInfo: LightClientInfo,
		indexer: IndexerConfig,
	) {
		this.suiClient = suiClient;
		this.signer = signer;
		this.lcInfo = lcInfo;
		this.indexer = indexer;
	}

	async getCurrentLightClientHeight(): Promise<number> {
		const lc = await this.suiClient.getObject({
			id: this.lcInfo.lcId,
			options: { showContent: true },
		});

		const content = lc.data?.content as { fields?: { height?: string | number } };
		return content?.fields?.height as number || 0;
	}

	async syncLightClientToHeight(targetHeight: number, batchSize: number = 30): Promise<void> {
		const currentHeight = await this.getCurrentLightClientHeight();
		if (currentHeight >= targetHeight) {
			console.log(`✓ Light client already at height ${currentHeight}`);
			return;
		}

		const blocksToSync = targetHeight - currentHeight;
		console.log(`🔄 Syncing light client: ${currentHeight} → ${targetHeight} (${blocksToSync} blocks)`);

		for (let batchStart = currentHeight; batchStart < targetHeight; batchStart += batchSize) {
			const batchEnd = Math.min(batchStart + batchSize, targetHeight);
			const blocks = await this.fetchHeadersRange(batchStart, batchEnd);

			if (blocks.length > 0) {
				await this.insertHeaders(blocks);
				console.log(`  → Inserted headers ${batchStart}-${batchEnd}`);
			}
		}

		console.log(`✓ Light client synced to height ${targetHeight}`);
	}

	private async fetchHeadersRange(startHeight: number, endHeight: number): Promise<string[]> {
		const headers: string[] = [];

		for (let h = startHeight; h < endHeight; h++) {
			const blockHash = await this.indexerCall(`/block-height/${h}`);
			const header = await this.indexerCall(`/block/${blockHash}/header`);
			if (header) headers.push(`0x${header.trim()}`);
		}

		return headers;
	}

	async insertHeaders(headers: string[]): Promise<void> {
		const tx = new Transaction();

		const headerObjs = headers.map((header) =>
			tx.moveCall({
				target: `${this.lcInfo.bitcoinLibPkg}::header::new`,
				arguments: [tx.pure("vector<u8>", Array.from(fromHex(header)))],
			})
		);

		const headerVec = tx.makeMoveVec({
			type: `${this.lcInfo.bitcoinLibPkg}::header::BlockHeader`,
			elements: headerObjs,
		});

		tx.moveCall({
			target: `${this.lcInfo.spvPkg}::light_client::insert_headers`,
			arguments: [tx.object(this.lcInfo.lcId), headerVec],
		});

		const result = await this.suiClient.signAndExecuteTransaction({
			transaction: tx,
			signer: this.signer,
			options: { showEffects: true, showEvents: true },
		});

		if (result.effects?.status?.status !== "success") {
			throw new Error(`Failed to insert headers: ${result.digest}`);
		}

		await this.suiClient.waitForTransaction({ digest: result.digest });
	}

	async generateSpvProof(txId: string, blockHeight?: number): Promise<SpvProof> {
		const txHex = await this.indexerCall(`/tx/${txId}/hex`);
		const blockHash = await this.indexerCall(`/tx/${txId}/block-hash`);
		const height = blockHeight !== undefined ? blockHeight : parseInt(await this.indexerCall(`/tx/${txId}/block-height`), 10);

		const merkleProof = await this.generateMerkleProof(txId, blockHash);

		const txIds = await this.indexerCall(`/block/${blockHash}/txids`);
		const allHashes = JSON.parse(txIds);
		const txIndex = allHashes.indexOf(txId.replace("0x", "").toLowerCase());

		return {
			proof: merkleProof,
			height,
			txIndex,
			txId,
			txHex,
		};
	}

	private async generateMerkleProof(txId: string, blockHash: string): Promise<string[]> {
		const txIds = await this.indexerCall(`/block/${blockHash}/txids`);
		const allTxIds: string[] = JSON.parse(txIds);

		const txs: BtcTransaction[] = [];

		for (const txIdHex of allTxIds) {
			const txHex = await this.indexerCall(`/tx/${txIdHex}/hex`);
			const tx = BtcTransaction.fromHex(txHex);
			txs.push(tx);
		}

		const merkleTree = new BitcoinMerkleTree(txs);

		const targetTx = txs.find(t => t.getId() === txId);
		if (!targetTx) {
			throw new Error(`Transaction ${txId} not found in block`);
		}

		const proofBuffers = merkleTree.getProof(targetTx);

		return proofBuffers.map(buf => buf.toString("hex"));
	}

	async syncToLatest(): Promise<number> {
		const tipHeight = parseInt(await this.indexerCall("/blocks/tip/height"), 10);
		await this.syncLightClientToHeight(tipHeight);
		return tipHeight;
	}

	private async indexerCall(endpoint: string): Promise<any> {
		if (!this.indexer) throw new Error("Indexer not configured");

		const response = await fetch(`${this.indexer.baseUrl}${endpoint}`);
		if (!response.ok) {
			throw new Error(`Indexer error: ${response.statusText}`);
		}
		return response.text();
	}

	static async fromDeployInfo(suiClient: SuiClient, signer: Ed25519Keypair): Promise<SpvHelper> {
		const deployInfo = readDeployInformation();

		if (!deployInfo.lc_contract || !deployInfo.bitcoin_lib_pkg || !deployInfo.lc_pkg) {
			throw new Error("Missing deployment info. Run deploy-nbtc.ts first.");
		}

		const lcInfo: LightClientInfo = {
			lcId: deployInfo.lc_contract,
			bitcoinLibPkg: deployInfo.bitcoin_lib_pkg,
			spvPkg: deployInfo.lc_pkg,
			currentHeight: deployInfo.height || 0,
		};

		const indexer = {
			baseUrl: process.env.INDEXER_URL || "http://localhost:8080/regtest",
		};

		if (!process.env.INDEXER_URL) {
			throw new Error("INDEXER_URL must be set");
		}

		console.log(`📋 Loaded deploy info:`);
		console.log(`   Sui Network: ${deployInfo.sui_network}`);
		console.log(`   Light Client: ${lcInfo.lcId}`);
		console.log(`   BTC Deposit: ${deployInfo.btc_address || "N/A"}`);
		console.log(`   nBTC Contract: ${deployInfo.nbtc_contract}`);

		return new SpvHelper(suiClient, signer, lcInfo, indexer);
	}
}
