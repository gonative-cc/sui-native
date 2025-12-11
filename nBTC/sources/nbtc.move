// SPDX-License-Identifier: MPL-2.0

module nbtc::nbtc;

use bitcoin_lib::reader;
use bitcoin_lib::tx;
use bitcoin_spv::light_client::LightClient;
use ika::ika::IKA;
use ika_dwallet_2pc_mpc::coordinator::DWalletCoordinator;
use ika_dwallet_2pc_mpc::coordinator_inner::{DWalletCap, VerifiedPartialUserSignatureCap};
use ika_dwallet_2pc_mpc::sessions_manager::SessionIdentifier;
use nbtc::config::{Self, Config};
use nbtc::nbtc_utxo::{Self, Utxo, validate_utxos};
use nbtc::redeem_request::{Self, RedeemRequest};
use nbtc::storage::{Storage, create_storage, create_dwallet_metadata};
use nbtc::verify_payment::verify_payment;
use sui::address;
use sui::balance::{Self, Balance};
use sui::clock::Clock;
use sui::coin::{Self, Coin, TreasuryCap};
use sui::coin_registry;
use sui::event;
use sui::sui::SUI;
use sui::table::{Self, Table};

//
// Constant
//

/// Package version
const VERSION: u32 = 1;

/// Coin Metadata
const DECIMALS: u8 = 8;
const SYMBOL: vector<u8> = b"nBTC-v0.3";
const NAME: vector<u8> = b"Native nBTC v0.3";
const DESCRIPTION: vector<u8> = b"Native synthetic BTC";
const ICON_URL: vector<u8> =
    b"https://raw.githubusercontent.com/gonative-cc/sui-native/master/assets/nbtc.svg";

/// ops_arg consts
const MINT_OP_APPLY_FEE: u32 = 1;

const ECDSA: u32 = 0;
const SHA256: u32 = 1;

//
// Errors
//

#[error]
const EInvalidArguments: vector<u8> = b"Function arguments are not valid";
#[error]
const EInvalidDepositKey: vector<u8> = b"Not an nBTC deposit spend key";
#[error]
const ETxAlreadyUsed: vector<u8> = b"The Bitcoin transaction ID has been already used for minting";
#[error]
const EMintAmountIsZero: vector<u8> = b"BTC deposit must not be zero";
#[error]
const EUntrustedLightClient: vector<u8> = b"Wrong Light Client object ID";
#[error]
const EVersionMismatch: vector<u8> = b"The package has been updated. You are using a wrong version";
#[error]
const EAlreadyUpdated: vector<u8> =
    b"The package version has been already updated to the latest one";
#[error]
const EInvalidOpsArg: vector<u8> = b"invalid mint ops_arg";
#[error]
const EDuplicatedDWallet: vector<u8> = b"duplicated dwallet";
#[error]
const EBalanceNotEmpty: vector<u8> = b"balance not empty";
#[error]
const ENotReadlyForSign: vector<u8> = b"redeem tx is not ready for signing";
#[error]
const EInputAlreadyUsed: vector<u8> = b"input has been already used";
#[error]
const EActiveDwalletNotInStorage: vector<u8> = b"try active dwallet not exist in storage";
#[error]
const ERedeemWindowExpired: vector<u8> = b"resolving window has expired";
#[error]
const EInvalidUTXOSet: vector<u8> = b"Invalid utxo set";
#[error]
const ENoUTXOsProposed: vector<u8> = b"No UTXOs proposed";
#[error]
const ENotResolving: vector<u8> = b"redeem request is not in resolving status";
#[error]
const EInvalidDWalletCoordinator: vector<u8> = b"Invalid Dwallet coordinator";

//
// Structs
//

/// Coin type identifier (`Coin<package_object::nbtc::NBTC>`) and One Time Witness.
public struct NBTC has drop {}

/// Operator capability. Created only once in the `init` function.
public struct OpCap has key, store { id: UID }

/// Admin capability. Created only once in the `init` function.
/// It has higher capabilities than Operator. For example, it can change contract parameters .
public struct AdminCap has key, store { id: UID }

