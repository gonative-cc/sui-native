#!/usr/bin/env bun
import "dotenv/config";
import { generateConfig, getPublishedPackageId } from "./config";
import { loadSigner, updateNBTCTomlWithValues, getActiveNetwork } from "./utils";
import { createLightClientAndGetId } from "./create_light_client";
import { publishPackage } from "./publish";
import { createSharedDwallet, createIkaClient, createSuiClient, type Config as NbtcConfig } from "../nBTC/scripts/common";
import { initialization } from "../nBTC/scripts/initialization";
import type { SuiObjectChange, SuiObjectChangeCreated, SuiObjectChangePublished, SuiTransactionBlockResponse } from "@mysten/sui/client";

async function main(): Promise<void> {
	console.log("🚀 Starting nBTC deployment...\n");

	const config = await generateConfig();
	const network = await getActiveNetwork();

	// Ensure dependencies are published
	for (const pkg of ["bitcoin_lib", "bitcoin_spv"]) {
		const packageId = getPublishedPackageId(pkg, network);
		if (!packageId) {
			throw new Error(`Package ${pkg} not published. Please publish it first.`);
		}
	}

	const signer = loadSigner();

	console.log("\nCreating light client...");
	const { lightClientId, digest } = await createLightClientAndGetId(config, signer);

	console.log(`\n✅ Light client created: ${lightClientId}`);
	console.log(`Transaction: ${digest}`);

	console.log("\nPublishing nBTC package...");
	const fallbackAddr = signer.toSuiAddress();
	const publishResult = await publishPackage("nBTC", network, true, () => updateNBTCTomlWithValues(lightClientId, fallbackAddr));

	if (!publishResult) {
		console.log("\n🎉 Deployment completed successfully!");
		return;
	}

	// Extract objects from publish result
	const objectChanges: SuiObjectChange[] = publishResult.objectChanges ?? [];

	// Find published package
	const publishedPackage = objectChanges.find(
		(c): c is SuiObjectChangePublished => c.type === "published"
	);
	const packageId = publishedPackage?.packageId;

	// Find created NbtcContract and AdminCap
	const createdChanges = objectChanges.filter(
		(c): c is SuiObjectChangeCreated => c.type === "created"
	);
	const nbtcContract = createdChanges.find((c) => c.objectType.includes("NbtcContract"))?.objectId;
	const adminCap = createdChanges.find((c) => c.objectType.includes("AdminCap"))?.objectId;

	if (!nbtcContract || !adminCap || !packageId) {
		throw new Error("Failed to extract nBTC objects from publish result");
	}

	console.log("\nInitializing nBTC with dWallet...");

	const suiClient = createSuiClient(packageId);
	const ikaClient = createIkaClient(suiClient);
	await ikaClient.initialize();

	// Create shared dWallet
	console.log("Creating dWallet...");
	const dWallet = await createSharedDwallet(ikaClient, suiClient);
	const dwalletId = dWallet.id.id;

	console.log(`dWallet created: ${dwalletId}`);

	// Initialize nBTC with dWallet
	const nbtcConfig: NbtcConfig = {
		nbtc: nbtcContract,
		dwalletId,
		adminCap,
		packageId,
	};

	await initialization(dwalletId, nbtcConfig);

	console.log(`\n🎉 Deployment completed successfully!`);
	console.log(`nBTC Contract: ${nbtcContract}`);
	console.log(`AdminCap: ${adminCap}`);
	console.log(`Package: ${packageId}`);
	console.log(`dWallet: ${dwalletId}`);
}

if (import.meta.main) {
	main().catch((error) => {
		console.error("❌ Deployment failed:", error);
		process.exit(1);
	});
}
