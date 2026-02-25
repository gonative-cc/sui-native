import { SuiClient } from "@mysten/sui/client";
import { fromHex } from "@mysten/sui/utils";
import { Transaction } from "@mysten/sui/transactions";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import { Transaction as BtcTransaction } from "bitcoinjs-lib";
import { BitcoinMerkleTree } from "./merkle";
import { readDeployInformation, DeployInformation } from "../scripts/config";
import {
	getBlockHash,
	getBlockHeader,
	getTxHex,
	getTxStatus,
	getBlockTxs,
	getTipHeight,
	fetchHeadersRange,
} from "../scripts/indexer";

export interface SpvProof {
	proof: string[];
	height: number;
	txIndex: number;
	txId: string;
	txHex: string;
}

export class SpvHelper {
	private suiClient: SuiClient;
	private signer: Ed25519Keypair;
	private deployInfo: DeployInformation;

	constructor(suiClient: SuiClient, signer: Ed25519Keypair, deployInfo: DeployInformation) {
		this.suiClient = suiClient;
		this.signer = signer;
		this.deployInfo = deployInfo;
	}

	async getCurrentLightClientHeight(): Promise<number> {
		const lc = await this.suiClient.getObject({
			id: this.deployInfo.lc_contract!,
			options: { showContent: true },
		});

		const content = lc.data?.content as { fields?: { head_height?: string } };
		return parseInt(content?.fields?.head_height as string) || 0;
	}

	async syncLightClientToHeight(targetHeight: number, batchSize: number = 30): Promise<void> {
		const currentHeight = await this.getCurrentLightClientHeight();
		if (currentHeight >= targetHeight) {
			console.log(`✓ Light client already at height ${currentHeight}`);
			return;
		}

		const blocksToSync = targetHeight - currentHeight;
		console.log(
			`🔄 Syncing light client: ${currentHeight} → ${targetHeight} (${blocksToSync} blocks)`,
		);

		for (
			let batchStart = currentHeight + 1;
			batchStart <= targetHeight;
			batchStart += batchSize
		) {
			const batchEnd = Math.min(batchStart + batchSize - 1, targetHeight);
			const blocks = await fetchHeadersRange(batchStart, batchEnd);

			if (blocks.length > 0) {
				await this.insertHeaders(blocks);
				console.log(`  → Inserted headers ${batchStart}-${batchEnd}`);
			}
		}

		console.log(`✓ Light client synced to height ${targetHeight}`);
	}

	async insertHeaders(headers: string[]): Promise<void> {
		const tx = new Transaction();

		const headerObjs = headers.map((header) =>
			tx.moveCall({
				target: `${this.deployInfo.bitcoin_lib_pkg}::header::new`,
				arguments: [tx.pure("vector<u8>", Array.from(fromHex(header)))],
			}),
		);

		const headerVec = tx.makeMoveVec({
			type: `${this.deployInfo.bitcoin_lib_pkg}::header::BlockHeader`,
			elements: headerObjs,
		});

		tx.moveCall({
			target: `${this.deployInfo.lc_pkg}::light_client::insert_headers`,
			arguments: [tx.object(this.deployInfo.lc_contract!), headerVec],
		});

		tx.setGasBudget(500000000);
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
		const txHex = await getTxHex(txId);

		// Get transaction status to find block height
		const status = await getTxStatus(txId);
		if (!status.confirmed || !status.block_height) {
			throw new Error(`Transaction ${txId} is not confirmed`);
		}

		const height = blockHeight !== undefined ? blockHeight : status.block_height;

		// Get block hash by height (standard API)
		const blockHash = await getBlockHash(height);

		const merkleProof = await this.generateMerkleProof(txId, blockHash);

		const txIds = await getBlockTxs(blockHash);
		const txIndex = txIds.indexOf(txId.replace("0x", "").toLowerCase());

		return {
			proof: merkleProof,
			height,
			txIndex,
			txId,
			txHex,
		};
	}

	private async generateMerkleProof(txId: string, blockHash: string): Promise<string[]> {
		const allTxIds = await getBlockTxs(blockHash);

		const txs: BtcTransaction[] = [];

		for (const txIdHex of allTxIds) {
			const txHex = await getTxHex(txIdHex);
			const tx = BtcTransaction.fromHex(txHex);
			txs.push(tx);
		}

		const merkleTree = new BitcoinMerkleTree(txs);

		const targetTx = txs.find((t) => t.getId() === txId);
		if (!targetTx) {
			throw new Error(`Transaction ${txId} not found in block`);
		}

		const proofBuffers = merkleTree.getProof(targetTx);

		return proofBuffers.map((buf) => buf.toString("hex"));
	}

	async syncToLatest(): Promise<number> {
		const tipHeight = await getTipHeight();
		await this.syncLightClientToHeight(tipHeight);
		return tipHeight;
	}

	static async fromDeployInfo(suiClient: SuiClient, signer: Ed25519Keypair): Promise<SpvHelper> {
		const deployInfo = readDeployInformation();

		if (!deployInfo.lc_contract || !deployInfo.bitcoin_lib_pkg || !deployInfo.lc_pkg) {
			throw new Error("Missing deployment info. Run deploy-nbtc.ts first.");
		}

		console.log(`📋 Loaded deploy info:`);
		console.log(`   Sui Network: ${deployInfo.sui_network}`);
		console.log(`   Light Client: ${deployInfo.lc_contract}`);
		console.log(`   BTC Deposit: ${deployInfo.btc_address || "N/A"}`);
		console.log(`   nBTC Contract: ${deployInfo.nbtc_contract}`);
		console.log(signer.toSuiAddress());

		return new SpvHelper(suiClient, signer, deployInfo);
	}
}
