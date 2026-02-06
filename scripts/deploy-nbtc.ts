#!/usr/bin/env bun
import "dotenv/config";
import { generateConfig, getPublishedPackageId, DeployInformation, readDeployInformation, writeDeployInformation, validateDeployNetwork, checkPackageMismatch } from "./config";
import { loadSigner, updateNBTCTomlWithValues, getActiveNetwork, PROJECT_ROOT } from "./utils";
import { createLightClientAndGetId } from "./create_light_client";
import { publishPackage } from "./publish";
import {
	createSharedDwallet,
	createIkaClient,
	createSuiClient,
	getDwalletMetadata,
	type Config as NbtcConfig,
} from "../nBTC/scripts/common";
import { initialization } from "../nBTC/scripts/initialization";
import type {
	SuiObjectChange,
	SuiObjectChangeCreated,
	SuiObjectChangePublished,
} from "@mysten/sui/client";
import * as fs from "node:fs/promises";
import * as path from "node:path";

async function main(): Promise<void> {
	console.log("Starting nBTC deployment...\n");

	const network = await getActiveNetwork();

	const deployInfo = readDeployInformation();

	// Get package IDs from Published.toml
	const bitcoinLibPublishedId = getPublishedPackageId("bitcoin_lib", network);
	const bitcoinSpvPublishedId = getPublishedPackageId("bitcoin_spv", network);

	// Check for mismatches
	checkPackageMismatch("bitcoin_lib", deployInfo.bitcoin_lib_pkg, bitcoinLibPublishedId);
	checkPackageMismatch("bitcoin_spv", deployInfo.lc_pkg, bitcoinSpvPublishedId);

	// Publish bitcoin_lib if not in Published.toml
	if (!bitcoinLibPublishedId) {
		console.log("bitcoin_lib not in Published.toml, deploying...");
		await publishPackage("bitcoin_lib", network);
	} else {
		console.log(`bitcoin_lib found in Published.toml: ${bitcoinLibPublishedId}`);
		deployInfo.bitcoin_lib_pkg = bitcoinLibPublishedId;
	}

	// Publish bitcoin_spv if not in Published.toml
	if (!bitcoinSpvPublishedId) {
		console.log("bitcoin_spv not in Published.toml, deploying...");
		await publishPackage("bitcoin_spv", network);
	} else {
		console.log(`bitcoin_spv found in Published.toml: ${bitcoinSpvPublishedId}`);
		deployInfo.lc_pkg = bitcoinSpvPublishedId;
	}

	// Write deploy-info.json if we have package IDs from Published.toml
	if (bitcoinLibPublishedId || bitcoinSpvPublishedId) {
		deployInfo.sui_network = network;
		writeDeployInformation(deployInfo);
	}

	const config = await generateConfig();

	if (deployInfo.sui_network && deployInfo.sui_network !== network) {
		throw new Error(
			`Deployment information exists for network '${deployInfo.sui_network}', but current network is '${network}'. Delete deploy-information.json in project root to reset.`,
		);
	}

	let lcContract = deployInfo.lc_contract;
	let bitcoinLibPkg = deployInfo.bitcoin_lib_pkg;
	if (!lcContract) {
		const signer = loadSigner();
		console.log("\nCreating light client...");
		const result = await createLightClientAndGetId(config, signer, false);
		lcContract = result.lightClientId;

		deployInfo.bitcoin_lib_pkg = config.bitcoinLibPackageId;
		deployInfo.lc_pkg = config.spvPackageId;
		deployInfo.lc_contract = lcContract;
		deployInfo.sui_network = network;
		deployInfo.btc_network = "regtest";
		deployInfo.sui_fallback_address = signer.toSuiAddress();
		// Store the height used for light client creation
		deployInfo.height = config.btcHeight;
		// Set default header count if not already present
		if (!deployInfo.header_count) {
			deployInfo.header_count = config.headers.length;
		}
		writeDeployInformation(deployInfo);
		bitcoinLibPkg = deployInfo.bitcoin_lib_pkg;
	} else {
		console.log("\nUsing existing light client");
		bitcoinLibPkg = deployInfo.bitcoin_lib_pkg;
	}

	let nbtcContract: string | undefined;
	let nbtcAdminCap: string | undefined;
	let nbtcPkg: string | undefined;

	const nbtcPublishedId = getPublishedPackageId("nBTC", network);

	// Check for nBTC mismatch
	checkPackageMismatch("nBTC", deployInfo.nbtc_pkg, nbtcPublishedId);

	if (nbtcPublishedId) {
		console.log(`\nnBTC found in Published.toml: ${nbtcPublishedId}`);
		if (!deployInfo.nbtc_pkg) {
			deployInfo.nbtc_pkg = nbtcPublishedId;
		}
		nbtcPkg = nbtcPublishedId;
		nbtcContract = deployInfo.nbtc_contract;
		nbtcAdminCap = deployInfo.nbtc_admin_cap;
	} else if (deployInfo.nbtc_pkg) {
		console.log("\nUsing existing nBTC package from deploy-info");
		nbtcPkg = deployInfo.nbtc_pkg;
		nbtcContract = deployInfo.nbtc_contract;
		nbtcAdminCap = deployInfo.nbtc_admin_cap;
	} else {
		console.log("\nPublishing nBTC package...");
		const fallbackAddr = loadSigner().toSuiAddress();
		const publishResult = await publishPackage("nBTC", network, () =>
			updateNBTCTomlWithValues(lcContract!, fallbackAddr),
		);

		if (!publishResult) {
			throw new Error("nBTC package publish returned no result");
		}

		const objectChanges: SuiObjectChange[] = publishResult.objectChanges ?? [];
		const publishedPackage = objectChanges.find(
			(c): c is SuiObjectChangePublished => c.type === "published",
		);
		nbtcPkg = publishedPackage?.packageId;
		const createdChanges = objectChanges.filter(
			(c): c is SuiObjectChangeCreated => c.type === "created",
		);
		nbtcContract = createdChanges.find((c) => c.objectType.includes("NbtcContract"))?.objectId;
		nbtcAdminCap = createdChanges.find((c) => c.objectType.includes("AdminCap"))?.objectId;

		if (!nbtcContract || !nbtcAdminCap || !nbtcPkg) {
			throw new Error("Failed to extract nBTC objects from publish result");
		}

		deployInfo.nbtc_pkg = nbtcPkg;
		deployInfo.nbtc_contract = nbtcContract;
		deployInfo.nbtc_admin_cap = nbtcAdminCap;
		writeDeployInformation(deployInfo);
	}

	let dwalletId = deployInfo.dwallet_id;
	if (!dwalletId) {

		console.log("Creating dWallet...");

		const suiClient = createSuiClient(nbtcPkg!);
		const ikaClient = createIkaClient(suiClient);
		await ikaClient.initialize();

		const dWallet = await createSharedDwallet(ikaClient, suiClient);
		dwalletId = dWallet.id.id;

		const { addr: btcAddress } = await getDwalletMetadata(dWallet);
		const nbtcConfig: NbtcConfig = {
			nbtc: nbtcContract!,
			dwalletId,
			adminCap: nbtcAdminCap!,
			packageId: nbtcPkg!,
		};
		await initialization(dwalletId, nbtcConfig);

		deployInfo.dwallet_id = dwalletId;
		deployInfo.btc_address = btcAddress;
		writeDeployInformation(deployInfo);
	} else {
		console.log("\nUsing existing dWallet");
	}

	console.log(`\nDeployment completed successfully!`);
	console.log(`Bitcoin Lib Package: ${bitcoinLibPkg}`);
	console.log(`Light Client Package: ${deployInfo.lc_pkg}`);
	console.log(`Light Client: ${lcContract}`);
	console.log(`nBTC Package: ${nbtcPkg}`);
	console.log(`nBTC Contract: ${nbtcContract}`);
	console.log(`AdminCap: ${nbtcAdminCap}`);
	console.log(`dWallet: ${dwalletId}`);
	if (deployInfo.btc_address) {
		console.log(`BTC Address: ${deployInfo.btc_address}`);
	}
}

if (import.meta.main) {
	main().catch((error) => {
		console.error("Deployment failed:", error);
		process.exit(1);
	});
}
