// SPDX-License-Identifier: MPL-2.0

module nbtc::nbtc;

use bitcoin_lib::reader;
use bitcoin_lib::tx;
use bitcoin_spv::light_client::LightClient;
use ika::ika::IKA;
use ika_dwallet_2pc_mpc::coordinator::DWalletCoordinator;
use ika_dwallet_2pc_mpc::coordinator_inner::{DWalletCap, UnverifiedPresignCap};
use nbtc::config::{Self, Config};
use nbtc::nbtc_utxo::{Self, validate_utxos};
use nbtc::redeem_request::{Self, RedeemRequest};
use nbtc::storage::{Self, Storage, create_storage, create_dwallet};
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

const MINUTE: u64 = 60_000;

/// Coin Metadata
const DECIMALS: u8 = 8;
const SYMBOL: vector<u8> = b"nBTC-v0.3";
const NAME: vector<u8> = b"Native nBTC v0.3";
const DESCRIPTION: vector<u8> = b"Native synthetic BTC";
const ICON_URL: vector<u8> =
    b"https://raw.githubusercontent.com/gonative-cc/sui-native/master/assets/nbtc.svg";

/// ops_arg consts
const MINT_OP_APPLY_FEE: u32 = 1;

//
// Errors
//

#[error]
const EInvalidArguments: vector<u8> = b"Function arguments are not valid";
#[error]
const EInvalidDWallet: vector<u8> = b"Invalid DWallet ID";
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
const ENotReadlyForSign: vector<u8> = b"redeem tx is not ready for signing";
#[error]
const EInputAlreadyUsed: vector<u8> = b"input has been already used";
#[error]
const ERedeemWindowExpired: vector<u8> = b"resolving window has expired";
#[error]
const ENoUTXOsProposed: vector<u8> = b"No UTXOs proposed";
#[error]
const ENotResolving: vector<u8> = b"redeem request is not in resolving status";
#[error]
const EInvalidDWalletCoordinator: vector<u8> = b"Invalid Dwallet coordinator";
#[error]
const ENotSigned: vector<u8> = b"redeem request is not signed";
#[error]
const ERedeemTxNotConfirmed: vector<u8> = b"Bitcoin redeem tx not confirmed via SPV";
#[error]
const EInvalidChangeRecipient: vector<u8> = b"Invalid change recipient";
#[error]
const EInputSignIdLengthMismatch: vector<u8> =
    b"input_ids and sign_ids vectors must have the same length";

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
    config: Config,
    fees_collected: Balance<NBTC>,
    // TODO: probably we should have UTXOs / dwallet
    // redeem request token for nbtc
    redeem_requests: Table<u64, RedeemRequest>,
    // lock nbtc for redeem, this is a mapping from request id to nBTC redeem coin
    locked: Table<u64, Coin<NBTC>>,
    storage: Storage,
    next_redeem_req: u64,
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
    btc_tx_id: vector<u8>,
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

// TODO: consider moving RedeemRequest events to redeem_request.move

public struct RedeemRequestEvent has copy, drop {
    redeem_id: u64,
    redeemer: address,
    recipient_script: vector<u8>, // Full Bitcoin pubkey/lockscript
    amount: u64, // in satoshi
    created_at: u64,
}

public struct RedeemRequestProposeEvent has copy, drop {
    redeem_id: u64,
    utxo_ids: vector<u64>,
}

public struct RedeemSigCreatedEvent has copy, drop {
    redeem_id: u64,
    input_id: u64,
}

public struct RedeemWithdrawReadyEvent has copy, drop {
    redeem_id: u64,
    tx_id: vector<u8>,
    tx_raw: vector<u8>,
}

/// Event emitted when nBTC is burned
public struct BurnEvent has copy, drop {
    redeem_id: u64,
    amount: u64,
    /// Bitcoin withdraw TX ID
    tx_id: vector<u8>,
}

//
// Functions
//

// NOTE: we create a currency using new_currency_with_otw. This is a two-step process.
// We MUST call coin_registry::finalize_registration to place the coin into the registry.
// https://docs.sui.io/standards/currency#coin-finalization
fun init(witness: NBTC, ctx: &mut TxContext) {
    let cfg = config::new(
        @bitcoin_lc.to_id(),
        @fallback_addr,
        10, // mint fee, TODO: increase it
        @ika_coordinator.to_id(),
        2*MINUTE,
    );
    let contract = init__(witness, cfg, ctx);
    transfer::public_share_object(contract);
}

