// SPDX-License-Identifier: MPL-2.0

module bitcoin_spv::light_client;

use bitcoin_parser::header::BlockHeader;
use bitcoin_spv::block_header::{calc_work, pow_check, target};
use bitcoin_spv::btc_math::target_to_bits;
use bitcoin_spv::light_block::{LightBlock, new_light_block};
use bitcoin_spv::merkle_tree::verify_merkle_proof;
use bitcoin_spv::params::{Self, Params, is_correct_init_height};
use bitcoin_spv::utils::nth_element;
use sui::event;
use sui::table::{Self, Table};

// alias methods
use fun calc_work as BlockHeader.calc_work;
use fun pow_check as BlockHeader.pow_check;
use fun target as BlockHeader.target;

/// Package version
const VERSION: u32 = 1;

/// === Errors ===
#[error]
const EWrongParentBlock: vector<u8> =
    b"New parent of the new header parent doesn't match the expected parent block hash";
#[error]
const EDifficultyNotMatch: vector<u8> =
    b"The difficulty bits in the header do not match the calculated difficulty";
#[error]
const ETimeTooOld: vector<u8> =
    b"The timestamp of the block is older than the median of the last 11 blocks";
#[error]
const EHeaderListIsEmpty: vector<u8> = b"The provided list of headers is empty";
#[error]
const EBlockNotFound: vector<u8> = b"The specified block could not be found in the light client";
#[error]
const EForkChainWorkTooSmall: vector<u8> =
    b"The proposed fork has less work than the current chain";
#[error]
const EInvalidStartHeight: vector<u8> =
    b"The start height must be a multiple of the retarget period (e.g 2016 for mainnet)";
#[error]
const EVersionMismatch: vector<u8> = b"The package has been updated. You are using a wrong version";
#[error]
const EAlreadyUpdated: vector<u8> =
    b"The package version has been already updated to the latest one";

public struct NewLightClientEvent has copy, drop {
    light_client_id: ID,
}

public struct InsertedHeadersEvent has copy, drop {
    chain_work: u256,
    is_forked: bool,
    head_hash: vector<u8>,
    head_height: u64,
}

public struct ForkBeyondFinalityEvent has copy, drop {
    parent_hash: vector<u8>,
    parent_height: u64,
}

public struct LightClient has key, store {
    id: UID,
    version: u32,
    params: Params,
    head_height: u64,
    head_hash: vector<u8>,
    light_block_by_hash: Table<vector<u8>, LightBlock>,
    block_hash_by_height: Table<u64, vector<u8>>,
    confirmation_depth: u64,
}

// === Init function for module ====

fun init(_ctx: &mut TxContext) {}

/// LightClient constructor. Create light client and verify data.
/// *params: Btc network params. Check the params module
/// *start_height: height of the first trusted header
/// *trusted_headers: List of trusted headers in hex format.
/// *parent_chain_work: chain_work at parent block of start_height block.
/// *confirmation_depth: the depth from which a block is considered `confirmed`.

public fun new_light_client(
    params: Params,
    start_height: u64,
    trusted_headers: vector<BlockHeader>,
    parent_chain_work: u256,
    confirmation_depth: u64,
    ctx: &mut TxContext,
): LightClient {
    let mut lc = LightClient {
        id: object::new(ctx),
        version: VERSION,
        params: params,
        head_height: 0,
        head_hash: vector[],
        light_block_by_hash: table::new(ctx),
        block_hash_by_height: table::new(ctx),
        confirmation_depth,
    };

    let mut parent_chain_work = parent_chain_work;
    if (!trusted_headers.is_empty()) {
        let mut height = start_height;
        let mut head_hash = vector[];
        trusted_headers.do!(|header| {
            head_hash = header.block_hash();
            let current_chain_work = parent_chain_work + header.calc_work();
            let light_block = new_light_block(height, header, current_chain_work);
            lc.set_block_hash_by_height(height, head_hash);
            lc.insert_light_block(light_block);
            height = height + 1;
            parent_chain_work = current_chain_work;
        });

        lc.head_height = height - 1;
        lc.head_hash = head_hash;
    };

    lc
}

/// Initializes Bitcoin light client by providing a trusted snapshot height and header.
/// Use `initialize_light_client` to create and transfer object,
/// emitting an event.
/// network: 0 = mainnet, 1 = testnet, other = regtest
/// start_height: the height of the first trusted header
/// trusted_header: The list of trusted header in hex encode.
/// previous_chain_work: the chain_work at parent block of start_height block
public fun initialize_light_client(
    network: u8,
    start_height: u64,
    trusted_headers: vector<BlockHeader>,
    parent_chain_work: u256,
    confirmation_depth: u64,
    ctx: &mut TxContext,
) {
    let params = match (network) {
        0 => params::mainnet(),
        1 => params::testnet(),
        _ => params::regtest(),
    };

    assert!(params.is_correct_init_height(start_height), EInvalidStartHeight);

    let lc = new_light_client(
        params,
        start_height,
        trusted_headers,
        parent_chain_work,
        confirmation_depth,
        ctx,
    );
    event::emit(NewLightClientEvent {
        light_client_id: object::id(&lc),
    });
    transfer::share_object(lc);
}

