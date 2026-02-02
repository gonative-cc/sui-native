#!/usr/bin/env bun
import "dotenv/config";
import { generateConfig, getPublishedPackageId } from "./config";
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

const DEPLOY_INFO_FILE = path.join(PROJECT_ROOT, "deploy-information.json");

interface DeployInformation {
	btc_network?: string;
	sui_network?: string;
	bitcoin_lib_pkg?: string;
	nbtc_pkg?: string;
	nbtc_contract?: string;
	nbtc_admin_cap?: string;
	lc_pkg?: string;
	lc_contract?: string;
	sui_fallback_address?: string;
	btc_address?: string;
	dwallet_id?: string;
}

async function main(): Promise<void> {
	console.log("Starting nBTC deployment...\n");

	const network = await getActiveNetwork();

	let deployInfo: DeployInformation = {};
	try {
		const content = await fs.readFile(DEPLOY_INFO_FILE, "utf-8");
		deployInfo = JSON.parse(content);
	} catch (error) {
		// File doesn't exist, start fresh
	}

	// Check and publish bitcoin_lib if needed
	if (!deployInfo.bitcoin_lib_pkg) {
		const publishedId = getPublishedPackageId("bitcoin_lib", network);
		if (publishedId) {
			console.log(`bitcoin_lib found in Published.toml: ${publishedId}`);
			deployInfo.bitcoin_lib_pkg = publishedId;
		} else {
			console.log("bitcoin_lib not in deploy-info or Published.toml, deploying...");
			await publishPackage("bitcoin_lib", network, false);
		}
	} else {
		console.log(`Using existing bitcoin_lib from deploy-info: ${deployInfo.bitcoin_lib_pkg}`);
	}

	// Check and publish bitcoin_spv if needed
	if (!deployInfo.lc_pkg) {
		const publishedId = getPublishedPackageId("bitcoin_spv", network);
		if (publishedId) {
			console.log(`bitcoin_spv found in Published.toml: ${publishedId}`);
			deployInfo.lc_pkg = publishedId;
		} else {
			console.log("bitcoin_spv not in deploy-info or Published.toml, deploying...");
			await publishPackage("bitcoin_spv", network, false);
		}
	} else {
		console.log(`Using existing bitcoin_spv from deploy-info: ${deployInfo.lc_pkg}`);
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
		await fs.writeFile(DEPLOY_INFO_FILE, JSON.stringify(deployInfo, null, 2), "utf-8");
		bitcoinLibPkg = deployInfo.bitcoin_lib_pkg;
	} else {
		console.log("\nUsing existing light client");
		bitcoinLibPkg = deployInfo.bitcoin_lib_pkg;
	}

	let nbtcContract: string | undefined;
	let nbtcAdminCap: string | undefined;
	let nbtcPkg: string | undefined;

	if (deployInfo.nbtc_pkg) {
		nbtcPkg = deployInfo.nbtc_pkg;
		nbtcContract = deployInfo.nbtc_contract;
		nbtcAdminCap = deployInfo.nbtc_admin_cap;
		console.log("\nUsing existing nBTC package");
	} else {
		console.log("\nPublishing nBTC package...");
		const fallbackAddr = loadSigner().toSuiAddress();
		const publishResult = await publishPackage("nBTC", network, true, () =>
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
		await fs.writeFile(DEPLOY_INFO_FILE, JSON.stringify(deployInfo, null, 2), "utf-8");
	}

	let dwalletId = deployInfo.dwallet_id;
	if (!dwalletId) {
		console.log("\nCreating dWallet...");

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
		await fs.writeFile(DEPLOY_INFO_FILE, JSON.stringify(deployInfo, null, 2), "utf-8");
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
