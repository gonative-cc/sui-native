import { fromBase64, fromHex } from "@mysten/sui/utils";
import { getFullnodeUrl, SuiClient } from "@mysten/sui/client";
import { Transaction } from "@mysten/sui/transactions";
import "dotenv/config";
import { generateConfig, type LightClientConfig } from "./config";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";


function loadSigner(): Ed25519Keypair {
	const mnemonic = process.env.MNEMONIC;
	const encodedSk = process.env.ENCODE_SK;

	if (!mnemonic && !encodedSk) {
		throw new Error("Please set either ENCODE_SK or MNEMONIC in .env");
	}

	if (encodedSk) {
		try {
			const sk = fromBase64(encodedSk);
			return Ed25519Keypair.fromSecretKey(sk.slice(1));
		} catch (error) {
			throw new Error(
				`Invalid ENCODE_SK format: ${error instanceof Error ? error.message : String(error)}`,
			);
		}
	}

	if (mnemonic) {
		try {
			return Ed25519Keypair.deriveKeypair(mnemonic);
		} catch (error) {
			throw new Error(
				`Invalid MNEMONIC format: ${error instanceof Error ? error.message : String(error)}`,
			);
		}
	}

	throw new Error("No valid signer configuration found");
}

function createLightClient(config: LightClientConfig, tx: Transaction): Transaction {
	const headers = config.headers.map((headerData) =>
		tx.moveCall({
			target: `${config.bitcoinLibPackageId}::header::new`,
			arguments: [tx.pure("vector<u8>", Array.from(fromHex(headerData)))],
		}),
	);

	const headerVec = tx.makeMoveVec({
		type: `${config.bitcoinLibPackageId}::header::BlockHeader`,
		elements: headers,
	});

	tx.moveCall({
		target: `${config.spvPackageId}::light_client::initialize_light_client`,
		arguments: [
			tx.pure.u8(config.btcNetwork),
			tx.pure.u64(config.btcHeight),
			headerVec,
			tx.pure.u256(config.parentChainWork),
			tx.pure.u64(config.confirmationDepth),
		],
	});

	return tx;
}

console.error(`Using indexer: ${process.env.INDEXER_URL || "http://localhost:8080/regtest"}\n`);
const config = await generateConfig();

console.error(`\nNetwork: ${config.network}`);
console.error(`SPV Package: ${config.spvPackageId}`);
console.error(`Bitcoin Lib Package: ${config.bitcoinLibPackageId}`);
console.error(`Headers: ${config.headers.length} blocks`);
console.error(`Starting Height: ${config.btcHeight}`);

const signer = loadSigner();
const client = new SuiClient({
	url: getFullnodeUrl(config.network as "mainnet" | "testnet" | "devnet" | "localnet"),
});

console.error("\nSubmitting transaction...");
const result = await client.signAndExecuteTransaction({
	transaction: createLightClient(config, new Transaction()),
	signer,
	options: {
		showEffects: true,
		showEvents: true,
		showObjectChanges: true,
	},
});

console.error("Waiting for confirmation...");
await client.waitForTransaction({ digest: result.digest });

console.log(`\n✅ Transaction executed: ${result.digest}`);

if (result.effects?.status?.status !== "success") {
	console.error("❌ Transaction failed:", result.effects?.status);
	process.exit(1);
}

// Try to find LightClient from events
let foundLightClient = false;
if (result.events) {
	const lightClientEvent = result.events.find((event: any) =>
		event.type.includes("LightClientCreated") || event.type.includes("LightClient")
	);
	if (lightClientEvent) {
		console.log(`\nLightClient Event:`, JSON.stringify(lightClientEvent.parsedJson, null, 2));
		foundLightClient = true;
	}
}

// Fallback: check objectChanges
if (!foundLightClient && result.objectChanges) {
	for (const change of result.objectChanges) {
		if (change.type === "created" && (change as any).objectType?.includes("LightClient")) {
			console.log(`\nLightClient Object ID: ${(change as any).objectId}`);
			console.log(`Object Type: ${(change as any).objectType}`);
			foundLightClient = true;
			break;
		}
	}
}