/// NbtcContract holds the TreasuryCap as well as configuration and state.
/// It should be a shared object to enable anyone to interact with the contract.
public struct NbtcContract has key, store {
    id: UID,
    version: u32,
    cap: TreasuryCap<NBTC>,
    /// set of "minted" txs
    tx_ids: Table<vector<u8>, bool>,
    config: Table<u32, Config>,
    fees_collected: Balance<NBTC>,
    // TODO: probably we should have UTXOs / nbtc pubkey
    utxos: Table<u64, Utxo>, // Table<dwallet_id + utxo_idx, Utxo>
    next_utxo: u64,
    // redeem request token for nbtc
    redeem_requests: Table<u64, RedeemRequest>,
    // lock nbtc for redeem, this is a mapping from request id to nBTC redeem coin
    locked: Table<u64, Coin<NBTC>>,
    storage: Storage,
    // should have one active_dwallet_id
    active_dwallet_id: Option<ID>,
    next_redeem_req: u64,
    /// minimum amount of time in milliseconds the redeem resolution should take.
    redeem_duration: u64,
}

/// MintEvent is emitted when nBTC is successfully minted.
public struct MintEvent has copy, drop {
    // Sui recipient
    recipient: address,
    fee: u64,
    dwallet_id: ID,
    utxo_id: u64,
    // btc data
    btc_script_publickey: vector<u8>,
    btc_tx_id: vector<u8>, // TODO: maybe we should change to bitcoin address format?
    btc_vout: u32,
    btc_amount: u64, // in satoshi
}

public struct InactiveDepositEvent has copy, drop {
    bitcoin_spend_key: vector<u8>,
    recipient: address,
    amount: u64, // in satoshi
}

public struct RedeemInactiveDepositEvent has copy, drop {
    bitcoin_spend_key: vector<u8>,
    /// Bitcoin recipient
    recipient: vector<u8>,
    amount: u64, // in satoshi
}

public struct RedeemRequestEvent has copy, drop {
    redeem_id: u64,
    redeemer: address,
    recipient_script: vector<u8>, // Full Bitcoin pubkey/lockscript
    amount: u64, // in satoshi
    created_at: u64,
}

public struct SignatureConfirmedEvent has copy, drop {
    redeem_id: u64,
    input_idx: u32,
    is_fully_signed: bool,
}

public struct ProposeUtxoEvent has copy, drop {
    redeem_id: u64,
    dwallet_ids: vector<ID>,
    utxo_ids: vector<u64>,
}

//
// Functions
//

// NOTE: after contract creation, we need to
fun init(witness: NBTC, ctx: &mut TxContext) {
    let (builder, treasury_cap) = coin_registry::new_currency_with_otw(
        witness,
        DECIMALS,
        SYMBOL.to_string(),
        NAME.to_string(),
        DESCRIPTION.to_string(),
        ICON_URL.to_string(),
        ctx,
    );

    let metadata_cap = builder.finalize(ctx);

    // NOTE: we removed post deployment setup function and didn't want to implement PTB style
    // initialization, so we require setting the address before publishing the package.
    let nbtc_bitcoin_spend_key = b""; // TODO: valid bitcoin address
    assert!(nbtc_bitcoin_spend_key.length() >= 22);
    let mut contract = NbtcContract {
        id: object::new(ctx),
        version: VERSION,
        cap: treasury_cap,
        tx_ids: table::new(ctx),
        config: table::new(ctx),
        utxos: table::new(ctx),
        fees_collected: balance::zero(),
        next_utxo: 0,
        redeem_requests: table::new<u64, RedeemRequest>(ctx),
        locked: table::new(ctx),
        storage: create_storage(ctx),
        active_dwallet_id: option::none(),
        next_redeem_req: 0,
        redeem_duration: 5*60_000, // 5min
    };

    contract
        .config
        .add(
            VERSION,
            config::new(@bitcoin_lc.to_id(), @fallback_addr, 10, @ika_coordinator.to_id(), ctx),
        );
    let sender = ctx.sender();
    transfer::public_share_object(contract);
    transfer::public_transfer(metadata_cap, sender);

    transfer::transfer(OpCap { id: object::new(ctx) }, sender);
    transfer::transfer(AdminCap { id: object::new(ctx) }, sender);
}

//
// Helper methods
//

