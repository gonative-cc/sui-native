#!/usr/bin/env bun
import { $ } from "zx";
import { readFileSync, writeFileSync } from "fs";
import { join } from "path";
import { getNetworkConfig, Network } from "@ika.xyz/sdk";
import * as toml from "smol-toml";

export const SCRIPT_DIR = new URL(".", import.meta.url).pathname;
export const PROJECT_ROOT = join(SCRIPT_DIR, "..");

export async function getActiveNetwork(): Promise<Network> {
	const output = await $`sui client active-env`.quiet();
	return output.stdout.trim() as Network;
}

export function updateNBTCToml(network: Network): void {
	const nbtctomlPath = join(PROJECT_ROOT, "nBTC", "Move.toml");
	const config = getNetworkConfig(network);
	const coordinatorId = config.objects.ikaDWalletCoordinator.objectID;

	let tomlContent = readFileSync(nbtctomlPath, "utf-8");

	if (process.env.BITCOIN_LC) {
		tomlContent = tomlContent.replace(/bitcoin_lc\s*=\s*"([^"]*)"/, `bitcoin_lc = "${process.env.BITCOIN_LC}"`);
	}
	if (process.env.FALLBACK_ADDR) {
		tomlContent = tomlContent.replace(/fallback_addr\s*=\s*"([^"]*)"/, `fallback_addr = "${process.env.FALLBACK_ADDR}"`);
	}
	tomlContent = tomlContent.replace(/ika_coordinator\s*=\s*"([^"]*)"/, `ika_coordinator = "${coordinatorId}"`);

	writeFileSync(nbtctomlPath, tomlContent);

	const parsed = toml.parse(tomlContent) as any;
	console.log(`Updated nBTC addresses:`);
	console.log(`  bitcoin_lc: ${parsed.addresses.bitcoin_lc}`);
	console.log(`  fallback_addr: ${parsed.addresses.fallback_addr}`);
	console.log(`  ika_coordinator: ${parsed.addresses.ika_coordinator}`);
}
