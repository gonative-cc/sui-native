// Importing the bitcoin lib
import * as bitcoin from "bitcoinjs-lib";

import { bcs } from "@mysten/sui/bcs";
// @ts-ignore
import { BufferWriter } from "bitcoinjs-lib/src/bufferutils";

import { sha256 } from "@noble/hashes/sha2.js";
import * as varuint from "varuint-bitcoin";

import { Curve, publicKeyFromDWalletOutput, type DWallet, type SharedDWallet } from "@ika.xyz/sdk";
import { sign_message } from "./sign";
import { createIkaClient, createSuiClient } from "./common";

const REGTEST = bitcoin.networks.regtest;

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

async function sendBTCTx(txHex: string) {
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

async function getBTCAddress(dWalletID: string) {
	let suiClient = createSuiClient();
	let ikaClient = createIkaClient(suiClient);
	await ikaClient.initialize();
	const dWallet = await ikaClient.getDWalletInParticularState(dWalletID, "Active", {
		timeout: 300000,
	});

	let publicKey = await publicKeyFromDWalletOutput(
		Curve.SECP256K1,
		Uint8Array.from(dWallet.state.Active?.public_output as number[]),
	);
	let ecpk = Buffer.from(bcs.byteVector().parse(publicKey));

	let dwalletAddress = bitcoin.payments.p2wpkh({
		pubkey: ecpk,
		network: REGTEST,
	}).address!;
	return dwalletAddress;
}
export { getUTXOs, sendBTCTx, getBTCAddress };