/// make all checks. Returns (amount, recipient, utxo_idx) tuple.
/// See mint function for documentation about parameters.
/// TODO: Support multiple UTXOs with the same spending_key in a single transaction.
/// Currently only handles one UTXO per transaction. Ideally there should be only one
fun verify_deposit(
    contract: &mut NbtcContract,
    light_client: &LightClient,
    dwallet_id: ID,
    tx_bytes: vector<u8>,
    proof: vector<vector<u8>>,
    height: u64,
    tx_index: u64,
    // see mint function for information about payload argument.
    _payload: vector<u8>,
    ops_arg: u32,
): (u64, address, vector<u64>) {
    assert!(contract.version == VERSION, EVersionMismatch);
    assert!(ops_arg == 0 || ops_arg == MINT_OP_APPLY_FEE, EInvalidOpsArg);
    let provided_lc_id = object::id(light_client);
    assert!(provided_lc_id == contract.config().light_client_id(), EUntrustedLightClient);

    let mut r = reader::new(tx_bytes);
    let tx = tx::deserialize(&mut r);

    let tx_id = tx.tx_id();

    // Double spend prevent
    assert!(!contract.tx_ids.contains(tx_id), ETxAlreadyUsed);
    contract.tx_ids.add(tx_id, true);
    let lockscript = contract.storage.dwallet_metadata(dwallet_id).lockscript();
    // NOTE: We assume only one active key. We should handle mutiple nbtc active key in the
    // future.
    let (amount, mut op_return, vouts) = verify_payment(
        light_client,
        height,
        proof,
        tx_index,
        &tx,
        lockscript, // We compare with lockscript to filter the vouts for deposit to nbtc address on BTC
    );

    assert!(amount > 0, EMintAmountIsZero);
    let mut recipient: address = contract.config().fallback_addr();
    if (op_return.is_some()) {
        let msg = op_return.extract();
        let mut msg_reader = reader::new(msg);
        let op_ret_type = msg_reader.read_byte();
        if (op_ret_type == 0x00) {
            if (msg_reader.readable(32)) {
                recipient = address::from_bytes(msg_reader.read(32));
            };

            // For op_ret_type=0x0 we expect only 32 bytes. If the stream is longer (more data), then
            // the format is invalid, so moving recipient to fallback.
            if (!msg_reader.end_stream()) {
                recipient = contract.config().fallback_addr();
            }
        }
    };

    // UTXO for each matched output since vouts is a vector now
    let o = tx.outputs();
    let mut utxo_idx = vector[];
    let mut i = 0;
    let dwallet_id = *contract.active_dwallet_id.borrow();
    while (i < vouts.length()) {
        let vout_idx = vouts[i];
        let o_amount = o[vout_idx as u64].amount();
        let utxo_idx_next = contract.next_utxo;
        add_utxo_to_contract(contract, tx_id, vout_idx, o_amount, lockscript, dwallet_id);
        utxo_idx.push_back(utxo_idx_next);
        i = i + 1;
    };

    (amount, recipient, utxo_idx)
}

public fun active_lockscript(contract: &NbtcContract): vector<u8> {
    let dwallet_id = *contract.active_dwallet_id.borrow();
    contract.storage.dwallet_metadata(dwallet_id).lockscript()
}

public fun active_balance(contract: &NbtcContract): u64 {
    let dwallet_id = *contract.active_dwallet_id.borrow();
    contract.storage.dwallet_metadata(dwallet_id).total_deposit()
}
//
// Public methods
//

/// Mints nBTC tokens after verifying a Bitcoin transaction proof.
/// * `tx_bytes`: raw, hex-encoded tx bytes.
/// * `proof`: merkle proof for the tx.
/// * `height`: block height, where the tx was included.
/// * `tx_index`: index of the tx within the block.
/// * `payload`: additional argument for the op_return instruction handling.
/// * `ops_arg`: operation argument controlling fee application.
///   - Pass `1` to apply minting fees.
///   - Pass `0` to skip minting fees (for special cases or admin operations).
/// Emits `MintEvent` if successful.
public fun mint(
    contract: &mut NbtcContract,
    light_client: &LightClient,
    tx_bytes: vector<u8>,
    proof: vector<vector<u8>>,
    height: u64,
    tx_index: u64,
    // The `payload` parameter is reserved for advanced op_return instruction handling.
    // Implementation pending. Do not remove; will be used to support additional minting logic,
    // while keeping stable API.
    payload: vector<u8>,
    ops_arg: u32,
    ctx: &mut TxContext,
) {
    let active_dwallet_id = *contract.active_dwallet_id.borrow();
    let (mut amount, recipient, utxo_ids) = contract.verify_deposit(
        light_client,
        active_dwallet_id,
        tx_bytes,
        proof,
        height,
        tx_index,
        payload,
        ops_arg,
    );
    assert!(amount > 0, EMintAmountIsZero);

    contract.storage.increase_total_deposit(active_dwallet_id, amount);
    let mut minted = contract.cap.mint_balance(amount);
    let mut fee_amount = 0;

    if (ops_arg == MINT_OP_APPLY_FEE) {
        fee_amount = amount.min(contract.config().mint_fee());
        let fee = minted.split(fee_amount);
        amount = amount - fee_amount;
        contract.fees_collected.join(fee);
    };

    if (amount > 0) transfer::public_transfer(coin::from_balance(minted, ctx), recipient)
    else minted.destroy_zero();

    let btc_tx_id = contract.utxos[utxo_ids[0]].tx_id();
    let btc_vout = contract.utxos[utxo_ids[0]].vout();
    event::emit(MintEvent {
        recipient,
        fee: fee_amount,
        dwallet_id: active_dwallet_id,
        utxo_id: utxo_ids[0],
        btc_script_publickey: contract.active_lockscript(),
        btc_tx_id,
        btc_vout,
        btc_amount: amount,
    });
}

