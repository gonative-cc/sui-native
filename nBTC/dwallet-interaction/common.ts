import { bcs, fromBase64, toHex } from "@mysten/bcs";
import { getFullnodeUrl, SuiClient } from "@mysten/sui/client";
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
	publicKeyFromDWalletOutput,
	type IkaConfig,
	type DWallet,
	type DWalletCap,
	type ZeroTrustDWallet,
	createRandomSessionIdentifier,
	prepareDKGAsync,
} from "@ika.xyz/sdk";
import { Transaction, type TransactionObjectArgument } from "@mysten/sui/transactions";
import "dotenv/config";

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
		url: getFullnodeUrl('testnet'),
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


export async function getIkaCoin(suiClient: SuiClient, addr: string): Promise<string | undefined> {
	const coins = (await suiClient.getCoins({ owner: addr, coinType: "0x1f26bb2f711ff82dcda4d02c77d5123089cb7f8418751474b9fb744ce031526a::ika::IKA", limit: 2 }));
	return coins.data[0]?.coinObjectId;
}

export async function createShareDwallet() {
	const suiClient = createSuiClient();
	const ikaClient = createIkaClient(suiClient);
	await ikaClient.initialize();

	const curve = Curve.SECP256K1;
	const keypairs = await generateKeypair();
	const signer = mkSigner();
	const transaction = new Transaction();
	const ikaTransaction = new IkaTransaction({
		ikaClient,
		transaction,
		userShareEncryptionKeys: keypairs.userShareEncryptionKeys
	})
	const identifier = createRandomSessionIdentifier();

	const dkgRequestInput = await prepareDKGAsync(
		ikaClient,
		curve,
		keypairs.userShareEncryptionKeys,
		identifier,
		signer.toSuiAddress(),
	);
	//

	const dWalletEncryptionKey = await ikaClient.getLatestNetworkEncryptionKey();
	const ikaCoin = await getIkaCoin(suiClient, signer.toSuiAddress());
	const [dWalletCap] = await ikaTransaction.requestDWalletDKGWithPublicUserShare({
		publicKeyShareAndProof: dkgRequestInput.userDKGMessage,
		publicUserSecretKeyShare: dkgRequestInput.userSecretKeyShare, // <-- Public, not encrypted
		userPublicOutput: dkgRequestInput.userPublicOutput,
		curve,
		dwalletNetworkEncryptionKeyId: dWalletEncryptionKey.id,
		ikaCoin: transaction.object(ikaCoin as string),
		suiCoin: transaction.gas,
		sessionIdentifier: ikaTransaction.registerSessionIdentifier(identifier),
	});

	if (dWalletCap != undefined) {
		transaction.transferObjects([dWalletCap], signer.toSuiAddress());
	}

	let result = await executeTransaction(suiClient, transaction);

	const event = result.events?.find((event) => {
		return (
			event.type.includes("DWalletDKGRequestEvent")
		);
	});
	let eventDecoded = SessionsManagerModule.DWalletSessionEvent(
		CoordinatorInnerModule.DWalletDKGRequestEvent,
	).fromBase64(event?.bcs as string);

	let dWalletID = eventDecoded.event_data.dwallet_id;

	const activeDWallet = await ikaClient.getDWalletInParticularState(dWalletID, 'Active', {
		timeout: 30000,
		interval: 1000,
	});
	console.log("New dwallet id = ", dWalletID);
	return activeDWallet
}
