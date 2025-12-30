#!/usr/bin/env bun zx
import { $ } from "zx";
import { join } from "path";
import { Network } from "@ika.xyz/sdk";
import "dotenv/config";
import { getPublishedPackageId } from "./config";
import { PROJECT_ROOT, getActiveNetwork, updateNBTCToml } from "./utils";

const Packages = [
	"bitcoin_lib",
	"bitcoin_spv",
	"nBTC",
];

async function publishPackage(packageName: string, network: Network, force: boolean): Promise<void> {
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
		updateNBTCToml(network);
	}

	$.cwd = packagePath;
	await $`sui client publish --gas-budget 1000000000`;
}

async function publishWithDependencies(
	packageName: string,
	network: Network,
	force: boolean,
	forceAll: boolean
): Promise<void> {
	const packageIndex = Packages.indexOf(packageName);
	if (packageIndex === -1) {
		throw new Error(`Unknown package: ${packageName}. Available packages: ${Packages.join(", ")}`);
	}

	for (let i = 0; i < packageIndex; i++) {
		const dep = Packages[i]!;
		const depId = getPublishedPackageId(dep, network);
		if (!depId || forceAll) {
			console.log(`Deploying dependency ${dep} first...`);
			await publishPackage(dep, network, forceAll);
		} else {
			console.log(`Dependency ${dep} already published at ${depId}`);
		}
	}

	await publishPackage(packageName, network, force);
}

async function main(): Promise<void> {
	const args = process.argv.slice(2);
	const force = args.includes("--republish") || args.includes("-f");
	const forceAll = args.includes("--force-all");

	const packageArg = args.find((arg) => !arg.startsWith("-"));
	const packagesToPublish = packageArg ? [packageArg] : Packages;

	const network = await getActiveNetwork();
	console.log(`Active network: ${network}${forceAll ? " (force all)" : ""}`);
	console.log(`Publishing: ${packagesToPublish.join(", ")}`);

	try {
		for (const pkg of packagesToPublish) {
			await publishWithDependencies(pkg, network, force, forceAll);
		}
		console.log("Publishing completed");
	} catch (error) {
		console.error("Publishing failed:", error);
		process.exit(1);
	}
}

main();
