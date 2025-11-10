module nbtc::sign_request;

use bitcoin_lib::encoding::u64_to_le_bytes;
use bitcoin_lib::sighash::{create_segwit_preimage, create_p2wpkh_scriptcode};
use bitcoin_lib::tx;
use bitcoin_lib::vector_utils::vector_slice;
use ika_dwallet_2pc_mpc::coordinator::{request_sign, DWalletCoordinator};
use nbtc::nbtc_utxo::Utxo;
use nbtc::tx_composer::compose_withdraw_tx;
use sui::table::{Self, Table};
use sui::vec_map::{Self, VecMap};

use fun vector_slice as vector.slice;
#[error]
const ERedeemTxSigningNotCompleted: vector<u8> =
    b"The signature for the redeem has not been completed";
const SHA256: u32 = 1;

#[error]
const ESignatureInValid: vector<u8> = b"signature invalid for this input";

public enum RedeemStatus has copy, drop, store {
    Resolving, // finding the best UTXOs
    Signing,
    Signed,
    Confirmed,
}

public struct RedeemRequest has store {
    // TODO: maybe we don't need the ID?
    redeemer: address, // TODO: maybe it's not needed
    /// Bitcoin spent key (address)
    recipient_script: vector<u8>,
    nbtc_spend_script: vector<u8>,
    status: RedeemStatus,
    amount: u64,
    fee: u64,
    inputs: vector<Utxo>,
    sig_hashes: VecMap<u32, vector<u8>>,
    sign_ids: Table<ID, bool>,
    signatures_map: VecMap<u32, vector<u8>>,
    // public key for unlock inputs
    // notes: We can't use nbtc object here, because this create cycle import!
    public_keys: VecMap<u32, vector<u8>>,
}

// ========== RedeemStatus methods ================

public fun is_resolving(status: &RedeemStatus): bool {
    match (status) {
        RedeemStatus::Resolving => true,
        _ => false,
    }
}

public fun is_signing(status: &RedeemStatus): bool {
    match (status) {
        RedeemStatus::Signing => true,
        _ => false,
    }
}

public fun is_signed(status: &RedeemStatus): bool {
    match (status) {
        RedeemStatus::Signed => true,
        _ => false,
    }
}

public fun is_comfirmed(status: &RedeemStatus): bool {
    match (status) {
        RedeemStatus::Confirmed => true,
        _ => false,
    }
}

// ========== RedeemRequest methods ===============
public fun has_signature(r: &RedeemRequest, input_idx: u32): bool {
    r.signatures_map.contains(&input_idx)
}

public fun status(r: &RedeemRequest): &RedeemStatus {
    &r.status
}

public(package) fun set_sign_request_metadata(
    r: &mut RedeemRequest,
    input_idx: u32,
    sig_hash: vector<u8>,
    sign_id: ID,
) {
    r.sig_hashes.insert(input_idx, sig_hash);
    r.sign_ids.add(sign_id, true);
}

// return segwit transaction
public fun raw_signed_tx(r: &RedeemRequest): vector<u8> {
    assert!(r.status == RedeemStatus::Signed, ERedeemTxSigningNotCompleted);

    let mut tx = compose_withdraw_tx(
        r.nbtc_spend_script,
        r.inputs,
        r.recipient_script,
        r.amount,
        r.fee, // TODO:: Set fee at parameter, or query from oracle
    );

    let mut witnesses = vector[];
    r.inputs.length().do!(|i| {
        witnesses.push_back(
            tx::new_witness(vector[
                // signature
                *r.signatures_map.get(&(i as u32)),
                *r.public_keys.get(&(i as u32)),
            ]),
        );
    });

    tx.set_witness(witnesses);

    tx.serialize_segwit()
}

// add valid signature to redeem request for specify input index
public(package) fun add_signature(r: &mut RedeemRequest, input_idx: u32, signature: vector<u8>) {
    r.signatures_map.insert(input_idx, signature);
    if (r.signatures_map.length() == r.inputs.length()) {
        r.status = RedeemStatus::Signed;
    }
}

/// Returns signature hash for input_idx-th in redeem transaction
public fun sig_hash(r: &RedeemRequest, input_idx: u32): vector<u8> {
    r.sig_hashes.try_get(&input_idx).extract_or!({
        let tx = compose_withdraw_tx(
            r.nbtc_spend_script,
            r.inputs,
            r.recipient_script,
            r.amount,
            r.fee, // TODO:: Set fee at parameter, or query from oracle
        );
        let input_spend_script = r.inputs[input_idx as u64].spend_script();
        let script_code = create_p2wpkh_scriptcode(
            input_spend_script.slice(2, 22) // nbtc public key hash
        );
        create_segwit_preimage(
            &tx,
            input_idx as u64, // input index
            &script_code, // segwit nbtc spend key
            u64_to_le_bytes(r.inputs[input_idx as u64].value()), // amount
            0x01, // SIGNHASH_ALL
        )
    })
}

public fun new(
    nbtc_spend_script: vector<u8>,
    redeemer: address,
    recipient_script: vector<u8>,
    amount: u64,
    fee: u64,
    ctx: &mut TxContext,
): RedeemRequest {
    RedeemRequest {
        nbtc_spend_script,
        redeemer,
        recipient_script,
        amount,
        sig_hashes: vec_map::empty(),
        fee,
        inputs: vector::empty(),
        sign_ids: table::new(ctx),
        signatures_map: vec_map::empty(),
        public_keys: vec_map::empty(),
        status: RedeemStatus::Resolving,
    }
}

public fun utxo_at(r: &RedeemRequest, input_idx: u32): &Utxo { &r.inputs[input_idx as u64] }

public(package) fun validate_signature(
    r: &mut RedeemRequest,
    dwallet_coordinator: &DWalletCoordinator,
    redeem_id: u64,
    input_idx: u32,
    sign_id: ID,
) {
    // TODO: ensure we get right spend key, because this spend key can also inactive_spend_key
    let sign_hash = r.sig_hash(input_idx);
    let dwallet_id = r.utxo_at(input_idx).dwallet_id();
    let signature = get_signature(dwallet_coordinator, dwallet_id, sign_id);
    let pk = r.public_keys.get(&input_idx);
    let is_valid = sui::ecdsa_k1::secp256k1_verify(
        &signature,
        pk,
        &sign_hash,
        SHA256 as u8,
    );

    assert!(is_valid, ESignatureInValid);
    r.add_signature(input_idx, signature);
}

public(package) fun get_signature(
    dwallet_coordinator: &DWalletCoordinator,
    dwallet_id: ID,
    sign_id: ID,
): vector<u8> {
    let mut signature = dwallet_coordinator
        .get_dwallet(dwallet_id)
        .get_sign_session(sign_id)
        .get_sign_signature();

    signature.extract()
}
