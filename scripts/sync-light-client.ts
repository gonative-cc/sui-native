#!/usr/bin/env bun
import "dotenv/config";
import { SuiClient } from "@mysten/sui/client";
import { Transaction } from "@mysten/sui/transactions";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import { fromHex } from "@mysten/sui/utils";
import { getFullnodeUrl } from "@mysten/sui/client";
import { readDeployInformation } from "./config";
import {
	getBlockByHeight,
	getBlockHeader,
	getTipHeight,
	fetchHeadersRange,
	INDEXER_URL,
} from "./indexer";
import { getActiveNetwork } from "./utils";

export async function getLightClientHeight(
	suiClient: SuiClient,
	lcContract: string,
): Promise<number> {
	const lc = await suiClient.getObject({
		id: lcContract,
		options: { showContent: true },
	});

	const content = lc.data?.content as { fields?: { head_height?: string } };
	return parseInt(content?.fields?.head_height as string) || 0;
}

async function insertHeaders(
	suiClient: SuiClient,
	signer: Ed25519Keypair,
	bitcoinLibPkg: string,
	spvPkg: string,
	lcContract: string,
	headers: string[],
): Promise<void> {
	const tx = new Transaction();

	const headerObjs = headers.map((header) =>
		tx.moveCall({
			target: `${bitcoinLibPkg}::header::new`,
			arguments: [tx.pure("vector<u8>", Array.from(fromHex(header)))],
		}),
	);

	const headerVec = tx.makeMoveVec({
		type: `${bitcoinLibPkg}::header::BlockHeader`,
		elements: headerObjs,
	});

	tx.moveCall({
		target: `${spvPkg}::light_client::insert_headers`,
		arguments: [tx.object(lcContract), headerVec],
	});

	tx.setGasBudget(500000000);
	const result = await suiClient.signAndExecuteTransaction({
		transaction: tx,
		signer,
		options: { showEffects: true, showEvents: true },
	});

	if (result.effects?.status?.status !== "success") {
		throw new Error(`Failed to insert headers: ${result.digest}`);
	}

	await suiClient.waitForTransaction({ digest: result.digest });
}

export async function syncToHeight(
	suiClient: SuiClient,
	signer: Ed25519Keypair,
	bitcoinLibPkg: string,
	spvPkg: string,
	lcContract: string,
	targetHeight: number,
	batchSize: number = 30,
): Promise<void> {
	const currentHeight = await getLightClientHeight(suiClient, lcContract);
	if (currentHeight >= targetHeight) {
		console.log(`✓ Light client already at height ${currentHeight}`);
		return;
	}

	const blocksToSync = targetHeight - currentHeight;
	console.log(
		`🔄 Syncing light client: ${currentHeight} → ${targetHeight} (${blocksToSync} blocks)`,
	);

	for (let batchStart = currentHeight + 1; batchStart <= targetHeight; batchStart += batchSize) {
		const batchEnd = Math.min(batchStart + batchSize, targetHeight);
		const blocks = await fetchHeadersRange(batchStart, batchEnd);

		if (blocks.length > 0) {
			await insertHeaders(suiClient, signer, bitcoinLibPkg, spvPkg, lcContract, blocks);
			console.log(`  → Inserted headers ${batchStart}-${batchEnd}`);
		}
	}

	console.log(`✓ Light client synced to height ${targetHeight}`);
}

function getSuiSigner(): Ed25519Keypair {
	const mnemonic = process.env.MNEMONIC;
	const walletSk = process.env.WALLET_SK;
	if (walletSk) {
		const sk = Buffer.from(walletSk, "base64");
		return Ed25519Keypair.fromSecretKey(sk.subarray(1));
	}
	if (mnemonic) {
		return Ed25519Keypair.deriveKeypair(mnemonic);
	}
	throw new Error("Please set either WALLET_SK or MNEMONIC in .env");
}

async function main() {
	const args = process.argv.slice(2);

	if (args.length > 0 && args[0] === "--help") {
		console.log("Usage:");
		console.log("  bun run scripts/sync-light-client.ts    - Sync to latest tip");
		console.log("  bun run scripts/sync-light-client.ts --help");
		process.exit(0);
	}

	const deployInfo = readDeployInformation();

	if (!deployInfo.bitcoin_lib_pkg || !deployInfo.lc_pkg || !deployInfo.lc_contract) {
		throw new Error("Missing deployment info (bitcoin_lib_pkg, lc_pkg, lc_contract)");
	}

	const bitcoinLibPkg = deployInfo.bitcoin_lib_pkg!;
	const spvPkg = deployInfo.lc_pkg!;
	const lcContract = deployInfo.lc_contract!;

	const network = await getActiveNetwork();
	const suiClient = new SuiClient({ url: getFullnodeUrl(network) });
	const signer = getSuiSigner();

	const currentHeight = await getLightClientHeight(suiClient, lcContract);
	console.log(`Current light client height: ${currentHeight}`);

	const targetHeight = await getTipHeight();
	console.log(`Syncing to latest tip: ${targetHeight}`);

	await syncToHeight(suiClient, signer, bitcoinLibPkg, spvPkg, lcContract, targetHeight);

	console.log("\n✅ Sync completed successfully!");
}

if (import.meta.main) {
	main().catch((err) => {
		console.error("Error:", err);
		process.exit(1);
	});
}
