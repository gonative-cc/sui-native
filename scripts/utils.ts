#!/usr/bin/env bun
import { $ } from "zx";
import { readFileSync, writeFileSync } from "fs";
import { join } from "path";
import { getNetworkConfig, Network } from "@ika.xyz/sdk";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import * as toml from "smol-toml";

export const SCRIPT_DIR = new URL(".", import.meta.url).pathname;
export const PROJECT_ROOT = join(SCRIPT_DIR, "..");

export async function getActiveNetwork(): Promise<Network> {
	const output = await $`sui client active-env`.quiet();
	return output.stdout.trim() as Network;
}

export function loadSigner(): Ed25519Keypair {
	const mnemonic = process.env.MNEMONIC;
	const encodedSk = process.env.ENCODE_SK;

	if (!mnemonic && !encodedSk) {
		throw new Error("Please set either ENCODE_SK or MNEMONIC in .env");
	}

	if (encodedSk) {
		const sk = Buffer.from(encodedSk, "base64");
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

	updateNBTCTomlWithValues(
		process.env.BITCOIN_LC,
		process.env.FALLBACK_ADDR,
		coordinatorId
	);
}

export function updateNBTCTomlWithValues(
	bitcoin_lc?: string,
	fallback_addr?: string,
	ika_coordinator?: string,
): void {
	const nbtctomlPath = join(PROJECT_ROOT, "nBTC", "Move.toml");

	let tomlContent = readFileSync(nbtctomlPath, "utf-8");

	if (bitcoin_lc) {
		tomlContent = tomlContent.replace(/bitcoin_lc\s*=\s*"([^"]*)"/, `bitcoin_lc = "${bitcoin_lc}"`);
	}
	if (fallback_addr) {
		tomlContent = tomlContent.replace(/fallback_addr\s*=\s*"([^"]*)"/, `fallback_addr = "${fallback_addr}"`);
	}
	if (ika_coordinator) {
		tomlContent = tomlContent.replace(/ika_coordinator\s*=\s*"([^"]*)"/, `ika_coordinator = "${ika_coordinator}"`);
	}

	writeFileSync(nbtctomlPath, tomlContent);

	const parsed = toml.parse(tomlContent) as any;
	console.error(`Updated nBTC addresses:`);
	console.error(`  bitcoin_lc: ${parsed.addresses.bitcoin_lc}`);
	console.error(`  fallback_addr: ${parsed.addresses.fallback_addr}`);
	console.error(`  ika_coordinator: ${parsed.addresses.ika_coordinator}`);
}
