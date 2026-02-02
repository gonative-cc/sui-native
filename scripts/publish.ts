#!/usr/bin/env bun zx
import { $ } from "zx";
import { join } from "path";
import { Network } from "@ika.xyz/sdk";
import "dotenv/config";
import { getPublishedPackageId } from "./config";
import { PROJECT_ROOT, getActiveNetwork, updateNBTCToml, getSuiCommand } from "./utils";
import type { SuiTransactionBlockResponse } from "@mysten/sui/client";

const Packages = ["bitcoin_lib", "bitcoin_spv", "nBTC"];

export async function publishPackage(
	packageName: string,
	network: Network,
	prePublish?: () => void | Promise<void>,
): Promise<SuiTransactionBlockResponse | null> {
	const publishedId = getPublishedPackageId(packageName, network);
	if (publishedId) {
		console.log(`${packageName} already published at ${publishedId}`);
		return null;
	}

	const packagePath = join(PROJECT_ROOT, packageName);
	console.log(`Publishing ${packageName}...`);

	if (prePublish) {
		await prePublish();
	}

	$.cwd = packagePath;
	const suiCommand = getSuiCommand();
	const result = await $`${suiCommand} client publish --gas-budget 1000000000 --json --silence-warnings`;
	const jsonStart = result.stdout.indexOf("{");
	if (jsonStart === -1) {
		throw new Error("No JSON found in publish output");
	}
	return JSON.parse(result.stdout.slice(jsonStart)) as SuiTransactionBlockResponse;
}

async function publishWithDependencies(
	packageName: string,
	network: Network,
	prePublish?: () => void | Promise<void>,
): Promise<void> {
	const packageIndex = Packages.indexOf(packageName);
	if (packageIndex === -1) {
		throw new Error(
			`Unknown package: ${packageName}. Available packages: ${Packages.join(", ")}`,
		);
	}

	for (let i = 0; i < packageIndex; i++) {
		const dep = Packages[i]!;
		const depId = getPublishedPackageId(dep, network);
		if (depId) {
			console.log(`Dependency ${dep} already published at ${depId}`);
		} else {
			console.log(`Deploying dependency ${dep} first...`);
			await publishPackage(dep, network);
		}
	}

	await publishPackage(packageName, network, prePublish);
}

async function main(): Promise<void> {
	const args = process.argv.slice(2);
	const packageArg = args.find((arg) => !arg.startsWith("-"));
	const packagesToPublish = packageArg ? [packageArg] : Packages;

	const network = await getActiveNetwork();
	console.log(`Active network: ${network}`);
	console.log(`Publishing: ${packagesToPublish.join(", ")}`);

	try {
		for (const pkg of packagesToPublish) {
			const prePublish =
				pkg === "nBTC" && !process.env.BITCOIN_LC && !process.env.FALLBACK_ADDR
					? () => updateNBTCToml(network)
					: undefined;

			await publishWithDependencies(pkg, network, prePublish);
		}
		console.log("Publishing completed");
	} catch (error) {
		console.error("Publishing failed:", error);
		process.exit(1);
	}
}

if (import.meta.main) {
	main();
}
