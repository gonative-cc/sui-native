#!/usr/bin/env bun zx
import { $ } from "zx";
import { join } from "path";
import "dotenv/config";
import { getPublishedPackageId } from "./config";
import { PROJECT_ROOT, getActiveNetwork, updateNBTCToml, getSuiCommand, loadSigner } from "./utils";
import { getFullnodeUrl, SuiClient, SuiTransactionBlockResponse } from "@mysten/sui/client";
import { Transaction } from "@mysten/sui/transactions";

const Packages = ["bitcoin_lib", "bitcoin_spv", "nBTC"];

export interface PublishResult {
	response: SuiTransactionBlockResponse;
	packageId: string | undefined;
	upgradeCap: string | undefined;
	adminCap: string | undefined;
}

interface BuildOutput {
	modules: string[];
	dependencies: string[];
	digest: number[];
}

async function buildPackage(packagePath: string): Promise<BuildOutput> {
	const suiCommand = getSuiCommand();
	const result =
		await $`${suiCommand} move build --path ${packagePath} --dump-bytecode-as-base64`.quiet();
	const jsonStart = result.stdout.lastIndexOf("{");
	if (jsonStart === -1) {
		throw new Error("No JSON found in build output");
	}
	return JSON.parse(result.stdout.slice(jsonStart)) as BuildOutput;
}

export async function publishPackage(
	client: SuiClient,
	packageName: string,
	prePublish?: () => void | Promise<void>,
): Promise<PublishResult | null> {
	const network = await getActiveNetwork();
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

	const { modules, dependencies } = await buildPackage(packagePath);

	const signer = loadSigner();
	const tx = new Transaction();

	const [upgradeCap] = tx.publish({
		modules,
		dependencies,
	});
	tx.transferObjects([upgradeCap!], signer.toSuiAddress());

	const response = await client.signAndExecuteTransaction({
		transaction: tx,
		signer,
		options: {
			showEffects: true,
			showObjectChanges: true,
		},
	});

	const objectChanges = response.objectChanges || [];
	const published = objectChanges.find((c) => c.type === "published") as
		| { packageId: string }
		| undefined;
	const upgradeCapObj = objectChanges.find(
		(c) => c.type === "created" && "objectType" in c && c.objectType?.includes("UpgradeCap"),
	) as { objectId: string } | undefined;
	const adminCapObj = objectChanges.find(
		(c) =>
			c.type === "created" &&
			"objectType" in c &&
			c.objectType?.includes("AdminCap") &&
			!c.objectType?.includes("0x2::package"),
	) as { objectId: string } | undefined;

	console.log(`Package ID: ${published?.packageId}`);
	console.log(`UpgradeCap: ${upgradeCapObj?.objectId}`);
	if (adminCapObj) {
		console.log(`AdminCap: ${adminCapObj.objectId}`);
	}

	return {
		response,
		packageId: published?.packageId,
		upgradeCap: upgradeCapObj?.objectId,
		adminCap: adminCapObj?.objectId,
	};
}

async function publishWithDependencies(
	client: SuiClient,
	packageName: string,
	prePublish?: () => void | Promise<void>,
): Promise<void> {
	const network = await getActiveNetwork();
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
			await publishPackage(client, dep);
		}
	}

	await publishPackage(client, packageName, prePublish);
}

async function main(): Promise<void> {
	const args = process.argv.slice(2);
	const packageArg = args.find((arg) => !arg.startsWith("-"));
	const packagesToPublish = packageArg ? [packageArg] : Packages;

	const network = await getActiveNetwork();
	console.log(`Active network: ${network}`);
	console.log(`Publishing: ${packagesToPublish.join(", ")}`);

	const client = new SuiClient({
		url: getFullnodeUrl(network as "mainnet" | "testnet" | "devnet" | "localnet"),
	});

	try {
		for (const pkg of packagesToPublish) {
			const prePublish =
				pkg === "nBTC" && !process.env.BITCOIN_LC && !process.env.FALLBACK_ADDR
					? () => updateNBTCToml(network)
					: undefined;

			await publishWithDependencies(client, pkg, prePublish);
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
