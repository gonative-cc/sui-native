import {
	CoordinatorInnerModule,
	Curve,
	Hash,
	IkaTransaction,
	SessionsManagerModule,
	SignatureAlgorithm,
	createUserSignMessageWithPublicOutput,
	type IkaClient,
	type SharedDWallet,
} from "@ika.xyz/sdk";
import { SuiClient } from "@mysten/sui/client";
import { Transaction } from "@mysten/sui/transactions";
import {
	createIkaClient,
	createSuiClient,
	delay,
	executeTransaction,
	getIkaCoin,
	mkSigner,
	type Config,
} from "./common";
import { bcs } from "@mysten/sui/bcs";
import { toHex } from "@mysten/sui/utils";
import { nBTCContractModule, RedeemRequestModule } from "../../sdk/nBTC/src";
/**
 * Initiates a global presign object and return presign id
 *
 * @returns A promise that resolves to the unique Presign ID (`presign_id`) as a string.
 */
export async function globalPreSign() {
	let suiClient = createSuiClient();
	let ikaClient = createIkaClient(suiClient);
	await ikaClient.initialize();

	const signer = mkSigner();
	const transaction = new Transaction();
	const ikaTransaction = new IkaTransaction({
		ikaClient,
		transaction,
	});
	const ikaCoin = await getIkaCoin(suiClient, signer.toSuiAddress());
	const dWalletEncryptionKey = await ikaClient.getLatestNetworkEncryptionKey();

	const presignCap = ikaTransaction.requestGlobalPresign({
		curve: Curve.SECP256K1,
		signatureAlgorithm: SignatureAlgorithm.Taproot,
		ikaCoin: transaction.object(ikaCoin),
		suiCoin: transaction.gas,
		dwalletNetworkEncryptionKeyId: dWalletEncryptionKey.id,
	});

	transaction.transferObjects([presignCap], signer.toSuiAddress());

	let result = await executeTransaction(suiClient, transaction);
	const event = result.events?.find((event) => {
		return event.type.includes("PresignRequestEvent");
	});
	let eventDecoded = SessionsManagerModule.DWalletSessionEvent(
		CoordinatorInnerModule.PresignRequestEvent,
	).fromBase64(event?.bcs as string);
	return eventDecoded.event_data.presign_id;
}

/**
 * Creates the nbtc_public_signature using createUserSignMessageWithCentralizedOutput
 *
 * @param ikaClient The initialized Ika client for protocol-specific calls
 * @param dwalletId The ID of the active dWallet to be used
 * @param presignId The PreSign ID get from globalPreSign
 * @param message data (Uint8Array) to be signed
 * @returns A promise that resolves to a msg_central_sig.
 */
export async function createUserSigMessage(
	ikaClient: IkaClient,
	dwalletId: string,
	presignId: string,
	message: Uint8Array,
): Promise<Uint8Array> {
	const dWallet = await ikaClient.getDWalletInParticularState(dwalletId, "Active");
	// wait 10s to avoid "Many Request" error when we use sui testnet
	await delay(10000);
	// TODO: We should cache protocol public parameters
	const protocolPublicParameters = await ikaClient.getProtocolPublicParameters(
		dWallet,
		Curve.SECP256K1,
	);
	const centralizedDkgOutput = Buffer.from(dWallet.state.Active.public_output) as Uint8Array;
	const userSecretKeyShare = new Uint8Array(dWallet.public_user_secret_key_share as number[]);
	const presign = await ikaClient.getPresign(presignId);

	return createUserSignMessageWithPublicOutput(
		protocolPublicParameters,
		centralizedDkgOutput,
		userSecretKeyShare,
		new Uint8Array(presign.state.Completed?.presign as number[]),
		message,
		Hash.SHA256,
		SignatureAlgorithm.Taproot,
		Curve.SECP256K1,
	);
}

/**
 * Calculates the signature hash for a specific input of a redeem transaction.
 *
 * @param suiClient The Sui client instance.
 * @param redeemId The ID of the redeem request.
 * @param inputId The index of the Bitcoin input (0-indexed).
 * @param config The configuration object containing IDs like `packageId` and `nbtc` object ID.
 * @returns A promise that resolves to the signature hash as a Uint8Array.
 */
export async function getSignHash(
	suiClient: SuiClient,
	redeemId: number,
	inputId: number,
	config: Config,
) {
	let tx = new Transaction();

	let redeem = tx.add(
		nBTCContractModule.redeemRequest({
			arguments: {
				contract: config.nbtc,
				redeemId: redeemId,
			},
		}),
	);

	let storage = tx.add(
		nBTCContractModule.storage({
			arguments: {
				contract: config.nbtc,
			},
		}),
	);

	tx.add(
		RedeemRequestModule.sigHash({
			arguments: {
				r: redeem,
				inputId,
				storage,
			},
		}),
	);

	let ans = await suiClient.devInspectTransactionBlock({
		transactionBlock: tx,
		sender: mkSigner().toSuiAddress(),
	});
	let encoded = ans.results![2]?.returnValues![0]![0]!;
	return bcs.byteVector().parse(Uint8Array.from(encoded));
}