#[allow(lint(self_transfer))]
fun init__(witness: NBTC, config: Config, ctx: &mut TxContext): NbtcContract {
    let (builder, treasury_cap) = coin_registry::new_currency_with_otw(
        witness,
        DECIMALS,
        SYMBOL.to_string(),
        NAME.to_string(),
        DESCRIPTION.to_string(),
        ICON_URL.to_string(),
        ctx,
    );

    let sender = ctx.sender();
    let metadata_cap = builder.finalize(ctx);
    transfer::public_transfer(metadata_cap, sender);
    transfer::transfer(OpCap { id: object::new(ctx) }, sender);
    transfer::transfer(AdminCap { id: object::new(ctx) }, sender);

    NbtcContract {
        id: object::new(ctx),
        version: VERSION,
        config,
        cap: treasury_cap,
        tx_ids: table::new(ctx),
        fees_collected: balance::zero(),
        redeem_requests: table::new<u64, RedeemRequest>(ctx),
        locked: table::new(ctx),
        storage: create_storage(ctx),
        next_redeem_req: 0,
    }
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
    contract.assert_light_client(object::id(light_client));

    let tx = tx::decode(tx_bytes);
    let tx_id = tx.tx_id();

    // Double spend prevent
    assert!(!contract.tx_ids.contains(tx_id), ETxAlreadyUsed);
    contract.tx_ids.add(tx_id, true);
    let lockscript = contract.storage.dwallet(dwallet_id).lockscript();
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
    let mut recipient: address = contract.config.fallback_addr();
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
                recipient = contract.config.fallback_addr();
            }
        }
    };

    // UTXO for each matched output since vouts is a vector now
    let o = tx.outputs();
    let mut utxo_idx = vector[];
    let mut i = 0;
    let dwallet_id = contract.storage.recommended_dwallet().dwallet_id();
    while (i < vouts.length()) {
        let vout_idx = vouts[i];
        let o_amount = o[vout_idx as u64].amount();
        utxo_idx.push_back(contract.storage.utxo_store().next_utxo());
        contract.add_utxo_to_contract(tx_id, vout_idx, o_amount, dwallet_id);
        i = i + 1;
    };

    (amount, recipient, utxo_idx)
}

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
    assert!(contract.version == VERSION, EVersionMismatch);
    let dwallet_id = contract.storage.recommended_dwallet().dwallet_id();
    let (mut amount, recipient, utxo_ids) = contract.verify_deposit(
        light_client,
        dwallet_id,
        tx_bytes,
        proof,
        height,
        tx_index,
        payload,
        ops_arg,
    );
    assert!(amount > 0, EMintAmountIsZero);

    contract.storage.increase_total_deposit(dwallet_id, amount);
    let mut minted = contract.cap.mint_balance(amount);
    let mut fee_amount = 0;

    if (ops_arg == MINT_OP_APPLY_FEE) {
        fee_amount = amount.min(contract.config.mint_fee());
        let fee = minted.split(fee_amount);
        amount = amount - fee_amount;
        contract.fees_collected.join(fee);
    };

    if (amount > 0) transfer::public_transfer(coin::from_balance(minted, ctx), recipient)
    else minted.destroy_zero();

    let utxo = contract.storage.utxo_store().get_utxo(utxo_ids[0]);
    let btc_tx_id = utxo.tx_id();
    let btc_vout = utxo.vout();
    let btc_script_publickey = contract.storage.dwallet(dwallet_id).lockscript();
    event::emit(MintEvent {
        recipient,
        fee: fee_amount,
        dwallet_id,
        utxo_id: utxo_ids[0],
        btc_script_publickey,
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
    contract.assert_light_client(object::id(light_client));
    assert!(!contract.storage().is_inactive(dwallet_id), EInvalidDWallet);

    let deposit_spend_key = contract.storage.dwallet(dwallet_id).lockscript();
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

    contract.storage.increase_user_balance(dwallet_id, recipient, amount);
    event::emit(InactiveDepositEvent {
        bitcoin_spend_key: deposit_spend_key,
        recipient,
        amount,
    });
}

/// Request signing for specific input in a redeem transaction.
///
/// This function will:
/// - Compute the signature hash for the specified input
/// - Request signature from Ika Network
/// - Record the sign_id for later verification
///
/// # Arguments
/// * `contract` - Mutable reference to the nBTC contract
/// * `dwallet_coordinator` - The coordinator for dWallet operations
/// * `redeem_id` - Unique identifier for the redeem request
/// * `input_id` - Index of the Bitcoin input to be signed (0-indexed)
/// * `msg_central_sig` - nBTC public sig share for the Ika MPC process.
/// * `presign` - Capability for unverified presigning operation
/// * `payment_ika` - IKA coin for payment
/// * `payment_sui` - SUI coin for gas fees
/// * `ctx` - Transaction context
///
/// # Aborts
/// * `EInvalidDWalletCoordinator` - If the provided coordinator doesn't match the contract's configured coordinator
/// * `ENotReadlyForSign` - If the redeem request is not in signing state
/// * `EInputAlreadyUsed` - If the input has already been signed
public fun request_utxo_sig(
    contract: &mut NbtcContract,
    dwallet_coordinator: &mut DWalletCoordinator,
    redeem_id: u64,
    input_id: u64,
    msg_central_sig: vector<u8>,
    presign: UnverifiedPresignCap,
    payment_ika: &mut Coin<IKA>,
    payment_sui: &mut Coin<SUI>,
    ctx: &mut TxContext,
) {
    assert!(contract.version == VERSION, EVersionMismatch);
    assert!(
        object::id(dwallet_coordinator) == contract.config.dwallet_coordinator(),
        EInvalidDWalletCoordinator,
    );
    let request = &mut contract.redeem_requests[redeem_id];
    assert!(request.status().is_signing(), ENotReadlyForSign);
    assert!(!request.has_signature(input_id), EInputAlreadyUsed);
    request.request_utxo_sig(
        dwallet_coordinator,
        &contract.storage,
        redeem_id,
        input_id,
        msg_central_sig,
        presign,
        payment_ika,
        payment_sui,
        ctx,
    );
}

/// Requests signature for taproot script path spending.
/// Verifies the leaf script hash is valid in dWallet's merkle tree.
public fun request_utxo_sig_for_tapscript(
    contract: &NbtcContract,
    dwallet_coordinator: &mut DWalletCoordinator,
    redeem_id: u64,
    input_id: u64, // UTXO input index to sign (0-based)
    msg_central_sig: vector<u8>,
    leaf_script_hash: vector<u8>,
    merkle_path: vector<vector<u8>>,
    presign: UnverifiedPresignCap,
    payment_ika: &mut Coin<IKA>,
    payment_sui: &mut Coin<SUI>,
    ctx: &mut TxContext,
) {
    assert!(contract.version == VERSION, EVersionMismatch);
    assert!(
        object::id(dwallet_coordinator) == contract.config.dwallet_coordinator(),
        EInvalidDWalletCoordinator,
    );
    let request = &contract.redeem_requests[redeem_id];
    assert!(request.status().is_signing(), ENotReadlyForSign);
    assert!(!request.has_signature(input_id), EInputAlreadyUsed);
    request.request_utxo_sig_for_tapscript(
        dwallet_coordinator,
        &contract.storage,
        redeem_id,
        input_id,
        msg_central_sig,
        leaf_script_hash,
        merkle_path,
        presign,
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
    fee: u64,
    clock: &Clock,
    ctx: &mut TxContext,
): u64 {
    assert!(contract.version == VERSION, EVersionMismatch);
    // TODO: implement logic to guard burning and manage UTXOs
    // TODO: we can call remove_inactive_spend_key if reserves of this key is zero

    assert!(coin.value() > fee, EInvalidArguments);
    let sender = ctx.sender();
    let lockscript = contract.storage.recommended_dwallet().lockscript();
    let r = redeem_request::new(
        lockscript,
        sender,
        recipient_script,
        coin.value(),
        fee,
        clock.timestamp_ms(),
        ctx,
    );
    let redeem_id = contract.next_redeem_req;
    contract.next_redeem_req = redeem_id + 1;

    event::emit(RedeemRequestEvent {
        redeem_id,
        redeemer: sender,
        recipient_script,
        amount: r.amount(),
        created_at: r.redeem_created_at(),
    });

    contract.redeem_requests.add(redeem_id, r);
    contract.locked.add(redeem_id, coin);

    redeem_id
}

/// Finalizes a redeem request by verifying the Bitcoin transaction via SPV,
/// burning nBTC/UTXOs, and destroying the request.
///
/// Emits BurnEvent containing the Bitcoin transaction ID.
///
/// # Parameters
/// * `contract` - Mutable reference to the nBTC contract
/// * `light_client` - Reference to the light client for SPV verification
/// * `redeem_id` - ID of the redeem request to finalize
/// * `proof` - SPV merkle proof for the Bitcoin transaction
/// * `height` - Block height where the Bitcoin transaction was confirmed
/// * `tx_index` - Index of the transaction within the block
///
/// # Aborts
/// * `EVersionMismatch` - Wrong contract version
/// * `EUntrustedLightClient` - Invalid light client
/// * `sui::table::ENotFound` - Redeem ID does not exist (request already finalized or invalid ID)
/// * `ENotSigned` - Request not yet signed
/// * `ERedeemTxNotConfirmed` - SPV verification failed
/// * `EInvalidChangeRecipient` - Change output wrong address
public fun finalize_redeem(
    contract: &mut NbtcContract,
    light_client: &LightClient,
    redeem_id: u64,
    proof: vector<vector<u8>>,
    height: u64,
    tx_index: u64,
) {
    assert!(contract.version == VERSION, EVersionMismatch);
    contract.assert_light_client(object::id(light_client));
    let btc_dwallet = contract.storage.recommended_dwallet();

    let dwallet_id = btc_dwallet.dwallet_id();
    let lockscript = btc_dwallet.lockscript();

    let mut r = contract.redeem_requests.remove(redeem_id);
    assert!(r.status().is_signed(), ENotSigned);

    let tx_id = r.btc_tx_id();
    assert!(light_client.verify_tx(height, tx_id, proof, tx_index), ERedeemTxNotConfirmed);

    // Burn UTXOs and add a new remainder UTXO
    let spent_utxos_ids = r.utxo_ids();

    spent_utxos_ids.length().do!(|i| {
        nbtc_utxo::unlock_utxo(
            contract.storage.utxo_store_mut(),
            spent_utxos_ids[i],
        );
    });

    r.burn_utxos();

    let coin_to_burn = contract.locked.remove(redeem_id);
    let burn_amount = coin_to_burn.value();
    contract.cap.burn(coin_to_burn);

    let outputs = r.outputs();
    if (outputs.length() > 1) {
        let change_output = &outputs[1];
        assert!(change_output.script_pubkey() == lockscript, EInvalidChangeRecipient);
        let change_utxo = nbtc_utxo::new_utxo(tx_id, 1, change_output.amount(), dwallet_id);
        contract.storage.utxo_store_mut().add(change_utxo);
    };

    r.destroy_confirmed();
    event::emit(BurnEvent {
        redeem_id,
        amount: burn_amount,
        tx_id,
    });
}

/// Batch record multiple signatures for a redeem request in a single tx.
/// Takes a single redeem_id and vectors of input_ids and sign_ids.
/// * `sign_ids` - IKA sign session IDs returned from `request_utxo_sig` calls
/// Emits a RedeemSigCreatedEvent for each newly recorded signature.
/// Emits a RedeemWithdrawReadyEvent when all signatures are recorded.
public fun record_signature(
    contract: &mut NbtcContract,
    dwallet_coordinator: &DWalletCoordinator,
    redeem_id: u64,
    input_ids: vector<u64>,
    sign_ids: vector<ID>,
) {
    assert!(contract.version == VERSION, EVersionMismatch);
    assert!(
        object::id(dwallet_coordinator) == contract.config.dwallet_coordinator(),
        EInvalidDWalletCoordinator,
    );
    assert!(input_ids.length() == sign_ids.length(), EInputSignIdLengthMismatch);

    let r = &mut contract.redeem_requests[redeem_id];

    input_ids.length().do!(|i| {
        let input_id = input_ids[i];
        let no_signature_for_input = !r.has_signature(input_id);

        if (no_signature_for_input) {
            r.record_signature(dwallet_coordinator, input_id, sign_ids[i]);
            event::emit(RedeemSigCreatedEvent {
                redeem_id,
                input_id,
            });
        }
    });

    if (r.status().is_signed()) {
        let tx = r.compose_tx(&contract.storage);
        let tx_raw = tx::serialize_segwit(&tx);
        event::emit(RedeemWithdrawReadyEvent {
            redeem_id,
            tx_id: r.btc_tx_id(),
            tx_raw,
        });
    };
}

// TODO: update event emitted to include the data from the redeem request
// TODO: this is not needed - we decided to merge solved stage with signing stage
//       https://github.com/gonative-cc/workers/issues/266
public fun solve_redeem_request(contract: &mut NbtcContract, redeem_id: u64, clock: &Clock) {
    assert!(contract.version == VERSION, EVersionMismatch);
    let r = &mut contract.redeem_requests[redeem_id];

    // 1. Make sure there is a utxo proposed and we are past the finalization time
    assert!(r.inputs_length() > 0, ENoUTXOsProposed);
    assert!(r.status().is_resolving(), ENotResolving);

    let now = clock.timestamp_ms();
    let deadline = r.redeem_created_at() + contract.config.redeem_duration();
    assert!(now > deadline, ERedeemWindowExpired);

    r.move_to_signing_status(redeem_id, &mut contract.storage);
}

public fun propose_utxos(
    contract: &mut NbtcContract,
    redeem_id: u64,
    utxo_ids: vector<u64>,
    clock: &Clock,
) {
    assert!(contract.version == VERSION, EVersionMismatch);

    let r = &mut contract.redeem_requests[redeem_id];
    assert!(r.status().is_resolving(), ENotResolving);

    // we check the deadline only if we have proposed solution
    if (r.inputs_length() > 0) {
        let now = clock.timestamp_ms();
        let deadline = r.redeem_created_at() + contract.config.redeem_duration();
        assert!(now <= deadline, ERedeemWindowExpired);
    };

    let requested_amount = r.amount();

    contract.storage.utxo_store().validate_utxos(&utxo_ids, requested_amount, redeem_id);

    let old_utxo_ids = r.utxo_ids();
    old_utxo_ids.length().do!(|i| {
        nbtc_utxo::unlock_utxo(
            contract.storage.utxo_store_mut(),
            old_utxo_ids[i],
        );
    });

    utxo_ids.length().do!(|i| {
        nbtc_utxo::lock_utxo(
            contract.storage.utxo_store_mut(),
            utxo_ids[i],
            redeem_id,
        );
    });

    r.set_utxos(utxo_ids);

    event::emit(RedeemRequestProposeEvent {
        redeem_id,
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
    assert!(contract.storage.is_inactive(dwallet_id), EInvalidDWallet);
    let amount = contract.storage.remove_inactive_user_deposit(dwallet_id, ctx.sender());
    let deposit_spend_key = contract.storage.dwallet(dwallet_id).lockscript();
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

/* TODO
/// Merge existing UTXOs to a new, aggregated one assigned to the current active spend key.
/// Used for moving funds from an inactive spend key to an active one.
public fun merge_utxos(_: &mut NbtcContract, _num_utxos: u16) {}
*/

//
// Admin functions
//

public fun update_redeem_duration(_: &OpCap, contract: &mut NbtcContract, redeem_duration: u64) {
    assert!(VERSION == contract.version, EAlreadyUpdated);
    assert!(redeem_duration >= 1000, EInvalidArguments); // at least 1s
    contract.config.set_redeem_duration(redeem_duration);
}

public fun withdraw_fees(_: &OpCap, contract: &mut NbtcContract, ctx: &mut TxContext): Coin<NBTC> {
    assert!(VERSION == contract.version, EAlreadyUpdated);
    coin::from_balance(contract.fees_collected.withdraw_all(), ctx)
}

public fun change_fees(_: &AdminCap, contract: &mut NbtcContract, mint_fee: u64) {
    assert!(contract.version == VERSION, EVersionMismatch);
    contract.config.set_mint_fee(mint_fee);
}

public fun update_config(contract: &mut NbtcContract, _: &AdminCap, config: Config) {
    contract.config = config;
}

/// Registers a new dwallet with it's bitcoin spending script.
/// BTC lockscript must derive from dwallet public key which is control by dwallet_cap.
public fun add_dwallet(
    _: &AdminCap,
    contract: &mut NbtcContract,
    cap: DWalletCap,
    lockscript: vector<u8>,
    control_byte: u8,
    script_merkle_root: vector<u8>,
    user_key_share: vector<u8>,
    ctx: &mut TxContext,
) {
    assert!(contract.version == VERSION, EVersionMismatch);
    // TODO: Verify public key and lockscript
    // In the case lockscript is p2wpkh, p2pkh:
    // - verify public key hash in lock script is compute from public_key
    // Reseach what we should check when lockscript is taproot, p2wsh(p2sh)..

    let dw = create_dwallet(
        cap,
        lockscript,
        control_byte,
        script_merkle_root,
        user_key_share,
        ctx,
    );
    contract.storage.add_dwallet(dw);
}

public fun deactive_dwallet(_: &AdminCap, contract: &mut NbtcContract, dwallet_id: ID) {
    contract.storage.deactive_dwallet(dwallet_id);
}

public(package) fun add_utxo_to_contract(
    contract: &mut NbtcContract,
    tx_id: vector<u8>,
    vout: u32,
    value: u64,
    dwallet_id: ID,
) {
    let utxo = nbtc_utxo::new_utxo(tx_id, vout, value, dwallet_id);
    contract.storage.utxo_store_mut().add(utxo);
}

/// Remove a UTXO from the contract
public fun remove_utxo(_: &AdminCap, contract: &mut NbtcContract, utxo_idx: u64) {
    assert!(contract.version == VERSION, EVersionMismatch);
    contract.storage.utxo_store_mut().remove(utxo_idx).burn();
}

//
// View functions
//

public fun config(contract: &NbtcContract): Config {
    contract.config
}

public fun total_supply(contract: &NbtcContract): u64 {
    coin::total_supply(&contract.cap)
}

public fun redeem_request(contract: &NbtcContract, redeem_id: u64): &RedeemRequest {
    &contract.redeem_requests[redeem_id]
}

public fun storage(contract: &NbtcContract): &Storage {
    &contract.storage
}

public fun package_version(): u32 {
    VERSION
}

//
// Helper functions
//

fun assert_light_client(contract: &NbtcContract, light_client_id: ID) {
    let expected = contract.config.light_client_id();
    assert!(light_client_id == expected, EUntrustedLightClient);
}

//
// Testing
//

#[test_only]
public(package) fun init_for_testing(
    bitcoin_lc: address,
    fallback_addr: address,
    ika_coordinator: ID,
    ctx: &mut TxContext,
): NbtcContract {
    let cfg = config::new(bitcoin_lc.to_id(), fallback_addr, 10, ika_coordinator, 5*MINUTE);
    init__(NBTC {}, cfg, ctx)
}

#[test_only]
public fun get_fees_collected(contract: &NbtcContract): u64 {
    contract.fees_collected.value()
}

#[test_only]
public fun redeem_duration(contract: &NbtcContract): u64 {
    contract.config().redeem_duration()
}

#[test_only]
/// Adds UTXO to the active wallet
public fun add_utxo_for_test(ctr: &mut NbtcContract, _idx: u64, utxo: nbtc_utxo::Utxo) {
    ctr.storage.utxo_store_mut().add(utxo);
}

#[test_only]
public fun borrow_utxo_map_for_test(ctr: &NbtcContract): &nbtc_utxo::UtxoStore {
    ctr.storage.utxo_store()
}

#[test_only]
public fun create_redeem_request_for_testing(
    contract: &mut NbtcContract,
    redeem_id: u64,
    redeemer: address,
    recipient_script: vector<u8>,
    amount: u64,
    fee: u64,
    created_at: u64,
    ctx: &mut TxContext,
) {
    let remainder_lockscript = contract.storage().recommended_dwallet().lockscript();
    let r = redeem_request::new(
        remainder_lockscript,
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
            redeem_id,
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
public fun redeem_request_mut(contract: &mut NbtcContract, redeem_id: u64): &mut RedeemRequest {
    &mut contract.redeem_requests[redeem_id]
}

#[test_only]
public fun testing_mint(contract: &mut NbtcContract, amount: u64, ctx: &mut TxContext): Coin<NBTC> {
    coin::mint(&mut contract.cap, amount, ctx)
}

#[test_only]
public fun set_dwallet_for_test(
    contract: &mut NbtcContract,
    _dwallet_id: ID,
    dw: storage::BtcDWallet,
) {
    contract.storage.add_dwallet(dw);
}

#[test_only]
/// Helper functions to access event fields in tests
public fun get_redeem_sig_created_event_redeem_id(event: &RedeemSigCreatedEvent): u64 {
    event.redeem_id
}

#[test_only]
public fun get_redeem_sig_created_event_input_id(event: &RedeemSigCreatedEvent): u64 {
    event.input_id
}

#[test_only]
public fun get_redeem_withdraw_ready_event_redeem_id(event: &RedeemWithdrawReadyEvent): u64 {
    event.redeem_id
}

#[test_only]
public fun get_redeem_withdraw_ready_event_tx_id(event: &RedeemWithdrawReadyEvent): vector<u8> {
    event.tx_id
}

#[test_only]
public fun get_redeem_withdraw_ready_event_tx_raw(event: &RedeemWithdrawReadyEvent): vector<u8> {
    event.tx_raw
}
