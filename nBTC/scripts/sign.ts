import {
	CoordinatorInnerModule,
	Curve,
	Hash,
	IkaTransaction,
	objResToBcs,
	SessionsManagerModule,
	SignatureAlgorithm,
	UserShareEncryptionKeys,
	type DWallet,
	type DWalletWithState,
	type IkaClient,
	type Presign,
	type SharedDWallet,
	type ZeroTrustDWallet,
} from "@ika.xyz/sdk";
import { SuiClient, type SuiObjectChangeCreated } from "@mysten/sui/client";
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

// Decode Signature
const MPCPublicOutput = bcs.byteVector();
const MPCSignature = bcs.enum("VersionedSignOutput", {
	V1: MPCPublicOutput,
});
const Signature = bcs.tuple([bcs.byteVector(), bcs.byteVector()]);

function delay(ms: number) {
	return new Promise((resolve) => setTimeout(resolve, ms));
}

export async function globalPreSign() {
	let suiClient = createSuiClient();
	let ikaClient = createIkaClient(suiClient);
	await ikaClient.initialize();

	const signer = mkSigner();
	const transaction = new Transaction();
	const ikaTransaction = new IkaTransaction({
		ikaClient,
		transaction
	})
	const ikacoin = await getIkaCoin(suiClient, signer.toSuiAddress());
	const dWalletEncryptionKey = await ikaClient.getLatestNetworkEncryptionKey();

	const presignCap = ikaTransaction.requestGlobalPresign({
		curve: Curve.SECP256K1,
		signatureAlgorithm: SignatureAlgorithm.ECDSASecp256k1,
		ikaCoin: transaction.object(ikacoin as string),
		suiCoin: transaction.gas,
		dwalletNetworkEncryptionKeyId: dWalletEncryptionKey.id
	});

	transaction.transferObjects([presignCap], signer.toSuiAddress());

	let result = await executeTransaction(suiClient, transaction);
	const event = result.events?.find((event) => {
		return (
			event.type.includes("PresignRequestEvent")
		);
	});
	let eventDecoded = SessionsManagerModule.DWalletSessionEvent(
		CoordinatorInnerModule.PresignRequestEvent,
	).fromBase64(event?.bcs as string);
	return eventDecoded.event_data.presign_id

}
async function getSign(suiClient: SuiClient, signID: string) {
	return suiClient
		.getObject({
			id: signID,
			options: { showBcs: true },
		})
		.then((obj) => {
			return CoordinatorInnerModule.SignSession.fromBase64(objResToBcs(obj));
		});
}

export async function sign_message(dWallet: DWalletWithState<'Active'>, presign_id: string, message: Uint8Array) {
	let suiClient = createSuiClient();
	let ikaClient = createIkaClient(suiClient);
	await ikaClient.initialize();
	const signer = mkSigner();

	const transaction = new Transaction();
	const ikaTransaction = new IkaTransaction({
		ikaClient,
		transaction,
	})

	const ikaCoin = await getIkaCoin(suiClient, signer.toSuiAddress());
	const presign = await ikaClient.getPresignInParticularState(presign_id, 'Completed');
	const partialUserSignatureCap = await ikaTransaction.requestFutureSign({
		dWallet: dWallet as SharedDWallet,
		hashScheme: Hash.SHA256,
		ikaCoin: transaction.object(ikaCoin as string),
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
		return (
			event.type.includes("FutureSignRequestEvent")
		);
	});

	let eventDecoded = SessionsManagerModule.DWalletSessionEvent(
		CoordinatorInnerModule.FutureSignRequestEvent,
	).fromBase64(event?.bcs as string);

	const partialCentralizedSignedMessageID = eventDecoded.event_data.partial_centralized_signed_message_id;


	const verifiedPartialSignature = await ikaClient.getPartialUserSignatureInParticularState(
		partialCentralizedSignedMessageID,
		'NetworkVerificationCompleted',
		{ timeout: 60000, interval: 1000 },
	);


	// 	// Fetch the completed signature
	// 	const signature = await ikaClient.getSignInParticularState(
	// 		signId,
	// 		curve,
	// 		SignatureAlgorithm.ECDSASecp256r1,
	// 		'Completed',
	// 		{ timeout: 60000, interval: 1000 },
	// 	);
	//
	// 	const rawSignature = Uint8Array.from(signature.state.Completed.signature);
	//

	console.log(verifiedPartialSignature);
	return verifiedPartialSignature
}


