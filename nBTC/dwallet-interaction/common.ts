import { bcs, fromBase64, toHex } from "@mysten/bcs";
import { SuiClient } from "@mysten/sui/client";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import { randomBytes } from "@noble/hashes/utils.js";
import {
	UserShareEncryptionKeys,
	Curve,
	IkaTransaction,
	IkaClient,
	getNetworkConfig,
	SessionsManagerModule,
	CoordinatorInnerModule,
	prepareDKGSecondRoundAsync,
	publicKeyFromDWalletOutput,
	type IkaConfig,
	type DWallet,
	type DKGSecondRoundRequestInput,
	type DWalletCap,
	type ZeroTrustDWallet,
} from "@ika.xyz/sdk";
import { Transaction, type TransactionObjectArgument } from "@mysten/sui/transactions";
import "dotenv/config";

export function createEmptyIkaToken(tx: Transaction, ikaConfig: IkaConfig) {
	return tx.moveCall({
		target: `0x2::coin::zero`,
		arguments: [],
		typeArguments: [`${ikaConfig.packages.ikaPackage}::ika::IKA`],
	});
}
export function destroyEmptyIkaToken(
	tx: Transaction,
	ikaConfig: IkaConfig,
	ikaToken: TransactionObjectArgument,
) {
	return tx.moveCall({
		target: `0x2::coin::destroy_zero`,
		arguments: [ikaToken],
		typeArguments: [`${ikaConfig.packages.ikaPackage}::ika::IKA`],
	});
}

export async function generateKeypair() {
	const seed = new Uint8Array(randomBytes(32));
	const userKeypair = Ed25519Keypair.deriveKeypairFromSeed(
		toHex(new Uint8Array(randomBytes(32))),
	);
	const userShareEncryptionKeys = await UserShareEncryptionKeys.fromRootSeedKey(
		seed,
		Curve.SECP256K1,
	);

	return {
		userShareEncryptionKeys,
		signerAddress: userKeypair.getPublicKey().toSuiAddress(),
		signerPublicKey: userKeypair.getPublicKey().toRawBytes(),
	};
}

export function createSuiClient() {
	return new SuiClient({
		url: "https://fullnode.testnet.sui.io:443",
	});
}

export function mkSigner() {
	if (process.env.ENCODE_SK) {
		let sk = fromBase64(process.env.ENCODE_SK);
		return Ed25519Keypair.fromSecretKey(sk.slice(1));
	}
	if (process.env.MNEMONIC) {
		return Ed25519Keypair.deriveKeypair(process.env.MNEMONIC);
	}
	throw new Error(
		"Missing required environment variable: Please set either ENCODE_SK or MNEMONIC.",
	);
}

export function createIkaClient(suiClient: SuiClient) {
	return new IkaClient({
		suiClient,
		config: getNetworkConfig("testnet"),
	});
}

export async function executeTransaction(suiClient: SuiClient, transaction: Transaction) {
	return suiClient.signAndExecuteTransaction({
		transaction,
		signer: mkSigner(),
		options: {
			showEvents: true,
		},
	});
}

async function registerEncryptionKey(
	ikaClient: IkaClient,
	suiClient: SuiClient,
	userShares: UserShareEncryptionKeys,
) {
	const transaction = new Transaction();
	const ikaTransaction = new IkaTransaction({
		ikaClient,
		transaction,
		userShareEncryptionKeys: userShares,
	});

	await ikaTransaction.registerEncryptionKey({
		curve: Curve.SECP256K1,
	});

	const result = await executeTransaction(suiClient, transaction);

	const createdEncryptionKeyEvent = result.events?.find((event) => {
		return event.type.includes("CreatedEncryptionKeyEvent");
	});

	return CoordinatorInnerModule.CreatedEncryptionKeyEvent.fromBase64(
		createdEncryptionKeyEvent?.bcs as string,
	);
}

export async function requestDKGFirstRound(ikaClient: IkaClient, suiClient: SuiClient) {
	let signer = mkSigner();
	const transaction = new Transaction();

	const ikaTransaction = new IkaTransaction({
		ikaClient,
		transaction,
	});

	const emptyIKACoin = createEmptyIkaToken(transaction, ikaClient.ikaConfig);

	const dwalletCap = await ikaTransaction.requestDWalletDKGFirstRoundAsync({
		curve: 0,
		ikaCoin: emptyIKACoin,
		suiCoin: transaction.gas,
	});

	transaction.transferObjects([dwalletCap], signer.toSuiAddress());

	destroyEmptyIkaToken(transaction, ikaClient.ikaConfig, emptyIKACoin);

	const result = await executeTransaction(suiClient, transaction);

	const startDKGFirstRoundEvents = result.events
		?.map((event) =>
			event.type.includes("DWalletDKGFirstRoundRequestEvent") &&
			event.type.includes("DWalletSessionEvent")
				? SessionsManagerModule.DWalletSessionEvent(
						CoordinatorInnerModule.DWalletDKGFirstRoundRequestEvent,
					).fromBase64(event.bcs)
				: null,
		)
		.filter(Boolean);

	const dwalletID = startDKGFirstRoundEvents?.[0]?.event_data.dwallet_id;
	const sessionIdentifierPreimage = startDKGFirstRoundEvents?.[0]?.session_identifier_preimage;

	return {
		dwalletID: dwalletID,
		sessionIdentifierPreimage: new Uint8Array(sessionIdentifierPreimage as number[]),
	};
}

