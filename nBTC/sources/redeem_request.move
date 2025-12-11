module nbtc::redeem_request;

use bitcoin_lib::encoding::{u64_to_le_bytes, der_encode_signature};
use bitcoin_lib::sighash::{create_segwit_preimage, create_p2wpkh_scriptcode};
use bitcoin_lib::tx;
use bitcoin_lib::vector_utils::vector_slice;
use ika::ika::IKA;
use ika_dwallet_2pc_mpc::coordinator::DWalletCoordinator;
use ika_dwallet_2pc_mpc::coordinator_inner::VerifiedPartialUserSignatureCap;
use ika_dwallet_2pc_mpc::sessions_manager::SessionIdentifier;
use nbtc::nbtc_utxo::Utxo;
use nbtc::storage::Storage;
use nbtc::tx_composer::compose_withdraw_tx;
use sui::coin::Coin;
use sui::event;
use sui::sui::SUI;
use sui::table::{Self, Table};
use sui::vec_map::{Self, VecMap};

use fun vector_slice as vector.slice;
#[error]
const ERedeemTxSigningNotCompleted: vector<u8> =
    b"The signature for the redeem has not been completed";
#[error]
const ESignatureInValid: vector<u8> = b"signature invalid for this input";
#[error]
const EInvalidSignatureId: vector<u8> = b"invalid signature id for redeem request";
#[error]
const EInvalidIkaECDSALength: vector<u8> = b"invalid ecdsa signature length from ika format";

const ECDSA: u32 = 0;
const SHA256: u32 = 1;
const SIGNHASH_ALL: u8 = 0x01;

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
    dwallet_ids: vector<ID>,
    utxo_ids: vector<u64>,
    sig_hashes: VecMap<u32, vector<u8>>,
    sign_ids: Table<ID, bool>,
    signatures_map: VecMap<u32, vector<u8>>,
    created_at: u64,
}

//TODO: Add logic to extract data from redeem inputs for:
/// Event emitted when a proposal for redeem request is selected (solved) and we are ready
/// for creating MPC signatures.
public struct SolvedEvent has copy, drop {
    id: u64,
    inputs: vector<Utxo>,
}

/// Event emitted when Ika sign request for a given redeem request input is sent.
public struct RequestSignatureEvent has copy, drop {
    redeem_id: u64,
    sign_id: ID, // IKA sign session ID
    input_idx: u32,
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

public fun recipient_script(r: &RedeemRequest): vector<u8> { r.recipient_script }

public fun dwallet_ids(r: &RedeemRequest): vector<ID> { r.dwallet_ids }

public fun utxo_ids(r: &RedeemRequest): vector<u64> { r.utxo_ids }

public fun redeem_created_at(r: &RedeemRequest): u64 { r.created_at }

public fun inputs_length(r: &RedeemRequest): u64 { r.inputs.length() }

public fun amount(r: &RedeemRequest): u64 { r.amount }

public fun move_to_signing_status(r: &mut RedeemRequest, redeem_id: u64) {
    r.status = RedeemStatus::Signing;
    event::emit(SolvedEvent {
        id: redeem_id,
        inputs: r.inputs,
    });
}

public(package) fun request_signature_for_input(
    r: &mut RedeemRequest,
    dwallet_coordinator: &mut DWalletCoordinator,
    storage: &Storage,
    redeem_id: u64,
    input_idx: u32,
    user_sig_cap: VerifiedPartialUserSignatureCap,
    session_identifier: SessionIdentifier,
    payment_ika: &mut Coin<IKA>,
    payment_sui: &mut Coin<SUI>,
    ctx: &mut TxContext,
) {
    // This should include other information for create sign hash
    let sig_hash = r.sig_hash(input_idx, storage);

    let dwallet_id = r.dwallet_ids[input_idx as u64];
    let dwallet_cap = storage.dwallet_cap(dwallet_id);
    let message_approval = dwallet_coordinator.approve_message(
        dwallet_cap,
        ECDSA,
        SHA256,
        sig_hash,
    );

    let sign_id = dwallet_coordinator.request_sign_with_partial_user_signature_and_return_id(
        user_sig_cap,
        message_approval,
        session_identifier,
        payment_ika,
        payment_sui,
        ctx,
    );

    r.set_sign_request_metadata(input_idx, sig_hash, sign_id);

    event::emit(RequestSignatureEvent {
        redeem_id,
        sign_id,
        input_idx,
    });
}

public(package) fun set_sign_request_metadata(
    r: &mut RedeemRequest,
    input_idx: u32,
    sig_hash: vector<u8>,
    sign_id: ID,
) {
    if (!r.sig_hashes.contains(&input_idx)) {
        r.sig_hashes.insert(input_idx, sig_hash);
    };
    r.sign_ids.add(sign_id, true);
}

// return segwit transaction
public fun raw_signed_tx(r: &RedeemRequest, storage: &Storage): vector<u8> {
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
        let dwallet_id = r.dwallet_ids[i];
        let public_key = storage.dwallet_metadata(dwallet_id).public_key();
        let signature = *r.signatures_map.get(&(i as u32));
        witnesses.push_back(
            tx::new_witness(vector[signature, public_key]),
        );
    });

    tx.set_witness(witnesses);

    tx.serialize_segwit()
}

