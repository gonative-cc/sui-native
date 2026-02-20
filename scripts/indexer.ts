export const INDEXER_URL = process.env.INDEXER_URL || "http://localhost:8080/regtest/api";

export function getIndexerURL(path: string): string {
	try {
		let url = new URL(INDEXER_URL.concat(path));
		return url.toString();
	} catch (error) {
		throw new Error(`Invalid INDEXER_URL configuration: ${INDEXER_URL}`);
	}
}

export async function getTxStatus(
	txid: string,
): Promise<{ confirmed: boolean; block_height?: number }> {
	const url = getIndexerURL(`/tx/${txid}/status`);
	const response = await fetch(url);
	if (!response.ok) {
		throw new Error(`Failed to get tx status: ${response.statusText}`);
	}
	return response.json() as Promise<{ confirmed: boolean; block_height?: number }>;
}

export async function getTxHex(txid: string): Promise<string> {
	const url = getIndexerURL(`/tx/${txid}/hex`);
	const response = await fetch(url);
	if (!response.ok) {
		throw new Error(`Failed to fetch tx hex: ${response.statusText}`);
	}
	return response.text();
}

export async function getBlockTxs(blockHash: string): Promise<string[]> {
	const url = getIndexerURL(`/block/${blockHash}/txids`);
	const response = await fetch(url);
	if (!response.ok) {
		throw new Error(`Failed to fetch block txs: ${response.statusText}`);
	}
	return response.json() as Promise<string[]>;
}

export async function getBlockTransactions(blockHash: string): Promise<Buffer[]> {
	const txids = await getBlockTxs(blockHash);
	const transactions: Buffer[] = [];
	for (const txid of txids) {
		const txHex = await getTxHex(txid);
		transactions.push(Buffer.from(txHex, "hex"));
	}
	return transactions;
}

export async function getBlockHash(height: number): Promise<string> {
	const url = getIndexerURL(`/block-height/${height}`);
	const response = await fetch(url);
	if (!response.ok) {
		throw new Error(`Failed to get block hash at height ${height}: ${response.statusText}`);
	}
	return response.text();
}

export async function getTipHeight(): Promise<number> {
	const url = getIndexerURL(`/blocks/tip/height`);
	const response = await fetch(url);
	if (!response.ok) {
		throw new Error(`Failed to fetch tip height: ${response.statusText}`);
	}
	return parseInt(await response.text(), 10);
}

export async function getBlockHeader(blockHash: string): Promise<string> {
	const url = getIndexerURL(`/block/${blockHash}/header`);
	const response = await fetch(url);
	if (!response.ok) {
		throw new Error(`Failed to fetch block header: ${response.statusText}`);
	}
	const headerHex = await response.text();
	return `0x${headerHex.trim()}`;
}

export async function getBlockByHeight(height: number): Promise<string> {
	return await getBlockHash(height);
}

export async function getBlockHashByTx(txid: string): Promise<string> {
	const url = getIndexerURL(`/tx/${txid}/block-hash`);
	const response = await fetch(url);
	if (!response.ok) {
		throw new Error(`Failed to fetch block hash for tx ${txid}: ${response.statusText}`);
	}
	return response.text();
}

export async function getBlockHeightByTx(txid: string): Promise<number> {
	const url = getIndexerURL(`/tx/${txid}/block-height`);
	const response = await fetch(url);
	if (!response.ok) {
		throw new Error(`Failed to fetch block height for tx ${txid}: ${response.statusText}`);
	}
	return parseInt(await response.text(), 10);
}

export async function fetchHeadersRange(startHeight: number, endHeight: number): Promise<string[]> {
	const headers: string[] = [];

	for (let h = startHeight; h < endHeight + 1; h++) {
		const blockHash = await getBlockHash(h);
		const header = await getBlockHeader(blockHash);
		if (header) {
			headers.push(header);
		}
	}

	return headers;
}
