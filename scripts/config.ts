import "dotenv/config";
import { readFileSync } from "fs";
import { join } from "path";
import * as toml from "smol-toml";
import { getActiveNetwork, PROJECT_ROOT } from "./utils";

const INDEXER_URL = process.env.INDEXER_URL || "http://localhost:8080/regtest";

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

/**
 * Retrieves the published package ID from Move.lock for a specific package and network.
 * Uses PROJECT_ROOT to ensure consistent path resolution regardless of execution directory.
 *
 * @param packagePath - The directory path of the Move package (e.g., "bitcoin_lib", "bitcoin_spv")
 * @param network - The network name (e.g., "testnet", "mainnet", "devnet")
 * @returns The package ID string if found, null otherwise
 * @throws {Error} If Move.lock file doesn't exist or cannot be parsed
 *
 * @example
 * const pkgId = getPublishedPackageId("bitcoin_lib", "testnet");
 * // Returns: "0x123..." or null
 */
export function getPublishedPackageId(packagePath: string, network: string): string | null {
	try {
		const moveLock = join(PROJECT_ROOT, packagePath, "Move.lock");
		const parsed = toml.parse(readFileSync(moveLock, "utf-8")) as any;
		const envSection = parsed.env?.[network];
		return envSection?.["latest-published-id"] || null;
	} catch (error) {
		throw new Error(`Failed to read Move.lock for package "${packagePath}": ${(error as Error).message}`);
	}
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
	const bitcoinLibId = getPublishedPackageId("bitcoin_lib", network);
	const bitcoinSpvId = getPublishedPackageId("bitcoin_spv", network);

	if (!bitcoinLibId || !bitcoinSpvId) {
		throw new Error(`Could not find published package IDs for network ${network}`);
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