/// Insert new headers to extend the LC chain. Fails if the included headers don't
/// create a heavier chain or fork.
public fun insert_headers(lc: &mut LightClient, headers: vector<BlockHeader>) {
    assert!(lc.version == VERSION, EVersionMismatch);

    assert!(!headers.is_empty(), EHeaderListIsEmpty);

    let first_header = headers[0];
    let head = *lc.head();

    let mut is_forked = false;
    if (first_header.parent() == head.header().block_hash()) {
        // extend current chain
        lc.extend_chain(head, headers);
    } else {
        // handle a new fork
        let parent_id = first_header.parent();
        assert!(lc.exist(parent_id), EBlockNotFound);
        let parent = lc.get_light_block_by_hash(parent_id);
        // NOTE: we can check here if the diff between current head and the parent of
        // the proposed blockcheck is not bigger than the required finality.
        // We decide to not to do it to protect from deadlock:
        // * pro: we protect against double mint for nBTC etc...
        // * cons: we can have a deadlock
        if (parent.height() >= lc.finalized_height()) {
            event::emit(ForkBeyondFinalityEvent {
                parent_hash: parent_id,
                parent_height: parent.height(),
            });
        };

        let current_chain_work = head.chain_work();
        let current_block_hash = head.header().block_hash();

        let fork_head = lc.extend_chain(*parent, headers);
        let fork_chain_work = fork_head.chain_work();

        assert!(current_chain_work < fork_chain_work, EForkChainWorkTooSmall);
        // If transaction not abort. This is the current chain is less power than
        // the fork. We will update the fork to main chain and remove the old fork
        // notes: current_block_hash is hash of the old fork/chain in this case.
        // TODO(vu): Make it more simple.
        lc.cleanup(parent_id, current_block_hash);
        is_forked = true;
    };

    let b = lc.head();
    event::emit(InsertedHeadersEvent {
        chain_work: b.chain_work(),
        is_forked,
        head_hash: lc.head_hash,
        head_height: lc.head_height,
    });
}

public(package) fun insert_light_block(lc: &mut LightClient, lb: LightBlock) {
    let block_hash = lb.header().block_hash();
    lc.light_block_by_hash.add(block_hash, lb);
}

public(package) fun remove_light_block(lc: &mut LightClient, block_hash: vector<u8>) {
    lc.light_block_by_hash.remove(block_hash);
}

/// Maps height to block_hash, overwrites the block_hash (reorg) if height exists in table
public(package) fun set_block_hash_by_height(
    lc: &mut LightClient,
    height: u64,
    block_hash: vector<u8>,
) {
    if (lc.block_hash_by_height.contains(height)) {
        let h_mut = lc.block_hash_by_height.borrow_mut(height);
        *h_mut = block_hash;
    } else {
        lc.block_hash_by_height.add(height, block_hash);
    }
}

/// Appends light block to the current branch and overwrites the current blockchain head.
/// Must only be called when we know that we extend the current branch or if we control
/// the cleanup.
public(package) fun append_block(lc: &mut LightClient, light_block: LightBlock) {
    let head_hash = light_block.header().block_hash();
    lc.insert_light_block(light_block);
    lc.set_block_hash_by_height(light_block.height(), head_hash);
    lc.head_height = light_block.height();
    lc.head_hash = head_hash;
}

/// Insert new header to bitcoin spv
/// * `parent`: hash of the parent block, must be already recorded in the light client.
/// NOTE: this function doesn't do fork checks and overwrites the current fork. So it must be
/// only called internally.
public(package) fun insert_header(
    lc: &mut LightClient,
    parent: &LightBlock,
    header: BlockHeader,
): LightBlock {
    let parent_header = parent.header();

    // verify new header
    // NOTE: we must provide `parent` to the function, to assure we have a chain - subsequent
    // headers must be connected.
    assert!(parent_header.block_hash() == header.parent(), EWrongParentBlock);
    // NOTE: see comment in the skip_difficulty_check function
    if (!lc.params().skip_difficulty_check()) {
        let next_block_difficulty = lc.calc_next_required_difficulty(parent);
        assert!(next_block_difficulty == header.bits(), EDifficultyNotMatch);
    };

    // we only check the case "A timestamp greater than the median time of the last 11 blocks".
    // because  network adjusted time requires a miners local time.
    // https://learnmeabitcoin.com/technical/block/time
    let median_time = lc.calc_past_median_time(parent);
    assert!(header.timestamp() > median_time, ETimeTooOld);
    header.pow_check();

    // update new header
    let next_height = parent.height() + 1;
    let next_chain_work = parent.chain_work() + header.calc_work();
    let next_light_block = new_light_block(next_height, header, next_chain_work);

    lc.append_block(next_light_block);
    next_light_block
}

