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
import { SuiClient } from "@mysten/sui/client";
import { Transaction } from "@mysten/sui/transactions";
import {
	createIkaClient,
	createSuiClient,
	executeTransaction,
	getIkaCoin,
	mkSigner,
} from "./common";
import { bcs } from "@mysten/sui/bcs";

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
