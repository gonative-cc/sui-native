import { describe, test, expect, beforeAll } from "bun:test";
import { SuiClient } from "@mysten/sui/client";
import { Transaction } from "@mysten/sui/transactions";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import * as bitcoin from "bitcoinjs-lib";
import { readDeployInformation } from "../../scripts/config";
import {
	createSuiClient,
	createIkaClient,
	mkSigner,
	delay,
} from "../scripts/common";
import { SpvHelper } from "./spv_helper";
import {
	globalPreSign,
	createUserSigMessage,
	getSignHash,
	requestUtxoSig,
	verifySignature,
	getRedeemBtcTx,
} from "../scripts/sign";
import { broadcastBtcTx } from "../scripts/btc-helper";
import { BitcoinCli } from "./btc-cli";
import { nBTCContractModule, RedeemRequestModule } from "../../sdk/nBTC/src";
import { mintNbtc, getTxInfo } from "../../scripts/mint";
import { getTxHex } from "../../scripts/indexer";

let suiClient: SuiClient;
let ikaClient: any;
let signer: Ed25519Keypair;
let spv: SpvHelper;
let btc: BitcoinCli;
let config: any;
let deployInfo: any;

const REDEEM_DURATION_MS = 120000;

beforeAll(async () => {
	suiClient = createSuiClient();
	signer = mkSigner();

	ikaClient = createIkaClient(suiClient);
	await ikaClient.initialize();

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

	btc = new BitcoinCli();

	if (!btc.checkContainer()) {
		throw new Error(
			"esplora-regtest container not running. Run: docker-compose -f bitcoin-regtest/docker-compose.yml up -d",
		);
	}

	btc.loadwallet("default");

	spv = await SpvHelper.fromDeployInfo(suiClient, signer);
	await spv.syncToLatest();
});

test("mint nBTC from BTC deposit", async () => {
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

	if (!depositTxid) {
		throw new Error("Failed to parse deposit TXID");
	}

	const txInfo = await getTxInfo(depositTxid);
	const txHex = await getTxHex(depositTxid);

	await mintNbtc({
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
	}, signer);

	await getNbtcBalance(signer.toSuiAddress());
}, 300000);

test("redeem nBTC to BTC withdrawal", async () => {
	const btcDepositAmount = 0.0001 * 100000000;
	const redeemAmount = 50000;
	const fee = 1000;

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

	if (!depositTxid) {
		throw new Error("Failed to parse deposit TXID");
	}

	const txInfo = await getTxInfo(depositTxid);
	const txHex = await getTxHex(depositTxid);

	const mintResult = await mintNbtc({
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
	}, signer);

	const nbtcBalanceBefore = await getNbtcBalance(signer.toSuiAddress());

	const recipientScript = Buffer.from(
		"76a914509a651dd392e1bc125323f629b67d65cca3d4bb88ac",
		"hex",
	);

	const redeemId = await createRedeemRequest(recipientScript, fee);

	await getRedeemRequest(redeemId);

	await proposeUtxos(redeemId, [mintResult.utxoIdx]);

	await getRedeemRequest(redeemId);

	await delay(REDEEM_DURATION_MS + 2000);

	await solveRedeemRequest(redeemId);

	await getRedeemRequest(redeemId);

	await requestAndRecordSignature(redeemId, 0);

	await getRedeemRequest(redeemId);

	const btcTxHex = await getRedeemBtcTx(suiClient, redeemId, config);

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

	const finalizeResult = await suiClient.signAndExecuteTransaction({
		transaction: finalizeTx,
		signer,
		options: { showEvents: true },
	});

	const burnEvent = finalizeResult.events?.find((e) => e.type.includes("BurnEvent"));
	if (!burnEvent) {
		throw new Error("BurnEvent not found");
	}

	const parsedBurn = burnEvent.parsedJson as any;

	await getNbtcBalance(signer.toSuiAddress());
}, 600000);

async function getNbtcBalance(address: string): Promise<bigint> {
	const coins = await suiClient.getCoins({
		owner: address,
		coinType: `${config.packageId}::nbtc::NBTC`,
	});

	let total = BigInt(0);
	for (const coin of coins.data) {
		total += BigInt(coin.balance);
	}
	return total;
}

async function createRedeemRequest(
	recipientScript: Uint8Array,
	fee: number,
): Promise<number> {
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

	const tx = new Transaction();
	const coin = tx.object(coinId);

	tx.transferObjects([coin], tx.pure.address(config.nbtc));

	tx.add(
		nBTCContractModule.redeem({
			arguments: {
				contract: config.nbtc,
				coin,
				recipientScript: Array.from(recipientScript),
				fee: BigInt(fee),
			},
		}),
	);

	const result = await suiClient.signAndExecuteTransaction({
		transaction: tx,
		signer,
		options: { showEvents: true },
	});

	const event = result.events?.find((e) => e.type.includes("RedeemRequestEvent"));
	if (!event) {
		throw new Error("RedeemRequestEvent not found");
	}

	const parsed = event.parsedJson as any;
	return parsed.redeem_id;
}

async function proposeUtxos(redeemId: number, utxoIds: number[]): Promise<void> {
	const tx = new Transaction();
	tx.add(
		nBTCContractModule.proposeUtxos({
			arguments: {
				contract: config.nbtc,
				redeemId: BigInt(redeemId),
				utxoIds: utxoIds.map((id) => BigInt(id)),
			},
		}),
	);

	await suiClient.signAndExecuteTransaction({
		transaction: tx,
		signer,
	});
}

async function solveRedeemRequest(redeemId: number): Promise<void> {
	const tx = new Transaction();
	tx.add(
		nBTCContractModule.solveRedeemRequest({
			arguments: {
				contract: config.nbtc,
				redeemId: BigInt(redeemId),
			},
		}),
	);

	await suiClient.signAndExecuteTransaction({
		transaction: tx,
		signer,
	});
}

async function requestAndRecordSignature(
	redeemId: number,
	inputId: number,
): Promise<void> {
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

	await verifySignature(suiClient, redeemId, inputId, signId, config);
}

async function getRedeemRequest(redeemId: number): Promise<any> {
	const tx = new Transaction();
	const redeem = tx.add(
		nBTCContractModule.redeemRequest({
			arguments: {
				contract: config.nbtc,
				redeemId: BigInt(redeemId),
			},
		}),
	);

	const result = await suiClient.devInspectTransactionBlock({
		transactionBlock: tx,
		sender: signer.toSuiAddress(),
	});

	const encoded = result.results![0]?.returnValues![0]![0]!;
	if (!encoded) {
		throw new Error("Failed to get redeem request data");
	}
	return RedeemRequestModule.RedeemRequest.parse(Uint8Array.from(encoded));
}
