import { describe, test, expect, beforeAll } from "bun:test";
import { SuiClient, getFullnodeUrl } from "@mysten/sui/client";
import { readDeployInformation } from "../../scripts/config";
import { mkSigner } from "../scripts/common";
import { SpvHelper } from "./spv_helper";

const BTC_AMOUNT_SATOSHIS = 0.01 * 100000000;
const REDEEM_AMOUNT_SATOSHIS = 0.005 * 100000000;
const FEE_SATOSHIS = 1000;

let suiClient: SuiClient;
let signer: ReturnType<typeof mkSigner>;
let spv: SpvHelper;
let nbtcContract: string;
let dwalletBtcAddress: string;

beforeAll(async () => {
	suiClient = new SuiClient({ url: getFullnodeUrl("testnet") });
	signer = mkSigner();
	const deployInfo = readDeployInformation();
	console.log(deployInfo);
	// if (!deployInfo.nbtc_contract || !deployInfo.btc_address) {
	// 	throw new Error("Missing deployment info. Run deploy-nbtc.ts first.");
	// }
	//
	// nbtcContract = deployInfo.nbtc_contract;
	// dwalletBtcAddress = deployInfo.btc_address;
	spv = await SpvHelper.fromDeployInfo(suiClient, signer);

	console.log("✅ E2E Test Setup:");
	console.log(`   Sui Network: testnet`);
	// console.log(`   nBTC Contract: ${nbtcContract}`);
	// console.log(`   BTC Deposit Address: ${dwalletBtcAddress}`);
});

test.only("sync light client to latest", async () => {
	console.log("\n🔄 Step 1: Sync light client to latest");

	const tipHeight = await spv.syncToLatest();

	console.log(`   Tip Height: ${tipHeight}`);

	expect(tipHeight).toBeGreaterThan(0);
}, 0);

test("generate SPV proof for mint transaction", async () => {
	console.log("\n🪙 Step 2: Generate SPV proof for mint");

	const txId = "YOUR_TX_ID_HERE";

	const proof = await spv.generateSpvProof(txId);

	console.log("   SPV Proof Generated:");
	console.log(`     Height: ${proof.height}`);
	console.log(`     Tx Index: ${proof.txIndex}`);
	console.log(`     Proof Length: ${proof.proof.length}`);

	expect(proof.height).toBeGreaterThan(0);
	expect(proof.txIndex).toBeGreaterThanOrEqual(0);
	expect(proof.proof.length).toBeGreaterThan(0);
	expect(proof.txId).toBe(txId);
});

test("generate SPV proof for redeem transaction", async () => {
	console.log("\n💸 Step 3: Generate SPV proof for redeem");

	const redeemTxId = "YOUR_REDEEM_TX_ID";

	const proof = await spv.generateSpvProof(redeemTxId);

	console.log("   Redeem SPV Proof Generated:");
	console.log(`     Height: ${proof.height}`);
	console.log(`     Tx Index: ${proof.txIndex}`);

	expect(proof.height).toBeGreaterThan(0);
	expect(proof.txIndex).toBeGreaterThanOrEqual(0);
});
