import "dotenv/config";
import { readFileSync } from "fs";
import { join } from "path";
import * as toml from "smol-toml";
import { getActiveNetwork, PROJECT_ROOT } from "./utils";

const INDEXER_URL = process.env.INDEXER_URL || "http://localhost:8080/regtest";

/**
 * Retrieves the published package ID from Published.toml for a specific package and network.
 *
 * @param packagePath - The directory path of the Move package (e.g., "bitcoin_lib", "bitcoin_spv")
 * @param network - The network name (e.g., "testnet", "mainnet", "devnet")
 * @returns The package ID string if found, null otherwise
 */
export function getPublishedPackageId(packagePath: string, network: string): string | null {
	try {
		const publishedToml = join(PROJECT_ROOT, packagePath, "Published.toml");
		const parsed = toml.parse(readFileSync(publishedToml, "utf-8")) as any;
		const envSection = parsed[`published.${network}`];
		return envSection?.["published-at"] || null;
	} catch (error) {
		return null;
	}
}

export interface LightClientConfig {
	spvPackageId: string;
	bitcoinLibPackageId: string;
	network: string;
	headers: string[];
	btcNetwork: number;
	btcHeight: number;
	parentChainWork: string;
	confirmationDepth: number;
}


export async function fetchBlockHeader(blockHash: string): Promise<string> {
	const url = `${INDEXER_URL}/api/block/${blockHash}/header`;
	const response = await fetch(url);
	if (!response.ok) {
		throw new Error(`Failed to fetch block ${blockHash}: ${response.statusText}`);
	}
	const headerHex = await response.text();
	return `0x${headerHex.trim()}`;
}

export async function getBlockByHeight(height: number): Promise<string> {
	const url = `${INDEXER_URL}/api/block-height/${height}`;
	const response = await fetch(url);
	if (!response.ok) {
		throw new Error(`Failed to fetch block at height ${height}: ${response.statusText}`);
	}
	return response.text();
}

export async function getTipHeight(): Promise<number> {
	const url = `${INDEXER_URL}/api/blocks/tip/height`;
	const response = await fetch(url);
	if (!response.ok) {
		throw new Error(`Failed to fetch tip height: ${response.statusText}`);
	}
	return parseInt(await response.text(), 10);
}

export async function fetchHeadersByHeight(startHeight: number, count: number): Promise<string[]> {
	const headers: string[] = [];
	const tipHeight = await getTipHeight();

	for (let i = 0; i < count; i++) {
		const height = startHeight + i;
		if (height > tipHeight) {
			console.log(`Cannot fetch block at height ${height} (beyond tip ${tipHeight})`);
			break;
		}
		const blockHash = await getBlockByHeight(height);
		const header = await fetchBlockHeader(blockHash);
		headers.push(header);
		if (i === 0 || i === count - 1 || (i + 1) % 5 === 0) {
			console.log(`Fetched block ${height}/${tipHeight}`);
		}
	}

	return headers;
}

export async function generateConfig(
	startHeight: number = 0,
	count: number = 11,
): Promise<LightClientConfig> {
	const network = await getActiveNetwork();

	const deployInfoPath = join(PROJECT_ROOT, "deploy-information.json");
	const deployInfo = JSON.parse(readFileSync(deployInfoPath, "utf-8"));

	// Validate network matches if deploy-info has network info
	if (deployInfo.sui_network && deployInfo.sui_network !== network) {
		throw new Error(
			`Deployment information exists for network '${deployInfo.sui_network}', but current network is '${network}'`,
		);
	}

	let bitcoinLibId = deployInfo.bitcoin_lib_pkg || null;
	let bitcoinSpvId = deployInfo.lc_pkg || null;

	if (bitcoinLibId && bitcoinSpvId) {
		console.log("Using package IDs from deploy-information.json");
	} else {
		// If not found in deploy-info, try Published.toml first
		if (!bitcoinLibId) {
			bitcoinLibId = getPublishedPackageId("bitcoin_lib", network);
		}
		if (!bitcoinSpvId) {
			bitcoinSpvId = getPublishedPackageId("bitcoin_spv", network);
		}
	}

	console.log(`Network: ${network}`);
	console.log(`bitcoin_lib: ${bitcoinLibId}`);
	console.log(`bitcoin_spv: ${bitcoinSpvId}`);
	console.log(`\nFetching ${count} blocks starting from height ${startHeight}...`);

	const headers = await fetchHeadersByHeight(startHeight, count);

	return {
		spvPackageId: bitcoinSpvId,
		bitcoinLibPackageId: bitcoinLibId,
		network,
		headers,
		btcNetwork: 2,
		btcHeight: startHeight,
		parentChainWork: "0",
		confirmationDepth: 3,
	};
}
