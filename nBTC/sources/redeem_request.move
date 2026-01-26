module nbtc::redeem_request;

use bitcoin_lib::output::{Self, Output};
use bitcoin_lib::script;
use bitcoin_lib::sighash::taproot_sighash_preimage;
use bitcoin_lib::tx;
use ika::ika::IKA;
use ika_dwallet_2pc_mpc::coordinator::{DWalletCoordinator, register_session_identifier};
use ika_dwallet_2pc_mpc::coordinator_inner::UnverifiedPresignCap;
use nbtc::nbtc_utxo::Utxo;
use nbtc::storage::Storage;
use nbtc::tx_composer::compose_withdraw_tx;
use sui::coin::Coin;
use sui::event;
use sui::sui::SUI;
use sui::table::{Self, Table};

#[error]
const ERedeemTxSigningNotCompleted: vector<u8> =
    b"The signature for the redeem has not been completed";
#[error]
const EInvalidIkaSchnorrLength: vector<u8> = b"invalid schnorr signature length from ika format";
#[error]
const EUnsupportedLockscript: vector<u8> = b"unsupported lockscript";

// signature algorithm
const TAPROOT: u32 = 1;
// hash function
const SHA256: u32 = 1;
const SIGNHASH_ALL: u8 = 0x01;

public enum RedeemStatus has copy, drop, store {
    Resolving, // finding the best UTXOs
    Signing,
    Signed,
}

public struct RedeemRequest has store {
    redeemer: address, // TODO: maybe it's not needed
    /// Bitcoin spent key (address)
    recipient_script: vector<u8>,
    nbtc_spend_script: vector<u8>,
    status: RedeemStatus,
    amount: u64,
    fee: u64,
    utxos: vector<Utxo>,
    utxo_ids: vector<u64>,
    btc_redeem_tx_id: vector<u8>,
    outputs: vector<Output>,
    sig_hashes: vector<vector<u8>>,
    sign_ids: Table<ID, bool>,
    signatures: vector<vector<u8>>,
    created_at: u64,
    signed_input: u64,
}

/// Event emitted when a proposal for redeem request is selected (solved) and we are ready
/// for creating MPC signatures.
public struct SolvedEvent has copy, drop {
    id: u64,
    utxo_ids: vector<u64>,
}