// TODO: test this function
/// Like mint, but records deposit to an inacitve deposit_spend_key.
/// This function allows user to record and verify deposit to an inactive key (e.g. user
/// by mistake used an old, inactive bitcoin deposit key) and recover that using
/// `redeem_from_inactive` function call.
/// Arguments are same as to `mint` with one extra argument:
/// * `deposit_spend_key`: bitcoin spend pub key the user used for the UTXO nBTC deposit.
/// Emits `InactiveDepositEvent`.
public fun record_inactive_deposit(
    contract: &mut NbtcContract,
    light_client: &LightClient,
    dwallet_id: ID,
    tx_bytes: vector<u8>,
    proof: vector<vector<u8>>,
    height: u64,
    tx_index: u64,
    payload: vector<u8>,
    ops_arg: u32,
) {
    assert!(contract.version == VERSION, EVersionMismatch);
    assert!(ops_arg == 0 || ops_arg == MINT_OP_APPLY_FEE, EInvalidOpsArg);
    let provided_lc_id = object::id(light_client);
    assert!(provided_lc_id == contract.config().light_client_id(), EUntrustedLightClient);
    assert!(
        option::some(dwallet_id) != contract.active_dwallet_id && contract.storage.exist(dwallet_id),
        EInvalidDepositKey,
    );

    let deposit_spend_key = contract.storage.dwallet_metadata(dwallet_id).lockscript();
    let (amount, recipient, _utxo_idx) = contract.verify_deposit(
        light_client,
        dwallet_id,
        tx_bytes,
        proof,
        height,
        tx_index,
        payload,
        ops_arg,
    );

    contract.storage.increase_record_balance(dwallet_id, recipient, amount);
    event::emit(InactiveDepositEvent {
        bitcoin_spend_key: deposit_spend_key,
        recipient,
        amount,
    });
}

/// Request signing for specific input in redeem transaction,
/// partial_user_signature_cap: Created by future sign request
/// Because we use shared dwallet this is already public and we don't need to send "user share's"
/// signature. The Ika also auto checks if the message we want to sign is identical between messages
/// signed by nbtc user share and message we request here.
/// We will:
///  - compute the sign hash for specific input
///  - Request signature from Ika
///  - Record sing_id and other recomputeable data
public fun request_signature_for_input(
    contract: &mut NbtcContract,
    dwallet_coordinator: &mut DWalletCoordinator,
    request_id: u64,
    input_idx: u32,
    user_sig_cap: VerifiedPartialUserSignatureCap,
    session_identifier: SessionIdentifier,
    payment_ika: &mut Coin<IKA>,
    payment_sui: &mut Coin<SUI>,
    ctx: &mut TxContext,
) {
    assert!(
        object::id(dwallet_coordinator) == contract.config().dwallet_coordinator(),
        EInvalidDWalletCoordinator,
    );
    let request = &mut contract.redeem_requests[request_id];
    assert!(request.status().is_signing(), ENotReadlyForSign);
    assert!(!request.has_signature(input_idx), EInputAlreadyUsed);
    request.request_signature_for_input(
        dwallet_coordinator,
        &contract.storage,
        request_id,
        input_idx,
        user_sig_cap,
        session_identifier,
        payment_ika,
        payment_sui,
        ctx,
    );
}