export async function requestDkgSecondRound(
	ikaClient: IkaClient,
	suiClient: SuiClient,
	dWallet: DWallet,
	dkgSecondRoundRequestInput: DKGSecondRoundRequestInput,
	userShareEncryptionKeys: UserShareEncryptionKeys,
) {
	const transaction = new Transaction();

	const ikaTransaction = new IkaTransaction({
		ikaClient,
		transaction,
		userShareEncryptionKeys,
	});

	const emptyIKACoin = createEmptyIkaToken(transaction, ikaClient.ikaConfig);

	//0xf02f5960c94fce1899a3795b5d11fd076bc70a8d0e20a2b19923d990ed490730::sessions_manager::<0xf02f5960c94fce1899a3795b5d11fd076bc70a8d0e20a2b19923d990ed490730::coordinator_inner::SignRequestEvent>
	ikaTransaction.requestDWalletDKGSecondRound({
		dWalletCap: dWallet.dwallet_cap_id,
		dkgSecondRoundRequestInput,
		ikaCoin: emptyIKACoin,
		suiCoin: transaction.gas,
	});

	destroyEmptyIkaToken(transaction, ikaClient.ikaConfig, emptyIKACoin);

	const result = await executeTransaction(suiClient, transaction);

	const dkgSecondRoundRequestEvent = result.events?.find((event) => {
		return (
			event.type.includes("DWalletDKGSecondRoundRequestEvent") &&
			event.type.includes("DWalletSessionEvent")
		);
	});

	return SessionsManagerModule.DWalletSessionEvent(
		CoordinatorInnerModule.DWalletDKGSecondRoundRequestEvent,
	).fromBase64(dkgSecondRoundRequestEvent?.bcs as string);
}

async function acceptEncryptedUserShare(
	ikaClient: IkaClient,
	suiClient: SuiClient,
	dWallet: ZeroTrustDWallet,
	userPublicOutput: Uint8Array,
	secondRoundMoveResponse: {
		event_data: {
			encrypted_user_secret_key_share_id: string;
		};
	},
	userShareEncryptionKeys: UserShareEncryptionKeys,
) {
	const transaction = new Transaction();

	const ikaTransaction = new IkaTransaction({
		ikaClient,
		transaction,
		userShareEncryptionKeys,
	});

	await ikaTransaction.acceptEncryptedUserShare({
		dWallet,
		userPublicOutput,
		encryptedUserSecretKeyShareId:
			secondRoundMoveResponse.event_data.encrypted_user_secret_key_share_id,
	});

	await executeTransaction(suiClient, transaction);
}

export async function makeDWalletUserSecretKeySharesPublic(
	ikaClient: IkaClient,
	suiClient: SuiClient,
	dWallet: ZeroTrustDWallet,
	secretShare: Uint8Array,
) {
	const transaction = new Transaction();

	const ikaTransaction = new IkaTransaction({
		ikaClient,
		transaction,
	});

	const emptyIKACoin = createEmptyIkaToken(transaction, ikaClient.ikaConfig);

	ikaTransaction.makeDWalletUserSecretKeySharesPublic({
		dWallet,
		secretShare,
		ikaCoin: emptyIKACoin,
		suiCoin: transaction.gas,
	});

	destroyEmptyIkaToken(transaction, ikaClient.ikaConfig, emptyIKACoin);

	await executeTransaction(suiClient, transaction);
}

export async function createShareDwallet() {
	let keypairs = await generateKeypair();
	let suiClient = createSuiClient();
	let ikaClient = createIkaClient(suiClient);
	await ikaClient.initialize();

	const { dwalletID, sessionIdentifierPreimage } = await requestDKGFirstRound(
		ikaClient,
		suiClient,
	);

	await registerEncryptionKey(ikaClient, suiClient, keypairs.userShareEncryptionKeys);
	const dWallet = await ikaClient.getDWalletInParticularState(
		dwalletID as string,
		"AwaitingUserDKGVerificationInitiation",
		{
			timeout: 300000,
		},
	);

	const dkgSecondRoundRequestInput = await prepareDKGSecondRoundAsync(
		ikaClient,
		dWallet,
		sessionIdentifierPreimage,
		keypairs.userShareEncryptionKeys,
	);

	const secondRoundMoveResponse = await requestDkgSecondRound(
		ikaClient,
		suiClient,
		dWallet,
		dkgSecondRoundRequestInput,
		keypairs.userShareEncryptionKeys,
	);

	const awaitingKeyHolderSignatureDWallet = await ikaClient.getDWalletInParticularState(
		dwalletID as string,
		"AwaitingKeyHolderSignature",
	);
	await acceptEncryptedUserShare(
		ikaClient,
		suiClient,
		awaitingKeyHolderSignatureDWallet as ZeroTrustDWallet,
		dkgSecondRoundRequestInput.userPublicOutput,
		secondRoundMoveResponse,
		keypairs.userShareEncryptionKeys,
	);

	const activeDWallet = await ikaClient.getDWalletInParticularState(
		dwalletID as string,
		"Active",
	);

	const encryptedUserSecretKeyShare = await ikaClient.getEncryptedUserSecretKeyShare(
		secondRoundMoveResponse.event_data.encrypted_user_secret_key_share_id,
	);

	const { secretShare } = await keypairs.userShareEncryptionKeys.decryptUserShare(
		activeDWallet,
		encryptedUserSecretKeyShare,
		await ikaClient.getProtocolPublicParameters(activeDWallet),
	);

	await makeDWalletUserSecretKeySharesPublic(
		ikaClient,
		suiClient,
		activeDWallet as ZeroTrustDWallet,
		secretShare,
	);

	console.log("Share dwallet id", dwalletID);
}
