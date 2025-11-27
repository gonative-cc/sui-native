import { Command } from "commander";
import { createIkaClient, createShareDwallet, createSuiClient, loadConfig } from "./common";
import { sendBTCTx } from "./btc-helper";
import { globalPreSign, completeFetureRequest, sign_message, getSigHash, createUserSigCap, request_signature_for_input, verifySignature, getRawTx } from "./sign";
import { initialization, mint_nbtc_for_testing } from "./initialization";

const config = loadConfig();

let suiClient = createSuiClient();
let ikaClient = createIkaClient(suiClient);
await ikaClient.initialize();

const program = new Command();
program
	.command("new-share-dwallet")
	.description("Create share Dwallet")
	.action(async () => {
		let dwallet = await createShareDwallet(ikaClient, suiClient);
		await initialization(dwallet.id.id, config);
	});

program
	.command("init-token")
	.description("Init token")
	.action(async () => {
		await mint_nbtc_for_testing(ikaClient, suiClient, config.dwalletId, config);
	});
program
	.command("request_signature <redeem_id> <input_idx>")
	.description("Request a signature for specify input_idx for redeem transaction have redeem_id")
	.action(async (redeem_id, input_idx) => {
		let gPreSign = await globalPreSign()
		let message = await getSigHash(suiClient, redeem_id, input_idx, config);
		let dwalletID = loadConfig().dwalletId
		let userSigCap = await createUserSigCap(ikaClient, suiClient, dwalletID, gPreSign, message)
		await request_signature_for_input(redeem_id, input_idx, userSigCap.cap_id, config);
	});

program
	.command("verify <redeem_id> <input_idx> <sign_id>")
	.description("Verify the signature for specify input_idx on redeem request tx with the sign_id")
	.action(async (redeem_id, input_idx, sign_id) => {
		await verifySignature(suiClient, redeem_id, input_idx, sign_id, config)
	});

program
	.command("raw_tx <redeem_id>")
	.description("Get a raw redeem transaction")
	.action(async (redeem_id) => {
		let data = await getRawTx(suiClient, redeem_id, config);
		await sendBTCTx(data)
	});




program.parse(process.argv);
