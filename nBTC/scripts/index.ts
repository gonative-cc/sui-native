import { Command } from "commander";
import { createIkaClient, createShareDwallet, createSuiClient, loadConfig } from "./common";
import { sendBTCTx } from "./btc-helper";
import {
	globalPreSign,
	getSigHash,
	createUserSigCap,
	request_signature_for_input,
	verifySignature,
	getRawTx,
} from "./sign";
import { initialization } from "./initialization";

const config = loadConfig();

let suiClient = createSuiClient();
let ikaClient = createIkaClient(suiClient);
await ikaClient.initialize();

const program = new Command();
program
	.command("init_dwallet")
	.description("Creates a shared Dwallet and adds it to the nNBTC object")
	.action(async () => {
		let dwallet = await createShareDwallet(ikaClient, suiClient);
		await initialization(dwallet.id.id, config);
	});

program
	.command("request_signature <redeem_id> <input_idx>")
	.description("Requests a signature for a specific input_idx of the given redeem transaction (redeem_id)")
	.action(async (redeem_id: number, input_idx: number) => {
		let gPreSign = await globalPreSign();
		let message = await getSigHash(suiClient, redeem_id, input_idx, config);
		let dwalletID = loadConfig().dwalletId;
		let userSigCap = await createUserSigCap(ikaClient, suiClient, dwalletID, gPreSign, message);
		let sigID = await request_signature_for_input(
			redeem_id,
			input_idx,
			userSigCap.cap_id,
			config,
		);
		console.log(signID);
	});

program
	.command("verify <redeem_id> <input_idx> <sign_id>")
	.description("Verify the signature for specify input_idx on redeem request tx with the sign_id")
	.action(async (redeem_id: number, input_idx: number, sign_id: string) => {
		await verifySignature(suiClient, redeem_id, input_idx, sign_id, config);
	});

program
	.command("raw_tx <redeem_id>")
	.description("Get a raw redeem transaction")
	.action(async (redeem_id: number) => {
		let rawTx = await getRawTx(suiClient, redeem_id, config);
		await sendBTCTx(data);
	});

program.parse(process.argv);