// TODO: check if we can use reference for parent
/// Extends chain from the given `parent` by inserting new block headers.
/// Returns ID of the last inserted block header.
/// NOTE: we need to pass `parent` block to assure we are creating a chain. Consider the
/// following scenario, where headers that we insert don't form a chain:
///
///    A = {parent: Z}
///    Chain = X-Y-Z  // existing chain
///    headers = [A, A, A]
///
/// the insert would try to insert A multiple times:
///
///    X-Y-Z-A
///        |-A
///        |-A
///
fun extend_chain(
    lc: &mut LightClient,
    parent: LightBlock,
    headers: vector<BlockHeader>,
): LightBlock {
    headers.fold!(parent, |p, header| {
        lc.insert_header(&p, header)
    })
}

/// Delete all blocks between head_hash to checkpoint_hash
public(package) fun cleanup(
    lc: &mut LightClient,
    checkpoint_hash: vector<u8>,
    head_hash: vector<u8>,
) {
    let mut block_hash = head_hash;
    while (checkpoint_hash != block_hash) {
        let previous_block_hash = lc.get_light_block_by_hash(block_hash).header().parent();
        lc.remove_light_block(block_hash);
        block_hash = previous_block_hash;
    }
}

/*
 * Views function
 */

/// Returns height of the blockchain head (latest, not confirmed block).
public fun head_height(lc: &LightClient): u64 {
    assert!(lc.version == VERSION, EVersionMismatch);
    lc.head_height
}

/// Returns height of the blockchain head (latest, not confirmed block).
public fun head_hash(lc: &LightClient): vector<u8> {
    assert!(lc.version == VERSION, EVersionMismatch);
    lc.head_hash
}

/// Returns vector of booleans, where each element corresponds to a block hash
/// from the input vector. `true` if its in the heaviest chain, `false` otherwise.
public fun verify_blocks(lc: &LightClient, block_hashes: vector<vector<u8>>): vector<bool> {
    assert!(lc.version == VERSION, EVersionMismatch);

    block_hashes.map!(|block_hash| {
        if (!lc.light_block_by_hash.contains(block_hash)) {
            false
        } else {
            let light_block = lc.get_light_block_by_hash(block_hash);
            let main_chain_hash_at_height = lc.get_block_hash_by_height(light_block.height());
            block_hash == main_chain_hash_at_height
        }
    })
}

/// Returns blockchain head light block (latest, not confirmed block).
public fun head(lc: &LightClient): &LightBlock {
    assert!(lc.version == VERSION, EVersionMismatch);
    lc.light_block_by_hash.borrow(lc.head_hash)
}

/// Returns latest finalized_block height
public fun finalized_height(lc: &LightClient): u64 {
    assert!(lc.version == VERSION, EVersionMismatch);
    lc.head_height - (lc.confirmation_depth - 1)
}

/// Verify a transaction has tx_id(32 bytes) inclusive in the block has height h.
/// proof is merkle proof for tx_id. This is a sha256(32 bytes) vector.
/// tx_index is index of transaction in block.
/// We use little endian encoding for all data.
public fun verify_tx(
    lc: &LightClient,
    height: u64,
    tx_id: vector<u8>,
    proof: vector<vector<u8>>,
    tx_index: u64,
): bool {
    assert!(lc.version == VERSION, EVersionMismatch);
    // TODO: handle: light block/block_header not exist.
    if (height > lc.finalized_height()) {
        return false
    };
    let block_hash = lc.get_block_hash_by_height(height);
    let header = lc.get_light_block_by_hash(block_hash).header();
    let merkle_root = header.merkle_root();
    verify_merkle_proof(merkle_root, proof, tx_id, tx_index)
}

public fun params(lc: &LightClient): &Params {
    assert!(lc.version == VERSION, EVersionMismatch);
    &lc.params
}

public fun client_id(lc: &LightClient): &UID {
    assert!(lc.version == VERSION, EVersionMismatch);
    &lc.id
}

public fun relative_ancestor(lc: &LightClient, lb: &LightBlock, distance: u64): &LightBlock {
    assert!(lc.version == VERSION, EVersionMismatch);
    let ancestor_height = lb.height() - distance;
    let ancestor_block_hash = lc.get_block_hash_by_height(ancestor_height);
    lc.get_light_block_by_hash(ancestor_block_hash)
}

