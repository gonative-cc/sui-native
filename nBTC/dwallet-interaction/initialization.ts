// Initialization nBTC object script
//
//

import * as bitcoin from "bitcoinjs-lib";
import { Curve, publicKeyFromDWalletOutput, type IkaClient } from "@ika.xyz/sdk"
import { bcs } from "@mysten/sui/bcs"
import type { SuiClient } from "@mysten/sui/client"
import { Transaction } from "@mysten/sui/transactions"
import { regtest } from "bitcoinjs-lib/src/networks";
import { createIkaClient, createSuiClient, executeTransaction, mkSigner } from "./common";
import { fromHex } from "@mysten/sui/utils";
const REGTEST = bitcoin.networks.regtest;

import "dotenv/config";

type Config = {
	nbtc: string,
	dwalletId: string,
	adminCap: string,
	packageId: string,
}



export function loadConfig(): Config {

	let config: Config = {
		nbtc: process.env.NBTC!,
		dwalletId: process.env.DWALLET_ID!,
		adminCap: process.env.ADMINCAP!,
		packageId: process.env.PACKAGE_ID!
	}
	return config
}


export async function initialization(dwalletId: string) {
	const suiClient = createSuiClient();
	const ikaClient = createIkaClient(suiClient);
	await ikaClient.initialize();
	const dWallet = await ikaClient.getDWalletInParticularState(dwalletId, 'Active');
	const dwalletCap = dWallet.dwallet_cap_id;
	console.log(dWallet.state.Active?.public_output);
	const publicKey = await publicKeyFromDWalletOutput(Curve.SECP256K1, Buffer.from(dWallet.state.Active?.public_output));
	console.log(publicKey);
	console.log(bitcoin.payments.p2wpkh({ pubkey: publicKey, network: REGTEST }).address);
	const lockscript = bitcoin.payments.p2wpkh({ pubkey: publicKey, network: REGTEST }).output;

	let tx = new Transaction();

	let config = loadConfig();
	// add dwallet to nbtc
	tx.moveCall({
		target: `${config.packageId}::nbtc::add_dwallet`,
		arguments: [
			tx.object(config.adminCap),
			tx.object(config.nbtc),
			tx.object(dwalletCap),
			tx.pure.vector('u8', lockscript as Uint8Array),
			tx.pure.vector("u8", publicKey),
			tx.pure.vector('u8', [1]),
		]
	});

	tx.moveCall({
		target: `${config.packageId}::nbtc::set_active_dwallet`,
		arguments: [
			tx.object(config.adminCap),
			tx.object(config.nbtc),
			tx.pure.id(dwalletId),
		]
	});

	await executeTransaction(suiClient, tx);
}
