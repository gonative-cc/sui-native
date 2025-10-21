import { CoordinatorInnerModule, Hash, IkaTransaction, objResToBcs, SessionsManagerModule, SignatureAlgorithm, type DWallet, type IkaClient, type Presign, type SharedDWallet, type ZeroTrustDWallet } from "@ika.xyz/sdk";
import { SuiClient } from '@mysten/sui/client';
import { Transaction } from "@mysten/sui/transactions";
import { createEmptyIkaToken, createIkaClient, createSuiClient, destroyEmptyIkaToken, executeTransaction, mkSigner } from "./common";
import { bcs } from "@mysten/sui/bcs";


// Decode Signature
const MPCPublicOutput = bcs.byteVector();
const MPCSignature = bcs.enum('VersionedSignOutput', {
	V1: MPCPublicOutput,
})
const Signature = bcs.tuple([bcs.byteVector(), bcs.byteVector()]);

export async function presign(
	ikaClient: IkaClient,
	suiClient: SuiClient,
	dWallet: DWallet,
	signatureAlgorithm: SignatureAlgorithm,
) {
	const transaction = new Transaction();

	const ikaTransaction = new IkaTransaction({
		ikaClient,
		transaction,
	});

	const emptyIKACoin = createEmptyIkaToken(transaction, ikaClient.ikaConfig);

	const unverifiedPresignCap = ikaTransaction.requestPresign({
		dWallet,
		signatureAlgorithm,
		ikaCoin: emptyIKACoin,
		suiCoin: transaction.gas,
	});

	let signer = mkSigner();
	transaction.transferObjects([unverifiedPresignCap], signer.toSuiAddress());

	destroyEmptyIkaToken(transaction, ikaClient.ikaConfig, emptyIKACoin);

	const result = await executeTransaction(suiClient, transaction);

	const presignRequestEvent = result.events?.find((event) => {
		return event.type.includes('PresignRequestEvent')
	});

	return SessionsManagerModule.DWalletSessionEvent(
		CoordinatorInnerModule.PresignRequestEvent,
	).fromBase64(presignRequestEvent?.bcs as string);
}


export async function signPublicUserShare(
	ikaClient: IkaClient,
	suiClient: SuiClient,
	dWallet: SharedDWallet,
	presign: Presign,
	message: Uint8Array,
	hashScheme: Hash,
	signatureAlgorithm: SignatureAlgorithm,
) {
	const transaction = new Transaction();

	const ikaTransaction = new IkaTransaction({
		ikaClient,
		transaction,
	});

	const verifiedPresignCap = ikaTransaction.verifyPresignCap({
		presign,
	});

	const emptyIKACoin = createEmptyIkaToken(transaction, ikaClient.ikaConfig);

	// Use appropriate signing method based on DWallet type
	const messageApproval = ikaTransaction.approveMessage({
		dWalletCap: dWallet.dwallet_cap_id,
		signatureAlgorithm,
		hashScheme,
		message,
	});

	await ikaTransaction.requestSign({
		dWallet,
		messageApproval,
		verifiedPresignCap,
		presign,
		message,
		hashScheme,
		ikaCoin: emptyIKACoin,
		suiCoin: transaction.gas,
	});

	destroyEmptyIkaToken(transaction, ikaClient.ikaConfig, emptyIKACoin);

	let result = await executeTransaction(suiClient, transaction);
	let data = result.events?.find(event => event.type.includes("DWalletSessionEvent"));

	return SessionsManagerModule.DWalletSessionEvent(CoordinatorInnerModule.SignRequestEvent).fromBase64(data?.bcs as string);

}

function delay(ms: number) {
	return new Promise(resolve => setTimeout(resolve, ms));
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


export async function sign_message(dWallet: ZeroTrustDWallet | SharedDWallet, message: Uint8Array) {
	let suiClient = createSuiClient()
	let ikaClient = createIkaClient(suiClient);
	await ikaClient.initialize()

	let signAlgo = SignatureAlgorithm.ECDSA;
	const presignRequestEvent = await presign(
		ikaClient,
		suiClient,
		dWallet,
		signAlgo
	);

	await delay(5000);

	const presignObject = await ikaClient.getPresignInParticularState(
		presignRequestEvent.event_data.presign_id,
		'Completed',
	);

	let sign_request = await signPublicUserShare(
		ikaClient,
		suiClient,
		dWallet as SharedDWallet,
		presignObject,
		message,
		Hash.SHA256,
		signAlgo
	);

	await delay(10000)
	let sign = await getSign(suiClient, sign_request.event_data.sign_id);
	let signature = Uint8Array.from(sign.state.Completed?.signature as number[]);
	let decoded = Signature.parse(MPCSignature.parse(signature).V1);

	// (r, s) format for ECDSA signarure
	return decoded
}