/**
 * Executes a Move call on Sui to request the final partial signature for a specific
 * Bitcoin input index of a redeem transaction.
 *
 * This function consumes the `UnverifiedPresignCap`
 * (`capid`) to request the dWallet network to sign the transaction input.
 *
 * @param redeemId The ID of the redeem request.
 * @param inputId The index of the Bitcoin input being signed (0-indexed).
 * @param presignId The presignId we use to get the unverifiedPresignCap ID
 * @param msgCentralSig - nBTC public sig share for the Ika MPC process.
 * @param config The configuration object containing IDs like `packageId` and `nbtc` object ID.
 */
export async function requestUtxoSig(
	suiClient: SuiClient,
	ikaClient: IkaClient,
	redeemId: number,
	inputId: number,
	presignId: string,
	msgCentralSig: Uint8Array,
	config: Config,
) {
	const signer = mkSigner();

	let tx = new Transaction();

	const ikaCoin = await getIkaCoin(suiClient, signer.toSuiAddress());
	const unverifiedPresignCap = (
		await ikaClient.getPresignInParticularState(presignId, "Completed")
	).cap_id;

	tx.add(
		nBTCContractModule.requestUtxoSig({
			arguments: {
				contract: config.nbtc,
				dwalletCoordinator:
					"0x4d157b7415a298c56ec2cb1dcab449525fa74aec17ddba376a83a7600f2062fc",
				redeemId,
				inputId,
				msgCentralSig: Array.from(msgCentralSig),
				presign: unverifiedPresignCap,
				paymentIka: ikaCoin,
				paymentSui: tx.gas,
			},
		}),
	);
	let result = await executeTransaction(suiClient, tx);

	const event = result.events?.find((event) => {
		return event.type.includes("SignRequestEvent");
	});
	let eventDecoded = SessionsManagerModule.DWalletSessionEvent(
		CoordinatorInnerModule.SignRequestEvent,
	).fromBase64(event?.bcs as string);
	return eventDecoded.event_data.sign_id;
}
/**
 * Executes a Move call on Sui to verify the validity of a signature create by Ika for
 * a Bitcoin transaction input details.
 *
 * @param suiClient The initialized Sui client instance.
 * @param redeemId The ID of the redeem request.
 * @param inputId The index of the Bitcoin input being signed (0-indexed).
 * @param signId The object ID of the sign session returned from requestUtxoSig
 * @param config The configuration object containing IDs like `packageId` and `nbtc` object ID.
 * @returns A promise that resolves when the verification transaction is executed successfully (no explicit return value).
 */
export async function verifySignature(
	suiClient: SuiClient,
	redeemId: number,
	inputId: number,
	signId: string,
	config: Config,
) {
	const tx = new Transaction();
	tx.add(
		nBTCContractModule.recordSignature({
			arguments: {
				contract: config.nbtc,
				dwalletCoordinator:
					"0x4d157b7415a298c56ec2cb1dcab449525fa74aec17ddba376a83a7600f2062fc",
				redeemId,
				inputIds: [BigInt(inputId)],
				signIds: [signId],
			},
		}),
	);

	await executeTransaction(suiClient, tx);
}

/**
 * Return a raw signed BTC redeem transaction
 *
 * @param suiClient The initialized Sui client instance.
 * @param redeemId The ID of the redeem request.
 * @param config The configuration object containing IDs like `packageId` and `nbtc` object ID.
 * @returns A redeem tx in Hex format
 */
export async function getRedeemBtcTx(suiClient: SuiClient, redeemId: number, config: Config) {
	let tx = new Transaction();

	let redeem = tx.add(
		nBTCContractModule.redeemRequest({
			arguments: {
				contract: config.nbtc,
				redeemId,
			},
		}),
	);

	let storage = tx.add(
		nBTCContractModule.storage({
			arguments: {
				contract: config.nbtc,
			},
		}),
	);

	tx.add(
		RedeemRequestModule.composeTx({
			arguments: {
				r: redeem,
				storage: storage,
			},
		}),
	);

	let result = await suiClient.devInspectTransactionBlock({
		transactionBlock: tx,
		sender: mkSigner().toSuiAddress(),
	});
	let encoded = result.results![2]?.returnValues![0]![0]!;
	let decoded = bcs.byteVector().parse(Uint8Array.from(encoded));
	return toHex(decoded);
}
