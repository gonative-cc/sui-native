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

function varSliceSize(someScript: Buffer): number {
	const length = someScript.length;
	return varuint.encodingLength(length) + length;
}

function txBytesToSign(
	tx: bitcoin.Transaction,
	inIndex: number,
	prevOutScript: Buffer,
	value: number,
	hashType: number,
): Buffer {
	const ZERO: Buffer = Buffer.from(
		"0000000000000000000000000000000000000000000000000000000000000000",
		"hex",
	);

	let tbuffer: Buffer = Buffer.from([]);
	let bufferWriter: BufferWriter;

	let hashOutputs = ZERO;
	let hashPrevouts = ZERO;
	let hashSequence = ZERO;

	if (!(hashType & bitcoin.Transaction.SIGHASH_ANYONECANPAY)) {
		tbuffer = Buffer.allocUnsafe(36 * tx.ins.length);
		bufferWriter = new BufferWriter(tbuffer, 0);

		tx.ins.forEach((txIn) => {
			bufferWriter.writeSlice(txIn.hash);
			bufferWriter.writeUInt32(txIn.index);
		});

		hashPrevouts = Buffer.from(sha256(sha256(tbuffer)));
	}

	if (
		!(hashType & bitcoin.Transaction.SIGHASH_ANYONECANPAY) &&
		(hashType & 0x1f) !== bitcoin.Transaction.SIGHASH_SINGLE &&
		(hashType & 0x1f) !== bitcoin.Transaction.SIGHASH_NONE
	) {
		tbuffer = Buffer.allocUnsafe(4 * tx.ins.length);
		bufferWriter = new BufferWriter(tbuffer, 0);

		tx.ins.forEach((txIn) => {
			bufferWriter.writeUInt32(txIn.sequence);
		});

		hashSequence = Buffer.from(sha256(sha256(tbuffer)));
	}

	if (
		(hashType & 0x1f) !== bitcoin.Transaction.SIGHASH_SINGLE &&
		(hashType & 0x1f) !== bitcoin.Transaction.SIGHASH_NONE
	) {
		const txOutsSize = tx.outs.reduce((sum, output) => {
			return sum + 8 + varSliceSize(output.script as Buffer);
		}, 0);

		tbuffer = Buffer.allocUnsafe(txOutsSize);
		bufferWriter = new BufferWriter(tbuffer, 0);

		tx.outs.forEach((out) => {
			bufferWriter.writeUInt64(out.value);
			bufferWriter.writeVarSlice(out.script);
		});

		hashOutputs = Buffer.from(sha256(sha256(tbuffer)));
	} else if (
		(hashType & 0x1f) === bitcoin.Transaction.SIGHASH_SINGLE &&
		inIndex < tx.outs.length
	) {
		const output = tx.outs[inIndex]!;

		tbuffer = Buffer.allocUnsafe(8 + varSliceSize(output.script as Buffer));
		bufferWriter = new BufferWriter(tbuffer, 0);
		bufferWriter.writeUInt64(output.value);
		bufferWriter.writeVarSlice(output.script);

		hashOutputs = Buffer.from(sha256(sha256(tbuffer)));
	}

	tbuffer = Buffer.allocUnsafe(156 + varSliceSize(prevOutScript));
	bufferWriter = new BufferWriter(tbuffer, 0);

	const input = tx.ins[inIndex]!;
	bufferWriter.writeInt32(tx.version);
	bufferWriter.writeSlice(hashPrevouts);
	bufferWriter.writeSlice(hashSequence);
	bufferWriter.writeSlice(input.hash);
	bufferWriter.writeUInt32(input.index);
	bufferWriter.writeVarSlice(prevOutScript);
	bufferWriter.writeUInt64(value);
	bufferWriter.writeUInt32(input.sequence);
	bufferWriter.writeSlice(hashOutputs);
	bufferWriter.writeUInt32(tx.locktime);
	bufferWriter.writeUInt32(hashType);

	return tbuffer;
}

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
async function redeemTx(dWalletID: string, receiverAddress: string, amountTx: number) {
	let suiClient = createSuiClient();
	let ikaClient = createIkaClient(suiClient);
	await ikaClient.initialize();

	const dWallet = await ikaClient.getDWalletInParticularState(dWalletID as string, "Active", {
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
	let output = bitcoin.payments.p2wpkh({
		pubkey: ecpk,
		network: REGTEST,
	}).output!;
	let utxos = await getUTXOs(dwalletAddress);

	const psbt = new bitcoin.Psbt({ network: REGTEST });

	const fee = 150; // we will covert the fee in this POC

	let totalInputAmount = 0;
	for (let i = 0; i < utxos.length; i++) {
		let { txid, vout, value } = utxos[i]!;
		psbt.addInput({
			hash: txid,
			index: vout,
			witnessUtxo: {
				script: output,
				value: value,
			},
		});

		totalInputAmount += value;
		if (totalInputAmount >= fee + amountTx) {
			break;
		}
	}

	psbt.addOutput({
		address: receiverAddress,
		value: amountTx,
	} as bitcoin.PsbtTxOutput);

	let change = totalInputAmount - fee - amountTx;

	if (change > 0) {
		psbt.addOutput({ address: dwalletAddress, value: change });
	}
	const tx = bitcoin.Transaction.fromBuffer(psbt.data.getTransaction());

	const signingScript = bitcoin.payments.p2pkh({
		hash: output.slice(2),
	}).output!;

	console.log("Starting signing process...");
	for (let i = 0; i < tx.ins.length; ++i) {
		const bytesToSign = txBytesToSign(
			tx,
			i,
			signingScript,
			utxos[i]?.value as number,
			bitcoin.Transaction.SIGHASH_ALL,
		);
		const hashToSign = sha256(bytesToSign);
		const raw_signature = await sign_message(dWallet as SharedDWallet, hashToSign);

		const witness = bitcoin.payments.p2wpkh({
			output: output,
			pubkey: ecpk as Buffer,
			signature: bitcoin.script.signature.encode(
				Buffer.concat(raw_signature),
				bitcoin.Transaction.SIGHASH_ALL,
			),
		}).witness!;

		tx.setWitness(i, witness);
	}
	console.log("Completed signing process!");
	return tx.toHex();
}

export { txBytesToSign, getUTXOs, sendBTCTx, redeemTx, getBTCAddress };