export async function completeFetureRequest(dWallet: DWalletWithState<'Active'>, message: Uint8Array, partialUserSignatureCap: string) {
	let suiClient = createSuiClient();
	let ikaClient = createIkaClient(suiClient);
	await ikaClient.initialize();
	const signer = mkSigner();

	const transaction = new Transaction();
	const ikaTransaction = new IkaTransaction({
		ikaClient,
		transaction,
	})

	const ikaCoin = await getIkaCoin(suiClient, signer.toSuiAddress());
	// await executeTransaction(suiClient, transaction);
	// Should match your curve and signature scheme used previously in requestFutureSign
	const messageApproval = ikaTransaction.approveMessage({
		message,
		curve: Curve.SECP256K1,
		dWalletCap: dWallet.dwallet_cap_id,
		signatureAlgorithm: SignatureAlgorithm.ECDSASecp256k1,
		hashScheme: Hash.SHA256,
	});

	const signId = ikaTransaction.futureSign({
		suiCoin: transaction.gas,
		ikaCoin: transaction.object(ikaCoin as string),
		messageApproval,
		partialUserSignatureCap: partialUserSignatureCap,
	});

	await executeTransaction(suiClient, transaction);
}

export async function getSigHash(suiClient: SuiClient, r: number, input_idx: number, config: Config) {
	let tx = new Transaction();

	let redeem = tx.moveCall({
		target: `${config.packageId}::nbtc::redeem_request`,
		arguments: [
			tx.object(config.nbtc),
			tx.pure.u64(r)
		]
	})


	let storage = tx.moveCall({
		target: `${config.packageId}::nbtc::storage`,
		arguments: [
			tx.object(config.nbtc)
		]
	});


	let sig = tx.moveCall(
		{
			target: `${config.packageId}::redeem_request::sig_hash`,
			arguments: [
				redeem,
				tx.pure.u32(input_idx),
				storage
			]
		}
	)

	let status = tx.moveCall(
		{
			target: `${config.packageId}::redeem_request::status`,
			arguments: [
				redeem,
			]
		}
	)

	tx.moveCall(
		{
			target: `${config.packageId}::redeem_request::is_signed`,
			arguments: [
				status,
			]
		}
	)
	tx.moveCall(
		{
			target: `${config.packageId}::redeem_request::has_signature`,
			arguments: [
				redeem,
				tx.pure.u32(0)
			]
		}
	)

	let ans = await suiClient.devInspectTransactionBlock({
		transactionBlock: tx,
		sender: mkSigner().toSuiAddress()
	})
	let encoded = ans.results![2]?.returnValues![0]![0]!
	let decoded = bcs.byteVector().parse(Uint8Array.from(encoded))
	return decoded
}

