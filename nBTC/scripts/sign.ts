import {
	CoordinatorInnerModule,
	Curve,
	Hash,
	IkaTransaction,
	SessionsManagerModule,
	SignatureAlgorithm,
	type IkaClient,
	type SharedDWallet,
} from "@ika.xyz/sdk";
import { SuiClient } from "@mysten/sui/client";
import { Transaction } from "@mysten/sui/transactions";
import {
	createIkaClient,
	createSuiClient,
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
		signatureAlgorithm: SignatureAlgorithm.ECDSASecp256k1,
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
 * Computes the Bitcoin Signature Hash (SigHash) required for signing a transaction.
 *
 * This function utilizes Sui client data and transaction configuration to determine
 * the final hash that needs to be signed by the dWallet network.
 *
 * @param suiClient The initialized Sui client instance for network interaction.
 * @param r A nonce or session identifier related to the transaction.
 * @param input_idx The index of the input being signed in the raw Bitcoin transaction.
 * @param config The sui package config
 * @returns A promise that resolves to the computed BTC SigHash as a hexadecimal string.
 */
export async function getSigHash(
	suiClient: SuiClient,
	r: number,
	inputIdx: number,
	config: Config,
) {
	let tx = new Transaction();

	let redeem = tx.add(
		nBTCContractModule.redeemRequest({
			arguments: {
				contract: config.nbtc,
				requestId: r,
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
				inputIdx,
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
 * Creates the  UnverifiedPartialUserSignatureCap object by requesting a future signature on Sui.
 *
 * This process involves verifying a completed presignature and authorizing the signing
 * of a specific message (`message`, usually a transaction hash) by the dWallet.
 *
 * @param ikaClient The initialized Ika client for protocol-specific calls.
 * @param suiClient The initialized Sui client instance.
 * @param dwalletId The ID of the active dWallet to be used.
 * @param presignId The ID of the completed presign request.
 * @param message The hash or message data (Uint8Array) to be signed.
 * @returns A promise that resolves to the completed UnverifiedPartialUserSignatureCap object.
 */
export async function createUserSigCap(
	ikaClient: IkaClient,
	suiClient: SuiClient,
	dwalletId: string,
	presignId: string,
	message: Uint8Array,
) {
	let transaction = new Transaction();
	let ikaTransaction = new IkaTransaction({
		ikaClient,
		transaction,
	});
	const signer = mkSigner();
	const dWallet = await ikaClient.getDWalletInParticularState(dwalletId, "Active");
	const ikaCoin = await getIkaCoin(suiClient, signer.toSuiAddress());
	const presign = await ikaClient.getPresignInParticularState(presignId, "Completed");
	const partialUserSignatureCap = await ikaTransaction.requestFutureSign({
		dWallet: dWallet as SharedDWallet,
		hashScheme: Hash.SHA256,
		ikaCoin: transaction.object(ikaCoin),
		message,
		presign,
		signatureScheme: SignatureAlgorithm.ECDSASecp256k1,
		suiCoin: transaction.gas,
		verifiedPresignCap: ikaTransaction.verifyPresignCap({
			presign,
		}),
		// Note: No encryptedUserSecretKeyShare parameter for shared dWallets
	});

	transaction.transferObjects([partialUserSignatureCap], signer.toSuiAddress());

	let result = await executeTransaction(suiClient, transaction);

	const event = result.events?.find((event) => {
		return event.type.includes("FutureSignRequestEvent");
	});

	let eventDecoded = SessionsManagerModule.DWalletSessionEvent(
		CoordinatorInnerModule.FutureSignRequestEvent,
	).fromBase64(event?.bcs as string);

	const partialCentralizedSignedMessageID =
		eventDecoded.event_data.partial_centralized_signed_message_id;

	return await ikaClient.getPartialUserSignatureInParticularState(
		partialCentralizedSignedMessageID,
		"NetworkVerificationCompleted",
		{ timeout: 60000, interval: 1000 },
	);
}

/**
 * Executes a Move call on Sui to request the final partial signature for a specific
 * Bitcoin input index of a redeem transaction.
 *
 * This function consumes the `UnverifiedPartialUserSignatureCap`
 * (`capid`) to request the dWallet network to sign the transaction input.
 *
 * @param r The nonce or session identifier related to the redeem request.
 * @param input_idx The index of the Bitcoin input being signed (0-indexed).
 * @param capid The object ID of the `UnverifiedPartialUserSignatureCap` created earlier.
 * @param config The configuration object containing IDs like `packageId` and `nbtc` object ID.
 * @returns A promise that resolves to the unique Sign ID (`sign_id`) as a string.
 */
export async function requestSignatureForInput(
	r: number,
	input_idx: number,
	capid: string,
	config: Config,
) {
	let suiClient = createSuiClient();
	let ikaClient = createIkaClient(suiClient);
	await ikaClient.initialize();
	const signer = mkSigner();

	let tx = new Transaction();
	let ikaTx = new IkaTransaction({
		ikaClient,
		transaction: tx,
	});

	const ikaCoin = await getIkaCoin(suiClient, signer.toSuiAddress());

	let verifiedCap = tx.moveCall({
		target: "0x6573a6c13daf26a64eb8a37d3c7a4391b353031e223072ca45b1ff9366f59293::coordinator::verify_partial_user_signature_cap",
		arguments: [
			tx.object("0x4d157b7415a298c56ec2cb1dcab449525fa74aec17ddba376a83a7600f2062fc"),
			tx.object(capid),
		],
	});
	tx.add(
		nBTCContractModule.requestSignatureForInput({
			arguments: {
				contract: config.nbtc,
				dwalletCoordinator:
					"0x4d157b7415a298c56ec2cb1dcab449525fa74aec17ddba376a83a7600f2062fc",
				requestId: r,
				inputIdx: input_idx,
				userSigCap: verifiedCap,
				sessionIdentifier: ikaTx.createSessionIdentifier(),
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
 * @param r redeem request ID
 * @param input_idx The index of the Bitcoin input being signed (0-indexed).
 * @param signId The object ID of the sign session we request before
 * @param config The configuration object containing IDs like `packageId` and `nbtc` object ID.
 * @returns A promise that resolves when the verification transaction is executed successfully (no explicit return value).
 */
export async function verifySignature(
	suiClient: SuiClient,
	r: number,
	input_idx: number,
	signId: string,
	config: Config,
) {
	const tx = new Transaction();
	tx.add(
		nBTCContractModule.validateSignature({
			arguments: {
				contract: config.nbtc,
				dwalletCoordinator:
					"0x4d157b7415a298c56ec2cb1dcab449525fa74aec17ddba376a83a7600f2062fc",
				redeemId: r,
				inputIdx: input_idx,
				signId: signId,
			},
		}),
	);

	await executeTransaction(suiClient, tx);
}

/**
 * Return a raw signed BTC redeem transaction
 *
 * @param suiClient The initialized Sui client instance.
 * @param r redeem request ID
 * @param config The configuration object containing IDs like `packageId` and `nbtc` object ID.
 * @returns A redeem tx in Hex format
 */
export async function getRedeemBtcTx(suiClient: SuiClient, r: number, config: Config) {
	let tx = new Transaction();

	let redeem = tx.add(
		nBTCContractModule.redeemRequest({
			arguments: {
				contract: config.nbtc,
				requestId: r,
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
		RedeemRequestModule.rawSignedTx({
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