/// Event emitted when Ika sign request for a given redeem request input is sent.
public struct RequestSignatureEvent has copy, drop {
    redeem_id: u64,
    sign_id: ID, // IKA sign session ID
    input_id: u64,
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

// ========== RedeemRequest methods ===============
/// Returns true if a signature has been recorded for the given input.
///
/// Aborts if `input_id` is out of bounds (>= number of inputs).
public fun has_signature(r: &RedeemRequest, input_id: u64): bool {
    !r.signatures[input_id].is_empty()
}

public fun status(r: &RedeemRequest): &RedeemStatus {
    &r.status
}

public fun recipient_script(r: &RedeemRequest): vector<u8> { r.recipient_script }

public fun utxo_ids(r: &RedeemRequest): vector<u64> { r.utxo_ids }

public fun redeem_created_at(r: &RedeemRequest): u64 { r.created_at }

public fun inputs_length(r: &RedeemRequest): u64 { r.utxo_ids.length() }

public fun amount(r: &RedeemRequest): u64 { r.amount }

public fun utxos(r: &RedeemRequest): &vector<Utxo> {
    &r.utxos
}

public fun outputs(r: &RedeemRequest): &vector<output::Output> {
    &r.outputs
}

public fun btc_tx_id(r: &RedeemRequest): vector<u8> {
    r.btc_tx_id
}

public(package) fun move_to_signing_status(
    r: &mut RedeemRequest,
    redeem_id: u64,
    storage: &mut Storage,
) {
    let number_input = r.inputs_length();
    r.status = RedeemStatus::Signing;
    r.signatures = vector::tabulate!(number_input, |_| vector::empty());
    r.sig_hashes = vector::tabulate!(number_input, |_| vector::empty());
    number_input.do!(|i| {
        let idx = r.utxo_ids[i];
        let utxo = storage.utxo_store_mut().remove(idx);
        r.utxos.push_back(utxo);
    });

    let tx = compose_withdraw_tx(
        r.nbtc_spend_script,
        r.utxos(),
        r.recipient_script,
        r.amount,
        r.fee,
    );
    r.btc_tx_id = tx.tx_id();
    r.outputs = tx.outputs();
    event::emit(SolvedEvent {
        id: redeem_id,
        utxo_ids: r.utxo_ids,
    });
}

/// Internal function to request signature for specific input in a redeem request.
///
/// This function:
/// - Verifies the presign capability
/// - Calculates signature hash for the input
/// - Approves the message with the dWallet
/// - Requests signature from the Ika Network
/// - Stores the signature metadata and emits an event
///
/// # Arguments - see nbtc::request_utxo_sig function.
public(package) fun request_utxo_sig(
    r: &mut RedeemRequest,
    dwallet_coordinator: &mut DWalletCoordinator,
    storage: &Storage,
    redeem_id: u64,
    input_id: u64,
    msg_central_sig: vector<u8>,
    presign: UnverifiedPresignCap,
    payment_ika: &mut Coin<IKA>,
    payment_sui: &mut Coin<SUI>,
    ctx: &mut TxContext,
) {
    let verified_presign = dwallet_coordinator.verify_presign_cap(presign, ctx);

    // This should include other information for create sign hash
    let sig_hash = r.sig_hash(input_id, storage);

    let utxo = r.utxo_at(input_id);
    let dwallet_id = utxo.dwallet_id();
    let dwallet_cap = storage.dwallet(dwallet_id).cap();

    let message_approval = dwallet_coordinator.approve_message(
        dwallet_cap,
        TAPROOT,
        SHA256,
        sig_hash,
    );
    let random_bytes = tx_context::fresh_object_address(ctx).to_bytes();
    let ika_session = dwallet_coordinator.register_session_identifier(random_bytes, ctx);
    let sign_id = dwallet_coordinator.request_sign_and_return_id(
        verified_presign,
        message_approval,
        msg_central_sig,
        ika_session,
        payment_ika,
        payment_sui,
        ctx,
    );

    r.set_sign_request_metadata(input_id, sig_hash, sign_id);

    event::emit(RequestSignatureEvent {
        redeem_id,
        sign_id,
        input_id,
    });
}

/// Sets signature request metadata for a specific input.
///
/// Aborts if `input_id` is out of bounds (>= number of inputs).
public(package) fun set_sign_request_metadata(
    r: &mut RedeemRequest,
    input_id: u64,
    sig_hash: vector<u8>,
    sign_id: ID,
) {
    if (r.sig_hashes[input_id].is_empty()) {
        let s = &mut r.sig_hashes[input_id];
        *s = sig_hash;
    };
    r.sign_ids.add(sign_id, true);
}

// returns Bitcoin withdraw transaction
public fun compose_tx(r: &RedeemRequest, storage: &Storage): tx::Transaction {
    assert!(r.status == RedeemStatus::Signed, ERedeemTxSigningNotCompleted);

    let inputs = r.utxos();
    let mut tx = compose_withdraw_tx(
        r.nbtc_spend_script,
        inputs,
        r.recipient_script,
        r.amount,
        r.fee,
    );

    let mut witnesses = vector[];
    inputs.length().do!(|i| {
        let utxo = &inputs[i];
        let dwallet_id = utxo.dwallet_id();
        let lockscript = storage.dwallet(dwallet_id).lockscript();
        let ika_signature = r.signatures[i];
        // Taproot witness expects a 64-byte Schnorr signature, no sighash flag byte.
        let witness = if (script::is_taproot(lockscript)) {
            assert!(ika_signature.length() == 64, EInvalidIkaSchnorrLength);
            vector[ika_signature]
        } else {
            abort EUnsupportedLockscript
        };
        witnesses.push_back(
            tx::new_witness(witness),
        );
    });
    tx.set_witness(witnesses);
    tx
}

/// Add valid signature to redeem request for specific input index.
///
/// Aborts if `input_id` is out of bounds (>= number of inputs).
public(package) fun add_signature(r: &mut RedeemRequest, input_id: u64, ika_signature: vector<u8>) {
    let s = &mut r.signatures[input_id];
    *s = ika_signature;
    r.signed_input = r.signed_input + 1;
    if (r.signed_input == r.inputs_length()) {
        r.status = RedeemStatus::Signed;
    }
}

/// Returns sighash for input_id-th in redeem transaction.
///
/// Aborts if `input_id` is out of bounds (>= number of inputs).
public fun sig_hash(r: &RedeemRequest, input_id: u64, storage: &Storage): vector<u8> {
    // check cache
    if (!r.sig_hashes[input_id].is_empty()) {
        return r.sig_hashes[input_id]
    };

    // compute sighash
    let inputs = r.utxos();
    let utxo = &inputs[input_id];
    let dwallet_id = utxo.dwallet_id();
    let lockscript = storage.dwallet(dwallet_id).lockscript();
    let tx = compose_withdraw_tx(
        lockscript,
        inputs,
        r.recipient_script,
        r.amount,
        r.fee,
    );

    if (script::is_taproot(lockscript)) {
        let previous_pubscripts = vector::tabulate!(
            inputs.length(),
            |i| storage.dwallet(inputs[i].dwallet_id()).lockscript(),
        );
        let previous_values = vector::tabulate!(inputs.length(), |i| inputs[i].value());

        return taproot_sighash_preimage(
                &tx,
                input_id as u32, // input index
                previous_pubscripts,
                previous_values,
                SIGNHASH_ALL,
                option::none(),
                option::none(),
            )
    } else {
        abort EUnsupportedLockscript
    }
}

public(package) fun burn_utxos(r: &mut RedeemRequest) {
    let len = r.utxos.length();
    len.do!(|_i| {
        let v = r.utxos.pop_back();
        v.burn();
    });
}

public(package) fun set_utxos(r: &mut RedeemRequest, utxo_ids: vector<u64>) {
    r.utxo_ids = utxo_ids;
}

public fun new(
    nbtc_spend_script: vector<u8>,
    redeemer: address,
    recipient_script: vector<u8>,
    amount: u64,
    fee: u64, // Bitcoin withdraw tx fee (for miners)
    created_at: u64,
    ctx: &mut TxContext,
): RedeemRequest {
    RedeemRequest {
        nbtc_spend_script,
        redeemer,
        recipient_script,
        amount,
        sig_hashes: vector::empty(),
        fee,
        utxos: vector::empty(),
        sign_ids: table::new(ctx),
        signatures: vector::empty(),
        status: RedeemStatus::Resolving,
        utxo_ids: vector::empty(),
        btc_tx_id: vector::empty(),
        outputs: vector::empty(),
        created_at,
        signed_input: 0,
    }
}

/// Returns a reference to the UTXO at the given index.
///
/// Aborts if `i` is out of bounds (>= number of UTXOs).
public fun utxo_at(r: &RedeemRequest, i: u64): &Utxo {
    &r.utxos[i]
}

public fun fee(r: &RedeemRequest): u64 { r.fee }

public(package) fun record_signature(
    r: &mut RedeemRequest,
    dwallet_coordinator: &DWalletCoordinator,
    input_id: u64,
    sign_id: ID,
) {
    let utxo = r.utxo_at(input_id);
    let dwallet_id = utxo.dwallet_id();
    let signature = get_signature(dwallet_coordinator, dwallet_id, sign_id);
    // NOTE: We intentionally do not re-verify the signature on-chain here.
    // The DWallet / IKA protocol guarantees that `get_sign_signature` only
    // returns signatures that have already been validated against the
    // appropriate public key and the computed `sig_hash`. As a result,
    // performing signature verification again in this module would be
    // redundant, and we safely persist the coordinator-provided signature.
    r.add_signature(input_id, signature);
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

/// Destroys a signed/confirmed redeem request to free storage.
/// This function should only be called after the redeem has been finalized on-chain.
public(package) fun destroy_confirmed(r: RedeemRequest) {
    let RedeemRequest {
        redeemer: _,
        recipient_script: _,
        nbtc_spend_script: _,
        status: _,
        amount: _,
        fee: _,
        utxos,
        utxo_ids: _,
        btc_redeem_tx_id: _,
        outputs: _,
        sig_hashes: _,
        sign_ids,
        signatures: _,
        created_at: _,
        signed_input: _,
    } = r;
    utxos.destroy_empty();
    sign_ids.drop();
}
#[test_only]
public fun update_to_signing_for_test(r: &mut RedeemRequest, utxo_ids: vector<u64>) {
    r.set_utxos(utxo_ids);
    r.status = RedeemStatus::Signing;
}

#[test_only]
public fun update_to_signed_for_test(r: &mut RedeemRequest, signatures: vector<vector<u8>>) {
    r.signatures = signatures;
    r.signed_input = signatures.length();
    r.status = RedeemStatus::Signed
}

#[test_only]
public fun add_sign_id_for_test(r: &mut RedeemRequest, sign_id: ID) {
    r.sign_ids.add(sign_id, true);
}
