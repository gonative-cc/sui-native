const ElectrsURL = "http://localhost:3002";

/**
 * Fetches the Unspent Transaction Outputs (UTXOs) for a given Bitcoin address.
 *
 * @param address The Bitcoin address (e.g., P2PKH, SegWit) to check.
 * @returns A promise that resolves to an array of UTXO objects.
 * @throws {Error} If no UTXOs are found for the provided address.
 */
async function getUTXOs(address: string) {
	const utxoUrl = `${ElectrsURL}/address/${address}/utxo`;
	let response = await fetch(utxoUrl);

	let utxos = (await response.json()) as any[];
	if (utxos.length === 0) {
		throw new Error("No UTXOs found for this address");
	}

	return utxos;
}
/**
 * Broadcasts a raw BTC transaction
 *
 * @param txHex Hexadecimal transaction string.
 * @returns 0 on completion (status logged).
 */
async function broadcastBtcTx(txHex: string) {
	const broadcastUrl = `${ElectrsURL}/tx`;
	try {
		const response = await fetch(broadcastUrl, {
			headers: { "Content-Type": "application/json" },
			method: "POST",
			body: txHex,
		});
		console.log("Transaction Broadcasted:", await response.body?.text());
		return 0;
	} catch (error) {
		console.error("Error broadcasting transaction:", error);
		return 0;
	}
}

export { getUTXOs, broadcastBtcTx };
