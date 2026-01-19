import { Transaction } from "@mysten/sui/transactions";
import {
	createIkaClient,
	createSuiClient,
	executeTransaction,
	getIkaCoin,
	loadConfig,
	mkSigner,
	type Config,
} from "./common";
import { nBTCContractModule } from "../../sdk/nBTC/src";

const config = loadConfig();

let suiClient = createSuiClient(config.packageId);

/**
 * Fills the nBTC contract's presign buffer up to MAX_PRESIGNS (30)
 *
 * This function creates global presigns and stores them in the contract's presigns vector.
 * Each presign costs IKA coins for protocol fees.
 *
 * @returns A promise that resolves when fill_presign transaction is executed successfully.
 */
export async function fillPresign() {
	const signer = mkSigner();
	const transaction = new Transaction();

	// Get IKA coin for payment
	const ikaCoin = await getIkaCoin(suiClient, signer.toSuiAddress());

	// Use the DWalletCoordinator ID from the existing requestUtxoSig pattern
	const dwalletCoordinator = "0x4d157b7415a298c56ec2cb1dcab449525fa74aec17ddba376a83a7600f2062fc";

	// Call fill_presign function from nBTC contract
	transaction.add(
		nBTCContractModule.fillPresign({
			arguments: {
				contract: config.nbtc,
				coordinator: dwalletCoordinator,
				suiPayment: transaction.gas,
				ikaPayment: transaction.object(ikaCoin),
			},
		}),
	);

	await executeTransaction(suiClient, transaction);
	console.log("Successfully filled presign buffer");
}
