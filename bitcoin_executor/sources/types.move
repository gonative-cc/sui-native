module bitcoin_executor::types;

// /// Inputs in btc transaction
// public struct Input has copy, drop {
//     /// Reference to the output being spent.
//     tx_id: vector<u8>,
//     vout: u32,
//     /// https://learnmeabitcoin.com/technical/transaction/input/scriptsig/
//     script_sig: vector<u8>,
//     /// tx version
//     sequence: u32,
// }

// public struct Output has copy, drop {
//     /// in satoshi
//     value: u64,
//     /// script that locks the output (scriptPubKey)
//     /// https://learnmeabitcoin.com/technical/script/
//     script_pub_key: vector<u8>,
// }

// /// BTC transaction
// public struct Transaction has copy, drop {
//     version: u32,
//     inputs: vector<Input>,
//     outputs: vector<Output>,
//     lock_time: u32,
//     witness: vector<u8>,
// }

// public fun new_input(tx_id: vector<u8>, vout: u32, script_sig: vector<u8>, sequence: u32): Input {
//     Input {
//         tx_id,
//         vout,
//         script_sig,
//         sequence,
//     }
// }

// public fun new_output(value: u64, script_pub_key: vector<u8>): Output {
//     Output {
//         value,
//         script_pub_key,
//     }
// }

// public fun new_tx(
//     version: u32,
//     inputs: vector<Input>,
//     outputs: vector<Output>,
//     lock_time: u32,
//     witness: vector<u8>,
// ): Tx {
//     Tx {
//         version,
//         inputs,
//         outputs,
//         lock_time,
//         witness,
//     }
// }

// // Getters for Input struct
// public fun tx_id(input: &Input): &vector<u8> {
//     &input.tx_id
// }

// public fun vout(input: &Input): u32 {
//     input.vout
// }

// public fun script_sig(input: &Input): &vector<u8> {
//     &input.script_sig
// }

// public fun sequence(input: &Input): u32 {
//     input.sequence
// }

// // Getters for Output struct
// public fun value(output: &Output): u64 {
//     output.value
// }

// public fun script_pub_key(output: &Output): &vector<u8> {
//     &output.script_pub_key
// }

// // Getters for Tx struct
// public fun version(tx: &Tx): u32 {
//     tx.version
// }

// public fun inputs(tx: &Tx): &vector<Input> {
//     &tx.inputs
// }

// public fun outputs(tx: &Tx): &vector<Output> {
//     &tx.outputs
// }

// public fun lock_time(tx: &Tx): u32 {
//     tx.lock_time
// }

// public fun witness(tx: &Tx): &vector<u8> {
//     &tx.witness
// }
