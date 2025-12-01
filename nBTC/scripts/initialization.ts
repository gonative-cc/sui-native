import { Transaction } from "@mysten/sui/transactions";
import {
	createIkaClient,
	createSuiClient,
	executeTransaction,
	getDwalletMetadata,
	type Config,
} from "./common";

// Get dwallet metadata for  and add dwallet to smart contract for a dwallet have dwallet id
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
