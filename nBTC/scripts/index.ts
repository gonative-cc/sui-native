import { Command } from "commander";
import {
	createIkaClient,
	createSharedDwallet,
	createSuiClient,
	loadConfig,
	type Config,
} from "./common";
import {
	globalPreSign,
	getSigHash,
	createUserSigMessage,
	requestSignatureForInput,
	verifySignature,
	getRedeemBtcTx,
} from "./sign";
import { initialization } from "./initialization";
import { broadcastBtcTx } from "./btc-helper";

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
		console.log(`Successfully created and initialized Dwallet with ID: ${dwallet.id.id}`);
	});

program
	.command("request_signature <redeem_id> <input_idx>")
	.description(
		"Requests a signature for a specific input_idx of the given redeem transaction (redeem_id)",
	)
	.action(async (redeem_id: number, input_idx: number) => {
		let presignId = await globalPreSign();
		let sigHash = await getSigHash(suiClient, redeem_id, input_idx, config);
		let dwalletID = loadConfig().dwalletId;

		// Create nbtc_public_signature using the new approach
		let nbtcPublicSignature = await createUserSigMessage(
			ikaClient,
			dwalletID,
			presignId,
			sigHash,
		);

		// we use signID to query the signature after ika response
		let signID = await requestSignatureForInput(
			redeem_id,
			input_idx,
			presignId,
			nbtcPublicSignature,
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
	.command("raw_redeem_tx <redeem_id>")
	.description("Get a raw redeem transaction and broadcast it")
	.action(async (redeem_id: number) => {
		let rawTx = await getRedeemBtcTx(suiClient, redeem_id, config);
		console.log("Raw redeem tx = ", rawTx);
		await broadcastBtcTx(rawTx);
	});
program.parse(process.argv);