export async function createUserSigCap(ikaClient: IkaClient, suiClient: SuiClient, dwalletId: string, presign_id: string, message: Uint8Array) {
	let transaction = new Transaction();
	let ikaTransaction = new IkaTransaction({
		ikaClient,
		transaction,
	})
	const signer = mkSigner();
	const dWallet = await ikaClient.getDWalletInParticularState(dwalletId, 'Active');
	const ikaCoin = await getIkaCoin(suiClient, signer.toSuiAddress());
	const presign = await ikaClient.getPresignInParticularState(presign_id, 'Completed');
	const partialUserSignatureCap = await ikaTransaction.requestFutureSign({
		dWallet: dWallet as SharedDWallet,
		hashScheme: Hash.SHA256,
		ikaCoin: transaction.object(ikaCoin as string),
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
		return (
			event.type.includes("FutureSignRequestEvent")
		);
	});

	let eventDecoded = SessionsManagerModule.DWalletSessionEvent(
		CoordinatorInnerModule.FutureSignRequestEvent,
	).fromBase64(event?.bcs as string);

	const partialCentralizedSignedMessageID = eventDecoded.event_data.partial_centralized_signed_message_id;


	const verifiedPartialSignature = await ikaClient.getPartialUserSignatureInParticularState(
		partialCentralizedSignedMessageID,
		'NetworkVerificationCompleted',
		{ timeout: 60000, interval: 1000 },
	);

	return verifiedPartialSignature
}

export async function request_signature_for_input(r: number, input_idx: number, capid: string, config: Config) {
	let suiClient = createSuiClient();
	let ikaClient = createIkaClient(suiClient);
	await ikaClient.initialize();
	const signer = mkSigner();

	let tx = new Transaction();
	let ikaTx = new IkaTransaction({
		ikaClient,
		transaction: tx
	});

	const ikaCoin = await getIkaCoin(suiClient, signer.toSuiAddress());

	let verifiedCap = tx.moveCall({
		target: "0x6573a6c13daf26a64eb8a37d3c7a4391b353031e223072ca45b1ff9366f59293::coordinator::verify_partial_user_signature_cap",
		arguments: [
			tx.object("0x4d157b7415a298c56ec2cb1dcab449525fa74aec17ddba376a83a7600f2062fc"),
			tx.object(capid)
		]
	})
	tx.moveCall({
		target: `${config.packageId}::nbtc::request_signature_for_input`,
		arguments: [
			tx.object(config.nbtc),
			tx.object("0x4d157b7415a298c56ec2cb1dcab449525fa74aec17ddba376a83a7600f2062fc"),
			tx.pure.u64(r),
			tx.pure.u32(input_idx),
			verifiedCap,
			ikaTx.createSessionIdentifier(),
			tx.object(ikaCoin as string),
			tx.gas
		]
	})
	await executeTransaction(suiClient, tx);
}

export async function verifySignature(suiClient: SuiClient, r: number, input_idx: number, signId: string, config: Config) {
	const tx = new Transaction();
	tx.moveCall({
		target: `${config.packageId}::nbtc::validate_signature`,
		arguments: [
			tx.object(config.nbtc),
			tx.object("0x4d157b7415a298c56ec2cb1dcab449525fa74aec17ddba376a83a7600f2062fc"),
			tx.pure.u64(r),
			tx.pure.u32(input_idx),
			tx.pure.id(signId)
		]
	})

	await executeTransaction(suiClient, tx);
}

// get raw tx for redeem_request after signed
export async function getRawTx(suiClient: SuiClient, r: number, config: Config) {
	let tx = new Transaction();
	let redeem = tx.moveCall({
		target: `${config.packageId}::nbtc::redeem_request`,
		arguments: [
			tx.object(config.nbtc),
			tx.pure.u64(r)
		]
	})
	let storage = tx.moveCall({
		target: `${config.packageId}::nbtc::storage`,
		arguments: [
			tx.object(config.nbtc)
		]
	});
	tx.moveCall(
		{
			target: `${config.packageId}::redeem_request::raw_signed_tx`,
			arguments: [
				redeem,
				storage
			]
		}
	)

	let ans = await suiClient.devInspectTransactionBlock({
		transactionBlock: tx,
		sender: mkSigner().toSuiAddress()
	})
	let encoded = ans.results![2]?.returnValues![0]![0]!
	let decoded = bcs.byteVector().parse(Uint8Array.from(encoded))
	return toHex(decoded)
}

