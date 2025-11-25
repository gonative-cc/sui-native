import { Command } from "commander";
import { createShareDwallet } from "./common";
import { getBTCAddress, redeemTx, sendBTCTx } from "./btc-helper";
import { globalPreSign, completeFetureRequest, sign_message } from "./sign";
import { initialization } from "./initialization";

const program = new Command();

program
	.command("new-share-dwallet")
	.description("Create share Dwallet")
	.action(async () => {
		// let dwallet = await createShareDwallet();
		await initialization("0xcf74ba537d77d67a2d14db0c15d47c767cbd5429b9208ab9542635e7db367bc9");

		// let gPreSign = await globalPreSign()
		// let message = new TextEncoder().encode('test message');
		// let pratialSign = await sign_message(dwallet, gPreSign, message)
		// await completeFetureRequest(dwallet, message, pratialSign.cap_id);
	});
program.parse(process.argv);