/// redeem initiates nBTC redemption and BTC withdraw process.
/// Returns total amount of redeemed balance.
public fun redeem(
    contract: &mut NbtcContract,
    coin: Coin<NBTC>,
    recipient_script: vector<u8>,
    clock: &Clock,
    ctx: &mut TxContext,
): u64 {
    assert!(contract.version == VERSION, EVersionMismatch);
    // TODO: implement logic to guard burning and manage UTXOs
    // TODO: we can call remove_inactive_spend_key if reserves of this key is zero

    let r = redeem_request::new(
        contract.active_lockscript(),
        ctx.sender(),
        recipient_script,
        coin.value(),
        150, // TODO: query fee from oracle or give api for user to set this
        clock.timestamp_ms(),
        ctx,
    );
    // TODO: we repeat this logic a lot of time. Consider to create a generic function for this
    // type.
    let redeem_id = contract.next_redeem_req;

    event::emit(RedeemRequestEvent {
        redeem_id,
        redeemer: ctx.sender(),
        recipient_script,
        amount: r.amount(),
        created_at: r.redeem_created_at(),
    });

    contract.redeem_requests.add(redeem_id, r);
    contract.locked.add(redeem_id, coin);
    contract.next_redeem_req = redeem_id + 1;

    return redeem_id
}

public fun validate_signature(
    contract: &mut NbtcContract,
    dwallet_coordinator: &DWalletCoordinator,
    redeem_id: u64,
    input_idx: u32,
    sign_id: ID,
) {
    assert!(
        object::id(dwallet_coordinator) == contract.config().dwallet_coordinator(),
        EInvalidDWalletCoordinator,
    );
    let r = &mut contract.redeem_requests[redeem_id];
    assert!(!r.has_signature(input_idx), EInputAlreadyUsed);

    r.validate_signature(dwallet_coordinator, &contract.storage, input_idx, sign_id);

    let is_fully_signed = r.status().is_signed();
    event::emit(SignatureConfirmedEvent {
        redeem_id,
        input_idx,
        is_fully_signed,
    });
}

//TODO: update event emmitted to include the data from the redeem request
public fun finalize_redeem_request(contract: &mut NbtcContract, redeem_id: u64, clock: &Clock) {
    assert!(contract.version == VERSION, EVersionMismatch);
    let r = &mut contract.redeem_requests[redeem_id];

    // 1. Make sure there is a utxo proposed and we are past the finalization time
    assert!(r.inputs_length() > 0, ENoUTXOsProposed);
    assert!(r.status().is_resolving(), ENotResolving);

    let current_time = clock.timestamp_ms();
    let deadline = r.redeem_created_at() + contract.redeem_duration;
    assert!(current_time > deadline, ERedeemWindowExpired);

    r.move_to_signing_status(redeem_id);
}

public fun propose_utxos(
    contract: &mut NbtcContract,
    redeem_id: u64,
    utxo_ids: vector<u64>,
    dwallet_ids: vector<ID>,
    clock: &Clock,
) {
    assert!(contract.version == VERSION, EVersionMismatch);

    let r = &mut contract.redeem_requests[redeem_id];
    assert!(r.status().is_resolving(), ENotResolving);

    let current_time = clock.timestamp_ms();
    let redeem_created_at = r.redeem_created_at();
    let deadline = redeem_created_at + contract.redeem_duration;
    assert!(current_time <= deadline, ERedeemWindowExpired);
    let requested_amount = r.amount();

    assert!(
        validate_utxos(&contract.utxos, &utxo_ids, dwallet_ids, requested_amount) >= requested_amount,
        EInvalidUTXOSet,
    );

    let utxos = utxo_ids.map!(|idx| contract.utxos[idx]);
    r.set_best_utxos(utxos, dwallet_ids);

    event::emit(ProposeUtxoEvent {
        redeem_id,
        dwallet_ids,
        utxo_ids,
    })
}

