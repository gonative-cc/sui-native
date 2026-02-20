#!/usr/bin/env bun
import "dotenv/config";
import { Transaction } from "@mysten/sui/transactions";
import { getFullnodeUrl, SuiClient } from "@mysten/sui/client";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import * as bitcoin from "bitcoinjs-lib";
import * as tinysecp from "tiny-secp256k1";
import { readDeployInformation } from "./config";
import { getActiveNetwork } from "./utils";
import { mint as mintMove } from "../sdk/nBTC/generated/nbtc/nbtc";
import { BitcoinMerkleTree } from "../e2e/merkle";
import { syncToHeight } from "./sync-light-client";
import { getTxStatus, getBlockTxs, getBlockHash, getTxHex, getBlockTransactions } from "./indexer";

bitcoin.initEccLib(tinysecp);

function getSuiClient(packageId: string, network: string): SuiClient {
	return new SuiClient({
		url: getFullnodeUrl(network as "mainnet" | "testnet" | "devnet" | "localnet"),
		mvr: {
			overrides: {
				packages: {
					"@local-pkg/nbtc": packageId,
				},
			},
		},
	});
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

async function generateSpvProofLocal(txHex: string, blockHash: string): Promise<string[]> {
	const txid = bitcoin.Transaction.fromHex(txHex).getId();

	console.log(`  Fetching all transactions in block...`);
	const blockTxHexes = await getBlockTransactions(blockHash);
	console.log(`  Found ${blockTxHexes.length} transactions`);
	console.log(`  Building merkle tree...`);
	const transactions = blockTxHexes.map((hex) =>
		bitcoin.Transaction.fromHex(hex.toString("hex")),
	);
	const merkleTree = new BitcoinMerkleTree(transactions);

	const targetTx = bitcoin.Transaction.fromHex(txHex);

	console.log(`  Generating merkle proof for transaction ${txid}...`);
	const proof = merkleTree.getProof(targetTx);

	return proof.map((p) => p.toString("hex"));
}

export async function getTxInfo(txid: string): Promise<{ height: number; txIndex: number }> {
	const status = await getTxStatus(txid);
	if (!status.confirmed || !status.block_height) {
		throw new Error(`Transaction ${txid} is not confirmed`);
	}
	const blockHash = await getBlockHash(status.block_height);
	const txids = await getBlockTxs(blockHash);
	const txIndex = txids.indexOf(txid);
	if (txIndex < 0) {
		throw new Error(`Transaction ${txid} not found in block`);
	}
	return { height: status.block_height, txIndex };
}

export async function mintNbtc(
	params: {
		nbtcPkg: string;
		nbtcContract: string;
		lcContract: string;
		bitcoinLibPkg: string;
		spvPkg: string;
		btcTxHex: string;
		height: number;
		txIndex: number;
		btcAddress: string;
		applyFee: boolean;
	},
	signer?: Ed25519Keypair,
): Promise<{ digest: string; utxoIdx: number; btcAmount: number }> {
	const network = await getActiveNetwork();
	const suiClient = getSuiClient(params.nbtcPkg, network);
	const txSigner = signer || getSuiSigner();

	console.log(`\nSyncing light client to height ${params.height}...`);
	await syncToHeight(
		suiClient,
		txSigner,
		params.bitcoinLibPkg,
		params.spvPkg,
		params.lcContract,
		params.height + 3,
	);
	console.log("✓ Light client synced");

	const blockHash = await getBlockHash(params.height);

	console.log("Generating merkle proof locally...");
	const proof = await generateSpvProofLocal(params.btcTxHex, blockHash);
	console.log("✓ Merkle proof generated");

	const tx = new Transaction();

	tx.add(
		mintMove({
			package: params.nbtcPkg,
			arguments: {
				contract: params.nbtcContract,
				lightClient: params.lcContract,
				dwalletBtcaddr: params.btcAddress,
				txBytes: Array.from(Buffer.from(params.btcTxHex, "hex")),
				proof: proof.map((p: string) => Array.from(Buffer.from(p, "hex"))),
				height: BigInt(params.height),
				txIndex: BigInt(params.txIndex),
				payload: [],
				opsArg: params.applyFee ? 1 : 0,
			},
		}),
	);

	const result = await suiClient.signAndExecuteTransaction({
		transaction: tx,
		signer: txSigner,
		options: { showEvents: true, showEffects: true },
	});

	console.log("Mint transaction digest:", result.digest);

	const mintEvent = result.events?.find((e) => e.type.includes("MintEvent"));
	if (mintEvent) {
		console.log("Mint event:", JSON.stringify(mintEvent.parsedJson, null, 2));
		const parsed = mintEvent.parsedJson as any;
		return {
			digest: result.digest,
			utxoIdx: parsed.utxo_id,
			btcAmount: parsed.btc_amount,
		};
	}

	throw new Error("MintEvent not found");
}

async function main() {
	const args = process.argv.slice(2);

	if (args.length === 0) {
		console.log("Usage:");
		console.log("  bun run scripts/mint.ts info                    - Show deposit address");
		console.log("  bun run scripts/mint.ts mint <txid>             - Auto-sync and mint");
		console.log(
			"  bun run scripts/mint.ts mint <txid> <h> <idx>   - Mint with known height/index",
		);
		console.log(
			"\nFirst, send BTC to the dWallet address with OP_RETURN containing your Sui address",
		);
		console.log("OP_RETURN format: 0x00 + 32-byte Sui address (without 0x prefix)");
		process.exit(1);
	}

	const deployInfo = readDeployInformation();

	const nbtcContract = deployInfo.nbtc_contract;
	const lcContract = deployInfo.lc_contract;
	const btcAddress = deployInfo.btc_address;
	const nbtcPkg = deployInfo.nbtc_pkg;
	const bitcoinLibPkg = deployInfo.bitcoin_lib_pkg;
	const spvPkg = deployInfo.lc_pkg;

	if (!nbtcContract || !lcContract || !btcAddress || !nbtcPkg || !bitcoinLibPkg || !spvPkg) {
		throw new Error("Missing deployment info. Run deploy-nbtc first.");
	}

	const command = args[0];

	if (command === "info") {
		console.log("=== Deposit Information ===");
		console.log(`dWallet BTC Address: ${btcAddress}`);
		console.log(
			"\nSend BTC to the dWallet address with OP_RETURN containing the recipient's Sui address",
		);
		console.log("OP_RETURN format: 0x00 + 32-byte Sui address (without 0x prefix)");
	} else if (command === "mint") {
		const txid = args[1];
		if (!txid) {
			throw new Error("Missing txid");
		}

		let height: number;
		let txIndex: number;

		if (args[2] && args[3]) {
			height = parseInt(args[2], 10);
			txIndex = parseInt(args[3], 10);
			if (isNaN(height) || isNaN(txIndex)) {
				throw new Error("Invalid height or txIndex");
			}
		} else {
			console.log(`\nFetching transaction info for ${txid}...`);
			const confirmResult = await getTxInfo(txid);
			height = confirmResult.height;
			txIndex = confirmResult.txIndex;
		}

		console.log(`\nConfirmed at height ${height}, index ${txIndex}`);

		const txHex = await getTxHex(txid);

		console.log("\n=== Minting nBTC ===");
		await mintNbtc({
			nbtcPkg,
			nbtcContract,
			lcContract,
			bitcoinLibPkg,
			spvPkg,
			btcTxHex: txHex,
			height,
			txIndex,
			btcAddress,
			applyFee: true,
		});

		console.log("\nMint completed successfully!");
	} else {
		throw new Error(`Unknown command: ${command}`);
	}
}

if (import.meta.main) {
	main().catch((err) => {
		console.error("Error:", err);
		process.exit(1);
	});
}
