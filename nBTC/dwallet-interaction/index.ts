import { Command } from 'commander'
import { createShareDwallet } from './common';
import { getBTCAddress, redeemTx, sendBTCTx } from './btc-helper';


const program = new Command();

program.command("new-share-dwallet").description("Create share Dwallet").action(async () => {
	createShareDwallet().then(() => console.log("Create dwallet successfully")).catch(console.log)
})

program.command("send").description("Send btc from BTC dwallet to other address")
	.argument("dwalletID", "DWalletID")
	.argument("receiver", "Receiver Address")
	.argument("amount", "Amount in sats")
	.action(async (dwalletID, receiver, amount) => {
		let raw_tx = await redeemTx(dwalletID, receiver, parseInt(amount));
		console.log("Raw Transaction = ", raw_tx)
		await sendBTCTx(raw_tx);
	})

program.command("btc_addr").argument("dwalletID").description("Get BTC address of Dwallet").action(async (dWalletID) => {
	console.log(await getBTCAddress(dWalletID))
})
program.parse(process.argv)