/// Allows user to withdraw back deposited BTC that used an inactive deposit spend key.
/// When user deposits to an inactive Bitcoin key, nBTC is not minted.
/// See docs of the record_inactive_deposit function.
public fun withdraw_inactive_deposit(
    contract: &mut NbtcContract,
    bitcoin_recipient: vector<u8>,
    dwallet_id: ID,
    ctx: &mut TxContext,
): u64 {
    assert!(contract.version == VERSION, EVersionMismatch);
    assert!(
        option::some(dwallet_id) != contract.active_dwallet_id && contract.storage.exist(dwallet_id),
        EInvalidDepositKey,
    );
    let amount = contract.storage.remove_inactive_balance(dwallet_id, ctx.sender());
    let deposit_spend_key = contract.storage.dwallet_metadata(dwallet_id).lockscript();
    event::emit(RedeemInactiveDepositEvent {
        bitcoin_spend_key: deposit_spend_key,
        recipient: bitcoin_recipient,
        amount,
    });

    // TODO: implement logic to guard burning
    // TODO: we can delete the btc public key when reserves of this key is zero

    amount
}

/// update_version updates the contract.version to the latest, making the usage of the older
/// versions not possible
public fun update_version(contract: &mut NbtcContract) {
    assert!(VERSION > contract.version, EAlreadyUpdated);
    contract.version = VERSION;
}

/// Merge existing UTXOs to a new, aggregated one assigned to the current active spend key.
/// Used for moving funds from an inactive spend key to an active one.
public fun merge_utxos(_: &mut NbtcContract, _num_utxos: u16) {}

//
// Admin functions
//

public fun update_redeem_duration(_: &OpCap, contract: &mut NbtcContract, redeem_duration: u64) {
    assert!(VERSION > contract.version, EAlreadyUpdated);
    assert!(redeem_duration >= 1000, EInvalidArguments); // at least 1s
    contract.redeem_duration = redeem_duration;
}

public fun withdraw_fees(_: &OpCap, contract: &mut NbtcContract, ctx: &mut TxContext): Coin<NBTC> {
    assert!(VERSION > contract.version, EAlreadyUpdated);
    coin::from_balance(contract.fees_collected.withdraw_all(), ctx)
}

public fun change_fees(_: &AdminCap, contract: &mut NbtcContract, mint_fee: u64) {
    let config_mut = &mut contract.config[VERSION];
    config_mut.set_mint_fee(mint_fee);
}

/// Sets config for specific NBTC version.
/// This should be called by the admin before updating the package with the next package_version
public fun set_config(_: &AdminCap, contract: &mut NbtcContract, version: u32, config: Config) {
    contract.config.add(version, config);
}

/// Set a metadata for dwallet
/// BTC lockscript must derive from dwallet public key which is control by dwallet_cap.
public fun add_dwallet(
    _: &AdminCap,
    contract: &mut NbtcContract,
    dwallet_cap: DWalletCap,
    lockscript: vector<u8>,
    public_key: vector<u8>,
    nbtc_endpoint_user_share: vector<u8>,
    ctx: &mut TxContext,
) {
    // TODO: Verify public key and lockscript
    // In the case lockscript is p2wpkh, p2pkh:
    // - verify public key hash in lock script is compute from public_key
    // Reseach what we should check when lockscript is taproot, p2wsh(p2sh)..
    let dwallet_id = dwallet_cap.dwallet_id();
    assert!(!contract.storage.exist(dwallet_id), EDuplicatedDWallet);

    let dmeta = create_dwallet_metadata(
        lockscript,
        public_key,
        nbtc_endpoint_user_share,
        ctx,
    );
    contract.storage.add_metadata(dwallet_id, dmeta);
    contract.storage.add_dwallet_cap(dwallet_id, dwallet_cap);
}

public fun set_active_dwallet(_: &AdminCap, contract: &mut NbtcContract, dwallet_id: ID) {
    assert!(contract.storage.exist(dwallet_id), EActiveDwalletNotInStorage);
    contract.active_dwallet_id = option::some(dwallet_id);
}

public fun remove_inactive_dwallet(_: &AdminCap, contract: &mut NbtcContract, dwallet_id: ID) {
    // TODO: need to decide if we want to keep balance check. Technically, it's not needed
    // if we can provide public signature to the merge_coins
    // NOTE: we don't check inactive_user_balance here because this is out of our control and the
    // spend key is recorded as a part of the Table key.

    assert!(
        option::some(dwallet_id) != contract.active_dwallet_id && contract.storage.exist(dwallet_id),
        EInvalidDepositKey,
    );
    assert!(contract.storage.dwallet_metadata(dwallet_id).total_deposit() == 0, EBalanceNotEmpty);
    contract.storage.remove(dwallet_id);
}

