module nbtc::verify_payment;


use bitcoin_spv::light_client::LightClient;
use btc_parser::tx::Transaction;

#[error]
const ETxNotInBlock: vector<u8> =
    b"The transaction is not included in a finalized block according to the Merkle proof";

/// Verifies the transaction and parses outputs to calculates the payment to the receiver.
/// To if you only want to verify if the tx is included in the block, you can use
/// `verify_tx` function.
/// Returns the the total amount of satoshi send to `receiver_address` from transaction outputs,
/// the content of the `OP_RETURN` opcode output, and tx_id (hash).
/// If OP_RETURN is not included in the transaction, return an empty vector.
/// NOTE: output with OP_RETURN is invalid, and only one such output can be included in a TX.
/// * `height`: block height the transaction belongs to.
/// * `proof`: merkle tree proof, this is the vector of 32bytes.
/// * `tx_index`: index of transaction in block.
/// * `transaction`: bitcoin transaction. Check transaction.move.
/// * `receiver_pk_hash`: receiver public key hash in p2pkh or p2wpkh. Must not empty
public fun verify_payment(
    lc: &LightClient,
    height: u64,
    proof: vector<vector<u8>>,
    tx_index: u64,
    transaction: &Transaction,
    receiver_pk_hash: vector<u8>,
): (u64, vector<u8>, vector<u8>) {

    let mut amount = 0;
    let mut op_return_msg = vector[];
    let tx_id = transaction.tx_id();

    assert!(lc.verify_tx(height, tx_id, proof, tx_index), ETxNotInBlock);
    let outputs = transaction.outputs();
    outputs.do!(|o| {
        if (o.extract_public_key_hash() == receiver_pk_hash) {
            amount = amount + o.amount();
        };

        if (o.is_op_return()) {
            op_return_msg = o.op_return();
        };
    });

    (amount, op_return_msg, tx_id)
}
