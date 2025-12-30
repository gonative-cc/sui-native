#!/usr/bin/env bun zx
import { $ } from "zx";
import { Transaction } from "@mysten/sui/transactions";
import "dotenv/config";
import { generateConfig, type LightClientConfig, getPublishedPackageId } from "./config";
import { PROJECT_ROOT, loadSigner, updateNBTCTomlWithValues, getActiveNetwork } from "./utils";
import { createLightClientAndGetId } from "./create_light_client";
import { publishPackage } from "./publish";
import { join } from "path";

async function main(): Promise<void> {
	console.error("🚀 Starting nBTC deployment...\n");

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

	console.error("\nCreating light client...");
	const { lightClientId, digest } = await createLightClientAndGetId(config, signer);

	console.log(`\n✅ Light client created: ${lightClientId}`);
	console.log(`Transaction: ${digest}`);

	console.error("\nPublishing nBTC package...");
	const fallbackAddr = signer.toSuiAddress();
	await publishPackage("nBTC", network, true, () => updateNBTCTomlWithValues(lightClientId, fallbackAddr));

	console.log("\n🎉 Deployment completed successfully!");
}

if (import.meta.main) {
	main().catch((error) => {
		console.error("❌ Deployment failed:", error);
		process.exit(1);
	});
}