public(package) fun add_utxo_to_contract(
    contract: &mut NbtcContract,
    tx_id: vector<u8>,
    vout: u32,
    value: u64,
    spend_key: vector<u8>,
    dwallet_id: ID,
) {
    let utxo_idx = contract.next_utxo;
    let utxo = nbtc_utxo::new_utxo(tx_id, vout, value, spend_key, dwallet_id);
    contract.utxos.add(utxo_idx, utxo);
    contract.next_utxo = contract.next_utxo + 1;
}

/// Remove a UTXO from the contract
public fun remove_utxo(_: &AdminCap, contract: &mut NbtcContract, utxo_idx: u64) {
    contract.utxos.remove(utxo_idx);
}

//
// View functions
//

public fun total_supply(contract: &NbtcContract): u64 {
    coin::total_supply(&contract.cap)
}

public fun redeem_request(contract: &NbtcContract, request_id: u64): &RedeemRequest {
    &contract.redeem_requests[request_id]
}

public fun storage(contract: &NbtcContract): &Storage {
    &contract.storage
}

public fun config(contract: &NbtcContract): &Config {
    &contract.config[VERSION]
}

public fun package_version(): u32 {
    VERSION
}
//
// Testing
//

#[test_only]
public(package) fun init_for_testing(
    bitcoin_lc: address,
    fallback_addr: address,
    nbtc_bitcoin_spend_key: vector<u8>,
    ika_coordinator: ID,
    ctx: &mut TxContext,
): NbtcContract {
    let witness = NBTC {};
    let (contract_cap, metadata) = coin::create_currency<NBTC>(
        witness,
        DECIMALS,
        SYMBOL,
        NAME,
        DESCRIPTION,
        option::some(url::new_unsafe_from_bytes(ICON_URL)),
        ctx,
    );
    transfer::public_freeze_object(metadata);
    let mut contract = NbtcContract {
        id: object::new(ctx),
        version: VERSION,
        cap: contract_cap,
        tx_ids: table::new(ctx),
        config: table::new(ctx),
        utxos: table::new(ctx),
        redeem_requests: table::new(ctx),
        locked: table::new(ctx),
        next_redeem_req: 0,
        next_utxo: 0,
        active_dwallet_id: option::none(),
        fees_collected: balance::zero(),
        redeem_duration: 5*60_000, // 5min
        storage: create_storage(ctx),
    };

    contract
        .config
        .add(VERSION, config::new(bitcoin_lc.to_id(), fallback_addr, 10, ika_coordinator, ctx));
    contract
}

#[test_only]
public fun get_fees_collected(contract: &NbtcContract): u64 {
    contract.fees_collected.value()
}

public fun redeem_duration(contract: &NbtcContract): u64 {
    contract.redeem_duration
}

#[test_only]
public fun add_utxo_for_test(ctr: &mut NbtcContract, idx: u64, utxo: Utxo) {
    ctr.utxos.add(idx, utxo);
}

#[test_only]
public fun create_redeem_request_for_testing(
    contract: &mut NbtcContract,
    request_id: u64,
    redeemer: address,
    recipient_script: vector<u8>,
    amount: u64,
    fee: u64,
    created_at: u64,
    ctx: &mut TxContext,
) {
    let lockscript = contract.active_lockscript();

    let r = redeem_request::new(
        lockscript,
        redeemer,
        recipient_script,
        amount,
        fee,
        created_at,
        ctx,
    );
    contract
        .redeem_requests
        .add(
            request_id,
            r,
        )
}

#[test_only]
public fun admin_cap_for_testing(ctx: &mut TxContext): AdminCap {
    AdminCap {
        id: object::new(ctx),
    }
}

#[test_only]
public fun redeem_request_mut(contract: &mut NbtcContract, request_id: u64): &mut RedeemRequest {
    &mut contract.redeem_requests[request_id]
}

#[test_only]
public fun set_dwallet_cap_for_test(
    contract: &mut NbtcContract,
    spend_script: vector<u8>,
    public_key: vector<u8>,
    nbtc_endpoint_user_share: vector<u8>,
    dwallet_cap: DWalletCap,
    ctx: &mut TxContext,
) {
    let dmeta = create_dwallet_metadata(
        spend_script,
        public_key,
        nbtc_endpoint_user_share,
        ctx,
    );
    let dwallet_id = dwallet_cap.dwallet_id();
    contract.active_dwallet_id = option::some(dwallet_id);
    contract.storage.add_metadata(dwallet_id, dmeta);
    contract.storage.add_dwallet_cap(dwallet_id, dwallet_cap);
}
