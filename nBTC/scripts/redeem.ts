import { Transaction } from "@mysten/sui/transactions";
import { createIkaClient, createSuiClient, executeTransaction } from "./common";
import { loadConfig } from "./initialization";
import { fromHex } from "@mysten/sui/utils";

export async function redeem(coinId: string) {
  const suiClient = createSuiClient();
  let config = loadConfig();

  let tx = new Transaction();

  tx.moveCall({
    target: `${config.packageId}::nbtc::redeem`,
    arguments: [
      tx.object(config.nbtc),
      tx.object(coinId),
      tx.pure.vector(
        "u8",
        fromHex("0x00147c619b661b6511972466e25a13a3177dd048204a"),
      ),
      tx.object.clock(),
    ],
  });

  tx.moveCall({
    target: `${config.packageId}::nbtc::propose_utxos`,
    arguments: [
      tx.object(config.nbtc),
      tx.pure.u64(1),
      tx.pure.vector("u64", [0]),
      tx.pure.vector("id", [config.dwalletId]),
      tx.object.clock(),
    ],
  });
  await executeTransaction(suiClient, tx);
}
