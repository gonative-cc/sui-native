// Bitcoin SPV Light Client Initialization Script
// This script initializes a Simplified Payment Verification (SPV) light client on Sui
// by submitting Bitcoin block headers to the light client Move contract.

import { fromBase64, fromHex } from "@mysten/sui/utils";
import { getFullnodeUrl, SuiClient } from "@mysten/sui/client";
import { Transaction } from "@mysten/sui/transactions";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";

import "dotenv/config";
import type { AppConfig } from "./config";
import { getLightClientConfig } from "./config";

// Load signer from environment variables (MNEMONIC or WALLET_SK)
function loadSigner(): Ed25519Keypair {
	const mnemonic = process.env.MNEMONIC;
	const walletSk = process.env.WALLET_SK;

	if (!mnemonic && !walletSk) {
		throw new Error("Please set either WALLET_SK or MNEMONIC");
	}

	if (walletSk) {
		try {
			const sk = fromBase64(walletSk);
			return Ed25519Keypair.fromSecretKey(sk.slice(1));
		} catch (error) {
			throw new Error(
				`Invalid WALLET_SK format: ${error instanceof Error ? error.message : String(error)}`,
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

// Load and validate configuration from environment variables
function getEnvConfig(): AppConfig {
	// Get non-secret configuration
	const config = getLightClientConfig();

	// Add signer to create complete app config
	return {
		...config,
		signer: loadSigner(),
	};
}

// Create and configure light client initialization transaction
function createLightClient(config: AppConfig, tx: Transaction): Transaction {
	// Convert hex headers to Move objects
	const headers = config.headers.map((headerData) =>
		tx.moveCall({
			target: `${config.bitcoinLibPackageId}::header::new`,
			arguments: [tx.pure("vector<u8>", Array.from(fromHex(headerData)))],
		}),
	);

	// Create vector of block headers for Move call
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

// Main execution
try {
	// Load and validate configuration
	const appConfig = getEnvConfig();

	// Initialize Sui client with specified network
	const client = new SuiClient({
		url: getFullnodeUrl(appConfig.network as "mainnet" | "testnet" | "devnet" | "localnet"),
	});

	// Create transaction with light client initialization
	const tx = createLightClient(appConfig, new Transaction());

	// Execute transaction on Sui network
	const result = await client.signAndExecuteTransaction({
		transaction: tx,
		signer: appConfig.signer,
		options: {
			showEffects: true,
			showEvents: true,
			showObjectChanges: true,
		},
	});

	// Wait for transaction confirmation
	await client.waitForTransaction({ digest: result.digest });

	// Display transaction result
	console.log(`✅ Transaction executed: ${result.digest}`);

	// Show transaction events if available
	if (result.events?.[0]) {
		console.log("Events:", result.events[0].parsedJson);
	}

	// Check if transaction succeeded
	if (result.effects?.status?.status !== "success") {
		console.error("❌ Transaction failed:", result.effects?.status);
		process.exit(1);
	}
} catch (error) {
	console.error("❌ Error:", error);
	process.exit(1);
}
