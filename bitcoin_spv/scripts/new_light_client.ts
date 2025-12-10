// Bitcoin SPV Light Client Initialization Script
// This script initializes a Simplified Payment Verification (SPV) light client on Sui
// by submitting Bitcoin block headers to the light client Move contract.

import { fromHex, fromBase64 } from "@mysten/sui/utils";
import { getFullnodeUrl, SuiClient } from "@mysten/sui/client";
import { Transaction } from "@mysten/sui/transactions";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";

import "dotenv/config";

// Configuration interface for light client initialization
interface AppConfig {
	spvPackageId: string;
	bitcoinLibPackageId: string;
	network: string;
	headers: string[];
	btcNetwork: number;
	btcHeight: number;
	parentChainWork: string;
	confirmationDepth: number;
	signer: Ed25519Keypair;
}

// Load signer from environment variables (MNEMONIC or ENCODE_SK)
function loadSigner(): Ed25519Keypair {
	const mnemonic = process.env.MNEMONIC;
	const encodedSk = process.env.ENCODE_SK;

	if (!mnemonic && !encodedSk) {
		throw new Error("Please set either ENCODE_SK or MNEMONIC");
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

// Load and validate configuration from environment variables
function getEnvConfig(): AppConfig {
	const env = process.env;

	// Validate all required environment variables exist
	const requiredVars = [
		"SPV_PACKAGE_ID",
		"BITCOIN_LIB_PACKAGE_ID",
		"HEADERS",
		"BTC_HEIGHT",
		"PARENT_CHAIN_WORK",
		"CONFIRMATION_DEPTH",
	];

	for (const varName of requiredVars) {
		if (!env[varName]) {
			throw new Error(`${varName} is required`);
		}
	}

	// Validate network type (defaults to testnet)
	const network = env.NETWORK || "testnet";
	const validNetworks = ["mainnet", "testnet", "devnet", "localnet"];
	if (!validNetworks.includes(network)) {
		throw new Error(`Invalid NETWORK: ${network}. Must be one of: ${validNetworks.join(", ")}`);
	}

	// Validate Bitcoin block headers format
	// - Must be comma-separated hex-encoded headers starting with 0x
	// - Each header must be exactly 80 bytes (160 hex characters)
	const validateHeaders = (headers: string): string[] => {
		const headerList = headers.split(",").map((h) => h.trim());

		// Ensure at least one header is provided
		if (headerList.length === 0) {
			throw new Error("At least one header is required");
		}

		for (const header of headerList) {
			if (!header.startsWith("0x")) {
				throw new Error(`Each header must start with 0x, found: ${header}`);
			}

			const hexData = header.slice(2); // Remove 0x prefix
			if (hexData.length !== 160) {
				// 80 bytes = 160 hex characters
				throw new Error(
					`Each header must be exactly 80 bytes (160 hex chars), found ${hexData.length} chars for: ${header}`,
				);
			}

			// Verify valid hexadecimal characters
			if (!/^[0-9a-fA-F]+$/.test(hexData)) {
				throw new Error(`Header contains invalid hex characters: ${header}`);
			}
		}

		return headerList;
	};

	return {
		spvPackageId: env.SPV_PACKAGE_ID!,
		bitcoinLibPackageId: env.BITCOIN_LIB_PACKAGE_ID!,
		network: network,
		headers: validateHeaders(env.HEADERS!),
		btcNetwork: Number(env.BTC_NETWORK || 2), // Default to regtest (2) if not provided
		btcHeight: Number(env.BTC_HEIGHT),
		parentChainWork: env.PARENT_CHAIN_WORK!,
		confirmationDepth: Number(env.CONFIRMATION_DEPTH),
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
