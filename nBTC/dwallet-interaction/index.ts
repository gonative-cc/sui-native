import { Command } from "commander";
import { createShareDwallet, loadConfig } from "./common";
import { getBTCAddress, redeemTx, sendBTCTx } from "./btc-helper";
import { globalPreSign, completeFetureRequest, sign_message, getSigHash, createUserSigCap, request_signature_for_input, verifySignature, getRawTx } from "./sign";
import { initialization, mint_nbtc_for_testing } from "./initialization";
const program = new Command();


const config = loadConfig();
program
	.command("new-share-dwallet")
	.description("Create share Dwallet")
	.action(async () => {
		let dwallet = await createShareDwallet();
		await initialization(dwallet.id.id, config);
	});

program
	.command("init-token")
	.description("Init token")
	.action(async () => {
		await mint_nbtc_for_testing(config.dwalletId, config);
	});
program
	.command("redeem")
	.description("redeem")
	.action(async () => {
		let gPreSign = await globalPreSign()
		let message = await getSigHash(19, 0);
		let dwalletID = loadConfig().dwalletId
		let userSigCap = await createUserSigCap(dwalletID, gPreSign, message)
		await request_signature_for_input(19, 0, userSigCap.cap_id);
	});

program
	.command("verify")
	.description("redeem")
	.action(async () => {
		await verifySignature(20, 0, "0x865f8e5efb3f02b4ab4474cb2920a0a59d7745b2d622f1a50a2342308a57865c")
	});

program
	.command("raw_tx")
	.description("raw_tx")
	.action(async () => {
		let data = await getRawTx(20);
		await sendBTCTx(data)
	});

program.parse(process.argv);