// add valid signature to redeem request for specify input index
public(package) fun add_signature(
    r: &mut RedeemRequest,
    input_idx: u32,
    ika_signature: vector<u8>,
) {
    // ECDSA Ika signature returns 65 bytes
    assert!(ika_signature.length() == 65, EInvalidIkaECDSALength);
    let raw_signature = ika_signature.slice(1, 65); // skip the first byte (pub key recovery byte)
    // NOTE: With taproot we don't need enocde signature
    r.signatures_map.insert(input_idx, der_encode_signature(raw_signature, SIGNHASH_ALL));
    if (r.signatures_map.length() == r.inputs.length()) {
        r.status = RedeemStatus::Signed;
    }
}

/// Returns sighash for input_idx-th in redeem transaction
public fun sig_hash(r: &RedeemRequest, input_idx: u32, storage: &Storage): vector<u8> {
    r.sig_hashes.try_get(&input_idx).extract_or!({
        let dwallet_id = r.dwallet_ids[input_idx as u64];
        let lockscript = storage.dwallet_metadata(dwallet_id).lockscript();
        let tx = compose_withdraw_tx(
            lockscript,
            r.inputs,
            r.recipient_script,
            r.amount,
            r.fee, // TODO:: Set fee at parameter, or query from oracle
        );
        let input_spend_script = storage.dwallet_metadata(dwallet_id).lockscript();
        let script_code = create_p2wpkh_scriptcode(
            input_spend_script.slice(2, 22) // nbtc public key hash
        );
        std::hash::sha2_256(
            create_segwit_preimage(
                &tx,
                input_idx as u64, // input index
                &script_code, // segwit nbtc spend key
                u64_to_le_bytes(r.inputs[input_idx as u64].value()), // amount
                SIGNHASH_ALL,
            ),
        )
    })
}

public(package) fun set_best_utxos(
    r: &mut RedeemRequest,
    utxos: vector<Utxo>,
    dwallet_ids: vector<ID>,
    utxo_ids: vector<u64>,
) {
    r.inputs = utxos;
    r.dwallet_ids = dwallet_ids;
    r.utxo_ids = utxo_ids;
}

public fun new(
    nbtc_spend_script: vector<u8>,
    redeemer: address,
    recipient_script: vector<u8>,
    amount: u64,
    fee: u64,
    created_at: u64,
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
        status: RedeemStatus::Resolving,
        dwallet_ids: vector::empty(),
        utxo_ids: vector::empty(),
        created_at,
    }
}

public fun utxo_at(r: &RedeemRequest, input_idx: u32): &Utxo { &r.inputs[input_idx as u64] }

public fun fee(r: &RedeemRequest): u64 { r.fee }

public(package) fun validate_signature(
    r: &mut RedeemRequest,
    dwallet_coordinator: &DWalletCoordinator,
    storage: &Storage,
    input_idx: u32,
    sign_id: ID,
) {
    // TODO: ensure we get right spend key, because this spend key can also inactive_spend_key
    assert!(r.sign_ids.contains(sign_id), EInvalidSignatureId);
    let sign_hash = r.sig_hash(input_idx, storage);
    let dwallet_id = r.dwallet_ids[input_idx as u64];
    let signature = get_signature(dwallet_coordinator, dwallet_id, sign_id);
    let pk = storage.dwallet_metadata(dwallet_id).public_key();
    let is_valid = sui::ecdsa_k1::secp256k1_verify(
        &vector_slice(&signature, 1, 65),
        &pk,
        &sign_hash,
        SHA256 as u8,
    );

    assert!(is_valid, ESignatureInValid);
    r.add_signature(input_idx, signature);
}

public fun get_signature(
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

#[test_only]
public fun move_to_signing(
    r: &mut RedeemRequest,
    inputs: vector<Utxo>,
    dwallet_ids: vector<ID>,
    utxo_ids: vector<u64>,
) {
    r.inputs = inputs;
    r.dwallet_ids = dwallet_ids;
    r.utxo_ids = utxo_ids;
    r.status = RedeemStatus::Signing
}

#[test_only]
public fun move_to_signed(r: &mut RedeemRequest, signatures: vector<vector<u8>>) {
    r.signatures_map =
        vec_map::from_keys_values(
            vector::tabulate!(signatures.length(), |i| i as u32),
            signatures,
        );
    r.status = RedeemStatus::Signed
}
