import { describe, test, expect, beforeAll } from "bun:test";
import { SuiClient } from "@mysten/sui/client";
import { Transaction } from "@mysten/sui/transactions";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import * as bitcoin from "bitcoinjs-lib";
import { readDeployInformation } from "../scripts/config";
import {
	createSuiClient,
	createIkaClient,
	mkSigner,
	delay,
	executeTransaction,
} from "../nBTC/scripts/common";
import { SpvHelper } from "./spv_helper";
import {
	globalPreSign,
	createUserSigMessage,
	getSignHash,
	requestUtxoSig,
	verifySignature,
	getRedeemBtcTx,
} from "../nBTC/scripts/sign";
import { broadcastBtcTx } from "../nBTC/scripts/btc-helper";
import { BitcoinCli } from "./btc-cli";
import { nBTCContractModule, StorageModule } from "../sdk/nBTC/src";
import * as NbtcUtxo from "../sdk/nBTC/generated/nbtc/nbtc_utxo";
import { bcs } from "@mysten/sui/bcs";
import { mintNbtc, getTxInfo } from "../scripts/mint";
import { getTxHex } from "../scripts/indexer";
import { sleep } from "bun";

let suiClient: SuiClient;
let ikaClient: any;
let signer: Ed25519Keypair;
let spv: SpvHelper;
let btc: BitcoinCli;
let config: any;
let deployInfo: any;

const REDEEM_DURATION_MS = 120000;

beforeAll(async () => {
	deployInfo = readDeployInformation();

	config = {
		nbtc: deployInfo.nbtc_contract,
		dwalletId: deployInfo.dwallet_id,
		adminCap: deployInfo.nbtc_admin_cap,
		packageId: deployInfo.nbtc_pkg,
		nbtcPkg: deployInfo.nbtc_pkg,
		lcContract: deployInfo.lc_contract,
		btcAddress: deployInfo.btc_address,
		bitcoinLibPkg: deployInfo.bitcoin_lib_pkg,
		lcPkg: deployInfo.lc_pkg,
	};

	console.log(config.nbtc);
	suiClient = createSuiClient(config.packageId);
	signer = mkSigner();

	ikaClient = createIkaClient(suiClient);
	await ikaClient.initialize();

	btc = new BitcoinCli();

	if (!btc.checkContainer()) {
		throw new Error(
			"esplora-regtest container not running. Run: docker-compose -f bitcoin-regtest/docker-compose.yml up -d",
		);
	}

	btc.loadwallet("default");

	spv = await SpvHelper.fromDeployInfo(suiClient, signer);
});

test("mint nBTC", async () => {
	const btcDepositAmount = 0.0001 * 100000000;

	const { spawnSync } = await import("node:child_process");
	const depositResult = spawnSync(
		"./scripts/btc-deposit.sh",
		[btcDepositAmount.toString(), signer.toSuiAddress()],
		{ encoding: "utf-8", shell: true },
	);

	if (depositResult.status !== 0) {
		throw new Error(`btc-deposit.sh failed: ${depositResult.stderr}`);
	}

	const output = depositResult.stdout;
	const depositTxid = output.match(/TXID: (\w+)/)?.[1];
	console.log(depositTxid);
	// sleep 5 second for indexer
	await sleep(5000);
	if (!depositTxid) {
		throw new Error("Failed to parse deposit TXID");
	}

	const txInfo = await getTxInfo(depositTxid);
	const txHex = await getTxHex(depositTxid);

	await mintNbtc(
		{
			nbtcPkg: config.packageId,
			nbtcContract: config.nbtc,
			lcContract: config.lcContract,
			bitcoinLibPkg: config.bitcoinLibPkg,
			spvPkg: config.lcPkg,
			btcTxHex: txHex,
			height: txInfo.height,
			txIndex: txInfo.txIndex,
			btcAddress: deployInfo.btc_address,
			applyFee: false,
		},
		signer,
	);
}, 0);

