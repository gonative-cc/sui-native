import { Command } from "commander";
import { createIkaClient, createSharedDwallet, createSuiClient, loadConfig } from "./common";
import { broadcastBtcTx } from "./btc-helper";
import {
	globalPreSign,
	getSigHash,
	createUserSigCap,
	request_signature_for_input,
	verifySignature,
	getRedeemBtcTx,
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
		let dwallet = await createSharedDwallet(ikaClient, suiClient);
		await initialization(dwallet.id.id, config);
	});

program
	.command("request_signature <redeem_id> <input_idx>")
	.description(
		"Requests a signature for a specific input_idx of the given redeem transaction (redeem_id)",
	)
	.action(async (redeem_id: number, input_idx: number) => {
		let gPreSign = await globalPreSign();
		let message = await getSigHash(suiClient, redeem_id, input_idx, config);
		let dwalletID = loadConfig().dwalletId;
		let userSigCap = await createUserSigCap(ikaClient, suiClient, dwalletID, gPreSign, message);
		// we use signID to query the signature after ika response
		let signID = await request_signature_for_input(
			redeem_id,
			input_idx,
			userSigCap.cap_id,
			config,
		);
		console.log("Ika sign id =", signID);
	});

program
	.command("verify_sign <redeem_id> <input_idx> <sign_id>")
	.description("Verify the signature we created to spend input_idx in redeem request transaction")
	.action(async (redeem_id: number, input_idx: number, sign_id: string) => {
		await verifySignature(suiClient, redeem_id, input_idx, sign_id, config);
	});

program
	.command("raw_tx <redeem_id>")
	.description("Get a raw redeem transaction")
	.action(async (redeem_id: number) => {
		let rawTx = await getRedeemBtcTx(suiClient, redeem_id, config);
		await broadcastBtcTx(rawTx);
	});

program.parse(process.argv);
