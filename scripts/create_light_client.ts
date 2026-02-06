import { fromHex } from "@mysten/sui/utils";
import { getFullnodeUrl, SuiClient } from "@mysten/sui/client";
import { Transaction } from "@mysten/sui/transactions";
import "dotenv/config";
import { generateConfig, type LightClientConfig, DeployInformation } from "./config";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import { loadSigner } from "./utils";

export function createLightClient(config: LightClientConfig, tx: Transaction): Transaction {
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

export async function createLightClientAndGetId(
	config: LightClientConfig,
	signer: Ed25519Keypair,
	verbose: boolean = true,
): Promise<{ lightClientId: string; digest: string }> {
	const network = config.network as "mainnet" | "testnet" | "devnet" | "localnet";
	const client = new SuiClient({ url: getFullnodeUrl(network) });

	const tx = new Transaction();
	createLightClient(config, tx);

	if (verbose) console.log("Submitting light client transaction...");
	const lcResult = await client.signAndExecuteTransaction({
		transaction: tx,
		signer,
		options: { showEffects: true, showEvents: true, showObjectChanges: true },
	});

	if (verbose) console.log("Waiting for confirmation...");
	await client.waitForTransaction({ digest: lcResult.digest });

	if (lcResult.effects?.status?.status !== "success") {
		throw new Error(`Light client creation failed: ${lcResult.effects?.status}`);
	}

	const lightClientEvent = lcResult.events?.find(
		(event: any) =>
			event.type.includes("LightClientCreated") || event.type.includes("LightClient"),
	);

	if (!lightClientEvent) {
		throw new Error("LightClient event not found");
	}

	const lightClientId =
		(lightClientEvent as any).parsedJson?.light_client_id ||
		(lightClientEvent as any).parsedJson?.id;

	return { lightClientId, digest: lcResult.digest };
}

async function main(): Promise<void> {
	console.log(`Using indexer: ${process.env.INDEXER_URL || "http://localhost:8080/regtest"}\n`);
	const config = await generateConfig();
	const network = config.network as "mainnet" | "testnet" | "devnet" | "localnet";

	console.log(`Network: ${network}`);
	console.log(`SPV Package: ${config.spvPackageId}`);
	console.log(`Bitcoin Lib Package: ${config.bitcoinLibPackageId}`);
	console.log(`Headers: ${config.headers.length} blocks`);
	console.log(`Starting Height: ${config.btcHeight}`);

	const signer = loadSigner();

	console.log("\nSubmitting transaction...");
	const result = await createLightClientAndGetId(config, signer);

	console.log(`Transaction executed: ${result.digest}`);
}

if (import.meta.main) {
	main();
}
