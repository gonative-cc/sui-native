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
 * Refills the nBTC contract's presign queue if it falls below MIN_PRESIGN_QUEUE_SIZE (30)
 *
 * This function checks the current presign queue size and if below threshold,
 * creates enough presigns to reach 2*MIN_PRESIGN_QUEUE_SIZE (60).
 * Each presign costs IKA coins for protocol fees.
 *
 * This function should be called periodically (e.g., every hour) to maintain
 * an adequate supply of presignatures for Bitcoin transactions.
 *
 * @returns A promise that resolves when refill_presign_queue transaction is executed successfully.
 */
export async function refillPresignQueue() {
	const signer = mkSigner();
	const transaction = new Transaction();

	// Get IKA coin for payment
	const ikaCoin = await getIkaCoin(suiClient, signer.toSuiAddress());

	// Use the DWalletCoordinator ID from the existing requestUtxoSig pattern
	const dwalletCoordinator = "0x4d157b7415a298c56ec2cb1dcab449525fa74aec17ddba376a83a7600f2062fc";

	// Call refill_presign_queue function from nBTC contract
	transaction.add(
		nBTCContractModule.refillPresignQueue({
			arguments: {
				contract: config.nbtc,
				coordinator: dwalletCoordinator,
				suiPayment: transaction.gas,
				ikaPayment: transaction.object(ikaCoin),
			},
		}),
	);

	await executeTransaction(suiClient, transaction);
	console.log("Successfully refilled presign queue");
}
