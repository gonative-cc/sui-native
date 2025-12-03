// Getting the unspent transaction output for a given address
async function getUTXOs(address: string) {
	const utxoUrl = `http://localhost:3002/address/${address}/utxo`;
	let response = await fetch(utxoUrl);

	let utxos = (await response.json()) as any[];
	if (utxos.length === 0) {
		throw new Error("No UTXOs found for this address");
	}

	return utxos;
}

async function broadcastBtcTx(txHex: string) {
	const broadcastUrl = `http://localhost:3002/tx`;
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
