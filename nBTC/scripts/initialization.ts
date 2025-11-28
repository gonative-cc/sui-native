// Initialization nBTC object script
//
//

import { Transaction } from "@mysten/sui/transactions";
import {
	createIkaClient,
	createSuiClient,
	executeTransaction,
	getDwalletMetadata,
	mkSigner,
	type Config,
} from "./common";
import { fromHex } from "@mysten/sui/utils";

import { getUTXOs } from "./btc-helper";
import type { IkaClient } from "@ika.xyz/sdk";
import type { SuiClient } from "@mysten/sui/client";

export async function initialization(dwalletId: string, config: Config) {
	const suiClient = createSuiClient();
	const ikaClient = createIkaClient(suiClient);
	await ikaClient.initialize();
	const dWallet = await ikaClient.getDWalletInParticularState(dwalletId, "Active");
	const dwalletCap = dWallet.dwallet_cap_id;

	let { publicKey, lockscript } = await getDwalletMetadata(dWallet);

	let tx = new Transaction();

	// add dwallet to nbtc
	tx.moveCall({
		target: `${config.packageId}::nbtc::add_dwallet`,
		arguments: [
			tx.object(config.adminCap),
			tx.object(config.nbtc),
			tx.object(dwalletCap),
			tx.pure.vector("u8", lockscript as Uint8Array),
			tx.pure.vector("u8", publicKey),
			tx.pure.vector("u8", dWallet.public_user_secret_key_share!),
		],
	});

	tx.moveCall({
		target: `${config.packageId}::nbtc::set_active_dwallet`,
		arguments: [tx.object(config.adminCap), tx.object(config.nbtc), tx.pure.id(dwalletId)],
	});

	await executeTransaction(suiClient, tx);
}

// init nbtc state for testing,
// TODO: this function should remove after have e2e tests
export async function mint_nbtc_for_testing(
	ikaClient: IkaClient,
	suiClient: SuiClient,
	dwalletId: string,
	config: Config,
) {
	const dWallet = await ikaClient.getDWalletInParticularState(dwalletId, "Active");
	let { addr } = await getDwalletMetadata(dWallet);

	let utxos = await getUTXOs(addr);
	let tx = new Transaction();
	for (let i = 0; i < utxos.length; i++) {
		tx.moveCall({
			target: `${config.packageId}::nbtc::mint_nbtc_with_admin`,
			arguments: [
				tx.object(config.adminCap),
				tx.object(config.nbtc),
				tx.pure.vector("u8", fromHex(utxos[i].txid).reverse()),
				tx.pure.u32(utxos[i].vout),
				tx.pure.u64(utxos[i].value),
			],
		});
	}
	await executeTransaction(suiClient, tx);
}
