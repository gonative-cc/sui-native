#!/usr/bin/env bun zx
import { $ } from "zx";
import { readFileSync, writeFileSync } from "fs";
import { join } from "path";
import { fileURLToPath } from "url";
import { getNetworkConfig, Network } from "@ika.xyz/sdk";
import * as toml from "smol-toml";
import "dotenv/config";
import { getPublishedPackageId } from "./config";

const SCRIPT_DIR = fileURLToPath(new URL(".", import.meta.url));
const PROJECT_ROOT = join(SCRIPT_DIR, "..");

async function getActiveNetwork(): Promise<Network> {
	const output = await $`sui client active-env`.quiet();
	return output.stdout.trim() as Network;
}

function formatDependenciesInline(parsed: any): string {
	const tomlLines: string[] = [];

	for (const [key, value] of Object.entries(parsed)) {
		if (key === "dependencies") {
			tomlLines.push("[dependencies]");
			for (const [name, dep] of Object.entries(value as Record<string, unknown>)) {
				const entries = Object.entries(dep as Record<string, unknown>)
					.map(([k, val]) => `${k} = "${val}"`)
					.join(", ");
				tomlLines.push(`${name} = { ${entries} }`);
			}
			tomlLines.push("");
		} else {
			tomlLines.push(toml.stringify({ [key]: value }).trim());
			tomlLines.push("");
		}
	}

	return tomlLines.join("\n").trim();
}

function updateNBTCToml(network: Network): void {
	const nbtctomlPath = join(PROJECT_ROOT, "nBTC", "Move.toml");
	const config = getNetworkConfig(network);
	const coordinatorId = config.objects.ikaDWalletCoordinator.objectID;

	const parsed = toml.parse(readFileSync(nbtctomlPath, "utf-8")) as any;

	// Update addresses from .env
	if (process.env.BITCOIN_LC) {
		parsed.addresses.bitcoin_lc = process.env.BITCOIN_LC;
	}
	if (process.env.FALLBACK_ADDR) {
		parsed.addresses.fallback_addr = process.env.FALLBACK_ADDR;
	}

	// Update ika_coordinator from SDK
	parsed.addresses.ika_coordinator = coordinatorId;

	const tomlString = formatDependenciesInline(parsed);
	writeFileSync(nbtctomlPath, tomlString);
	console.log(`Updated nBTC addresses:`);
	console.log(`  bitcoin_lc: ${parsed.addresses.bitcoin_lc}`);
	console.log(`  fallback_addr: ${parsed.addresses.fallback_addr}`);
	console.log(`  ika_coordinator: ${parsed.addresses.ika_coordinator}`);
}

async function publishPackage(packageName: string, network: string, force: boolean): Promise<void> {
	if (!force) {
		const publishedId = getPublishedPackageId(packageName, network);
		if (publishedId) {
			console.log(`${packageName} already published at ${publishedId}`);
			return;
		}
	}

	const packagePath = join(PROJECT_ROOT, packageName);
	console.log(`Publishing ${packageName}${force ? " (republish)" : ""}...`);

	if (packageName === "nBTC") {
		updateNBTCToml(network as Network);
	}

	$.cwd = packagePath;
	await $`sui move build --skip-fetch-latest-git-deps`;
	await $`sui client publish --gas-budget 1000000000`;
}

async function publishWithDependencies(
	packageName: string,
	network: string,
	force: boolean
): Promise<void> {
	const packageIndex = packages.indexOf(packageName);
	if (packageIndex === -1) {
		throw new Error(`Unknown package: ${packageName}. Available packages: ${packages.join(", ")}`);
	}

	for (let i = 0; i < packageIndex; i++) {
		const dep = packages[i]!;
		const depId = getPublishedPackageId(dep, network);
		if (!depId || force) {
			console.log(`Deploying dependency ${dep} first...`);
			await publishPackage(dep, network, force);
		} else {
			console.log(`Dependency ${dep} already published at ${depId}`);
		}
	}

	await publishPackage(packageName, network, force);
}

const packages = [
	"bitcoin_lib",
	"bitcoin_spv",
	"nBTC",
];

async function main(): Promise<void> {
	const args = process.argv.slice(2);
	const force = args.includes("--republish") || args.includes("-f");

	const packageArg = args.find((arg) => !arg.startsWith("-"));
	const packagesToPublish = packageArg ? [packageArg] : packages;

	const network = await getActiveNetwork();
	console.log(`Active network: ${network}${force ? " (republish all)" : ""}`);
	console.log(`Publishing: ${packagesToPublish.join(", ")}`);

	try {
		for (const pkg of packagesToPublish) {
			await publishWithDependencies(pkg, network, force);
		}
		console.log("Publishing completed");
	} catch (error) {
		console.error("Publishing failed:", error);
		process.exit(1);
	}
}

main();
