import { Transaction } from "@mysten/sui/transactions";
import {
	createIkaClient,
	createSuiClient,
	executeTransaction,
	getDwalletMetadata,
	type Config,
} from "./common";
import { nBTCContractModule } from "../../sdk/nBTC/src";

/**
 * Initializes the nBTC smart contract by registering an existing active dWallet and
 * setting it as the contract's current active dWallet for transaction processing.
 *
 * This function fetches the dWallet's Bitcoin metadata (public key, lockscript, control block, tapscript)
 * and passes it, along with the dWallet capability, to the nBTC Move module.
 *
 * @param dwalletId The ID of the fully initialized and "Active" dWallet object.
 * @param config The configuration object containing IDs like `packageId`, `adminCap`, and `nbtc` object ID.
 * @returns A promise that resolves when the initialization transaction is executed successfully (no explicit return value).
 */
export async function initialization(dwalletId: string, config: Config) {
	const suiClient = createSuiClient(config.packageId);
	const ikaClient = createIkaClient(suiClient);
	await ikaClient.initialize();
	const dWallet = await ikaClient.getDWalletInParticularState(dwalletId, "Active");
	const dwalletCap = dWallet.dwallet_cap_id;

	let { addr, lockscript, controlBlock, tapscript } = await getDwalletMetadata(dWallet);

	let tx = new Transaction();
	console.log(lockscript);
	// add dwallet to nbtc
	tx.add(
		nBTCContractModule.addDwallet({
			arguments: {
				_: config.adminCap,
				contract: config.nbtc,
				cap: dwalletCap,
				lockscript: Array.from(lockscript),
				controlByte: 0, // Kept for compatibility, not used in script path spending
				scriptMerkleRoot: Array.from([]), // Empty for single-leaf tree
				controlBlock: Array.from(controlBlock),
				tapscript: Array.from(tapscript),
				userKeyShare: Array.from(dWallet.public_user_secret_key_share!),
				btcaddr: addr,
			},
		}),
	);

	await executeTransaction(suiClient, tx);
}
