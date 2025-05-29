module bitcoin_executor::tx;

use bitcoin_executor::interpreter::run;
use bitcoin_executor::reader::Reader;
use bitcoin_executor::utils::u64_to_varint_bytes;

/// Input in btc transaction
public struct Input has copy, drop {
    tx_id: vector<u8>,
    vout: vector<u8>,
    script_sig: vector<u8>,
    sequence: vector<u8>
}

/// Output in btc transaction
public struct Output has copy, drop {
    amount: vector<u8>,
    script_pubkey: vector<u8>
}

public struct Witness has copy, drop{
    items: vector<vector<u8>>
}

/// BTC transaction
public struct Transaction has copy, drop {
    version: vector<u8>,
    inputs: vector<Input>,
    marker: Option<u8>,
    flag: Option<u8>,
    outputs: vector<Output>,
    witness: vector<Witness>,
    locktime: vector<u8>,
    tx_id: vector<u8>
}

public fun output_tx_id(input: &Input): vector<u8> {
    input.tx_id
}

public fun vout(input: &Input): vector<u8> {
    input.vout
}

public fun script_sig(input: &Input): vector<u8> {
    input.script_sig
}

public fun sequence(input: &Input): vector<u8> {
    input.sequence
}

public fun amount(output: &Output): vector<u8> {
    output.amount
}

public fun script_pubkey(output: &Output) : vector<u8> {
    output.script_pubkey
}

public fun items(w: &Witness) : vector<vector<u8>> {
    w.items
}

public fun version(tx: &Transaction): vector<u8> {
    tx.version
}

public fun inputs(tx: &Transaction): vector<Input> {
    tx.inputs
}

public fun outputs(tx: &Transaction): vector<Output> {
    tx.outputs
}

public fun witness(tx: &Transaction): vector<Witness> {
    tx.witness
}

public fun locktime(tx: &Transaction): vector<u8> {
    tx.locktime
}

public fun is_witness(tx: &Transaction): bool {
    if (tx.marker.is_none() || tx.flag.is_none()) {
        return false
    };

    let m = tx.marker.borrow();
    let f = tx.flag.borrow();
    m == 0x00 && f == 0x01
}

public fun tx_id(tx: &Transaction): vector<u8> {
    tx.tx_id
}
/// deseriablize transaction from bytes
public fun deserialize(r: &mut Reader) : Transaction {
    let mut raw_tx = vector[];
    let version = r.read(4);
    raw_tx.append(version);

    let segwit = r.peek(2);
    let mut marker = option::none();
    let mut flag = option::none();
    if (segwit[0] == 0x00 && segwit[1] == 0x01) {
    // TODO: Handle case marker and option is none
        marker = option::some(r.read_byte());
        flag = option::some(r.read_byte());
    };
    let number_inputs = r.read_compact_size();
    raw_tx.append(u64_to_varint_bytes(number_inputs));

    let mut inputs = vector[];
    number_inputs.do!(|_| {
        let tx_id = r.read(32);
        raw_tx.append(tx_id);
        let vout = r.read(4);
        raw_tx.append(vout);
        let script_sig_size = r.read_compact_size();
        raw_tx.append(u64_to_varint_bytes(script_sig_size));
        let script_sig = r.read(script_sig_size);
        raw_tx.append(script_sig);
        let sequence = r.read(4);
        raw_tx.append(sequence);

        inputs.push_back(Input {
            tx_id,
            vout,
            script_sig,
            sequence
        });
    });

    let number_outputs = r.read_compact_size();
    raw_tx.append(u64_to_varint_bytes(number_outputs));
    let mut outputs = vector[];
    number_outputs.do!(|_| {
        let amount = r.read(8);
        raw_tx.append(amount);
        let script_pubkey_size = r.read_compact_size();
        let script_pubkey = r.read(script_pubkey_size);
        raw_tx.append(u64_to_varint_bytes(script_pubkey_size));
        raw_tx.append(script_pubkey);
        outputs.push_back(Output {
            amount,
            script_pubkey
        })
    });

    let mut witness = vector[];


    if (segwit[0] == 0x00 && segwit[1] == 0x01) {

        number_inputs.do!(|_| {
            let stack_item = r.read_compact_size();
            let mut items = vector[];
            stack_item.do!(|_| {
                let size = r.read_compact_size();
                items.push_back(r.read(size));
            });
            witness.push_back(Witness {
                items
            });
        })

    };

    let locktime = r.read(4);
    raw_tx.append(locktime);

    Transaction {
        version,
        marker,
        flag,
        inputs,
        outputs,
        witness,
        locktime,
        tx_id: std::hash::sha2_256(std::hash::sha2_256(raw_tx)),
    }
}


/// Validate BTC transaction
public fun execute(tx: Transaction) : bool {
    let mut i = 0;
    while (i < tx.inputs.length()) {
        if (run(tx.inputs[i].script_sig) == false) {
            return false
        };
        i = i + 1;
    };
    true
}


public fun coinbase_check(tx: &Transaction): bool {
    if (tx.inputs.length() != 1) {
        return false
    };

    let input = tx.inputs[0];
    if (input.vout != x"ffffffffffffffff") {
        return false
    };

    // TODO: check BIP34 and BIP141
    true
}