test("redeem nBTC to BTC withdrawal", async () => {
	const fee = 150;
	const recipientScript = Buffer.from(
		"76a914509a651dd392e1bc125323f629b67d65cca3d4bb88ac",
		"hex",
	);

	const coinId = await getNbtcCoin();

	const createRedeemTx = new Transaction();
	const coin = createRedeemTx.object(coinId);

	createRedeemTx.add(
		nBTCContractModule.redeem({
			arguments: {
				contract: config.nbtc,
				coin,
				recipientScript: Array.from(recipientScript),
				fee: BigInt(fee),
			},
		}),
	);

	const createRedeemResult = await executeTransaction(suiClient, createRedeemTx);
	await suiClient.waitForTransaction({ digest: createRedeemResult.digest });

	const event = createRedeemResult.events?.find((e) => e.type.includes("RedeemRequestEvent"));
	if (!event) {
		throw new Error("RedeemRequestEvent not found");
	}

	const parsed = event.parsedJson as any;
	const redeemId = parsed.redeem_id;

	const utxoIndex = await getNextUtxoIndex();

	const proposeUtxosTx = new Transaction();
	proposeUtxosTx.add(
		nBTCContractModule.proposeUtxos({
			arguments: {
				contract: config.nbtc,
				redeemId: BigInt(redeemId),
				utxoIds: [BigInt(utxoIndex)],
			},
		}),
	);

	const proposeResult = await executeTransaction(suiClient, proposeUtxosTx);
	await suiClient.waitForTransaction({ digest: proposeResult.digest });

	await delay(REDEEM_DURATION_MS + 2000);

	const solveTx = new Transaction();
	solveTx.add(
		nBTCContractModule.solveRedeemRequest({
			arguments: {
				contract: config.nbtc,
				redeemId: BigInt(redeemId),
			},
		}),
	);
	const solveResult = await executeTransaction(suiClient, solveTx);
	await suiClient.waitForTransaction({ digest: solveResult.digest });

	const recordResult = await requestAndRecordSignature(redeemId, 0);
	await suiClient.waitForTransaction({ digest: recordResult.digest });
	const withdrawReadyEvent = recordResult.events?.find((e: any) =>
		e.type.includes("RedeemWithdrawReadyEvent"),
	);
	if (!withdrawReadyEvent) {
		throw new Error("RedeemWithdrawReadyEvent not found");
	}

	const parsedEvent = withdrawReadyEvent.parsedJson as any;
	const btcTxRaw = Buffer.from(parsedEvent.tx_raw);
	const btcTxId = Buffer.from(parsedEvent.tx_id).reverse().toString("hex");

	const btcTxHex = btcTxRaw.toString("hex");
	await broadcastBtcTx(btcTxHex);

	const btcTx = bitcoin.Transaction.fromHex(btcTxHex);
	const redeemTxid = btcTx.getId();

	btc.mineBlocks(6);

	const redeemSpvProof = await spv.generateSpvProof(redeemTxid);

	const finalizeTx = new Transaction();
	finalizeTx.add(
		nBTCContractModule.finalizeRedeem({
			arguments: {
				contract: config.nbtc,
				lightClient: config.lcContract,
				redeemId: BigInt(redeemId),
				proof: redeemSpvProof.proof.map((p) => Array.from(Buffer.from(p, "hex"))),
				height: BigInt(redeemSpvProof.height),
				txIndex: BigInt(redeemSpvProof.txIndex),
			},
		}),
	);

	const finalizeResult = await executeTransaction(suiClient, finalizeTx);
	await suiClient.waitForTransaction({ digest: finalizeResult.digest });

	const burnEvent = finalizeResult.events?.find((e) => e.type.includes("BurnEvent"));
	if (!burnEvent) {
		throw new Error("BurnEvent not found");
	}
}, 0);

async function getNextUtxoIndex(): Promise<number> {
	const contractObj = await suiClient.getObject({
		id: config.nbtc,
		options: { showContent: true },
	});

	if (!contractObj.data?.content) {
		throw new Error("Failed to get contract content");
	}

	const content = contractObj.data.content as any;
	const storage = content.fields.storage;

	if (storage.fields && storage.fields.utxo_store) {
		const utxoStore = storage.fields.utxo_store;
		return Number(utxoStore.fields.next_utxo) - 1;
	}

	if (storage.fields && storage.fields.id) {
		const storageId = storage.fields.id.id;
		const storageObj = await suiClient.getObject({
			id: storageId,
			options: { showContent: true },
		});

		if (!storageObj.data?.content) {
			throw new Error("Failed to get storage content");
		}

		const storageContent = storageObj.data.content as any;
		const utxoStore = storageContent.fields.utxo_store;

		return Number(utxoStore.fields.next_utxo) - 1;
	}

	throw new Error("Could not find utxo_store");
}

async function getNbtcCoin(): Promise<string> {
	const coins = await suiClient.getCoins({
		owner: signer.toSuiAddress(),
		coinType: `${config.packageId}::nbtc::NBTC`,
	});

	if (coins.data.length === 0) {
		throw new Error("No nBTC coins found");
	}

	const firstCoin = coins.data[0];
	const coinId = firstCoin?.coinObjectId;
	if (!coinId) {
		throw new Error("Coin ID not found");
	}

	return coinId;
}

async function requestAndRecordSignature(redeemId: number, inputId: number): Promise<any> {
	const sighash = await getSignHash(suiClient, redeemId, inputId, config);

	const presignId = await globalPreSign();

	const msgCentralSig = await createUserSigMessage(
		ikaClient,
		config.dwalletId,
		presignId,
		sighash,
	);

	const signId = await requestUtxoSig(
		suiClient,
		ikaClient,
		redeemId,
		inputId,
		presignId,
		msgCentralSig,
		config,
	);

	await delay(35000);

	return await verifySignature(suiClient, redeemId, inputId, signId, config);
}