/// The function calculates the required difficulty for a block that we want to add after
/// the `parent_block` (potentially fork).
public fun calc_next_required_difficulty(lc: &LightClient, parent_block: &LightBlock): u32 {
    assert!(lc.version == VERSION, EVersionMismatch);
    // reference from https://github.com/btcsuite/btcd/blob/master/blockchain/difficulty.go#L136
    let params = lc.params();
    let blocks_pre_retarget = params.blocks_pre_retarget();

    if (params.pow_no_retargeting() || parent_block.height() == 0) {
        return params.power_limit_bits()
    };

    // if this block does not start a new retarget cycle
    if ((parent_block.height() + 1) % blocks_pre_retarget != 0) {
        // Return previous block difficulty
        return parent_block.header().bits()
    };

    // we compute a new difficulty for the new target cycle.
    // this target applies at block  height + 1
    let first_block = lc.relative_ancestor(parent_block, blocks_pre_retarget - 1);
    let first_header = first_block.header();
    let previous_target = first_header.target();
    let first_timestamp = first_header.timestamp() as u64;
    let last_timestamp = parent_block.header().timestamp() as u64;

    let new_target = retarget_algorithm(
        params,
        previous_target,
        first_timestamp,
        last_timestamp,
    );
    let new_bits = target_to_bits(new_target);
    new_bits
}

fun calc_past_median_time(lc: &LightClient, lb: &LightBlock): u32 {
    // Follow implementation from btcsuite/btcd
    // https://github.com/btcsuite/btcd/blob/bc6396ddfd097f93e2eaf0d1346ab80735eaa169/blockchain/blockindex.go#L312
    // https://learnmeabitcoin.com/technical/block/time
    let median_time_blocks = 11;
    let mut timestamps = vector[];
    let mut i = 0;
    let mut prev_lb = lb;
    while (i < median_time_blocks) {
        timestamps.push_back(prev_lb.header().timestamp());
        if (!lc.exist(prev_lb.header().parent())) {
            break
        };
        prev_lb = lc.relative_ancestor(prev_lb, 1);
        i = i + 1;
    };

    let size = timestamps.length();
    nth_element(&mut timestamps, size / 2)
}

public fun get_light_block_by_hash(lc: &LightClient, block_hash: vector<u8>): &LightBlock {
    assert!(lc.version == VERSION, EVersionMismatch);
    lc.light_block_by_hash.borrow(block_hash)
}

public fun exist(lc: &LightClient, block_hash: vector<u8>): bool {
    assert!(lc.version == VERSION, EVersionMismatch);
    lc.light_block_by_hash.contains(block_hash)
}

public fun get_block_hash_by_height(lc: &LightClient, height: u64): vector<u8> {
    assert!(lc.version == VERSION, EVersionMismatch);
    // copy the block hash
    *lc.block_hash_by_height.borrow(height)
}

public fun get_light_block_by_height(lc: &LightClient, height: u64): &LightBlock {
    assert!(lc.version == VERSION, EVersionMismatch);
    let block_hash = lc.get_block_hash_by_height(height);
    lc.get_light_block_by_hash(block_hash)
}

/*
 * Helper function
 */

/// Compute new target
public fun retarget_algorithm(
    p: &Params,
    previous_target: u256,
    first_timestamp: u64,
    last_timestamp: u64,
): u256 {
    let mut adjusted_timespan = last_timestamp - first_timestamp;
    let target_timespan = p.target_timespan();

    // target adjustment is based on the time diff from the target_timestamp. We have max and min value:
    // https://github.com/bitcoin/bitcoin/blob/v28.1/src/pow.cpp#L55
    // https://github.com/btcsuite/btcd/blob/v0.24.2/blockchain/difficulty.go#L184
    let min_timespan = target_timespan / 4;
    let max_timespan = target_timespan * 4;
    if (adjusted_timespan > max_timespan) {
        adjusted_timespan = max_timespan;
    } else if (adjusted_timespan < min_timespan) {
        adjusted_timespan = min_timespan;
    };

    // A trick from summa-tx/bitcoin-spv :D.
    // NB: high targets e.g. ffff0020 can cause overflows here
    // so we divide it by 256**2, then multiply by 256**2 later.
    // we know the target is evenly divisible by 256**2, so this isn't an issue
    // notes: 256*2 = (1 << 16)
    let mut next_target = previous_target / (1 << 16) * (adjusted_timespan as u256);
    next_target = next_target / (target_timespan as u256) * (1 << 16);

    if (next_target > p.power_limit()) {
        next_target = p.power_limit();
    };

    next_target
}

/// Updates the light_client.version to the latest,
/// migrating the object to the latest package version
public fun update_version(lc: &mut LightClient) {
    assert!(VERSION > lc.version, EAlreadyUpdated);
    lc.version = VERSION;
}
