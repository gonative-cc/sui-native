import { Command } from "commander";
import { createShareDwallet } from "./common";
import { getBTCAddress, redeemTx, sendBTCTx } from "./btc-helper";
import { globalPreSign, completeFetureRequest, sign_message } from "./sign";

const program = new Command();

program
	.command("new-share-dwallet")
	.description("Create share Dwallet")
	.action(async () => {
		let dwallet = await createShareDwallet();
		let gPreSign = await globalPreSign()
		let message = new TextEncoder().encode('test message');
		let pratialSign = await sign_message(dwallet, gPreSign, message)
		await completeFetureRequest(dwallet, message, pratialSign.cap_id);
	});
program.parse(process.argv);
