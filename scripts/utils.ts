#!/usr/bin/env bun
import { $ } from "zx";
import { readFileSync, writeFileSync } from "fs";
import { join } from "path";
import { getNetworkConfig, Network } from "@ika.xyz/sdk";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";

export const SCRIPT_DIR = new URL(".", import.meta.url).pathname;
export const PROJECT_ROOT = join(SCRIPT_DIR, "..");

export function getSuiCommand(): string {
	return process.env.SUI_PATH || "sui";
}

export async function getActiveNetwork(): Promise<Network> {
	const suiCommand = getSuiCommand();
	const output = await $`${suiCommand} client active-env`.quiet();
	return output.stdout.trim() as Network;
}

export function loadSigner(): Ed25519Keypair {
	const mnemonic = process.env.MNEMONIC;
	const walletSk = process.env.WALLET_SK;
	if (!mnemonic && !walletSk) {
		throw new Error("Please set either WALLET_SK or MNEMONIC in .env");
	}

	if (walletSk) {
		const sk = Buffer.from(walletSk, "base64");
		return Ed25519Keypair.fromSecretKey(sk.subarray(1));
	}

	if (mnemonic) {
		return Ed25519Keypair.deriveKeypair(mnemonic);
	}

	throw new Error("No valid signer configuration found");
}

export function updateNBTCToml(network: Network): void {
	const config = getNetworkConfig(network);
	const coordinatorId = config.objects.ikaDWalletCoordinator.objectID;

	updateNBTCTomlWithValues(process.env.BITCOIN_LC, process.env.FALLBACK_ADDR, coordinatorId);
}

export function updateNBTCTomlWithValues(
	bitcoin_lc?: string,
	fallback_addr?: string,
	ika_coordinator?: string,
): void {
	const nbtctomlPath = join(PROJECT_ROOT, "nBTC", "Move.toml");

	let tomlContent = readFileSync(nbtctomlPath, "utf-8");

	if (bitcoin_lc) {
		tomlContent = tomlContent.replace(
			/bitcoin_lc\s*=\s*"([^"]*)"/,
			`bitcoin_lc = "${bitcoin_lc}"`,
		);
	}
	if (fallback_addr) {
		tomlContent = tomlContent.replace(
			/fallback_addr\s*=\s*"([^"]*)"/,
			`fallback_addr = "${fallback_addr}"`,
		);
	}
	if (ika_coordinator) {
		tomlContent = tomlContent.replace(
			/ika_coordinator\s*=\s*"([^"]*)"/,
			`ika_coordinator = "${ika_coordinator}"`,
		);
	}

	writeFileSync(nbtctomlPath, tomlContent);
}
