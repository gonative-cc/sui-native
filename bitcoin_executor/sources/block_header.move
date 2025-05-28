module bitcoin_executor::block_header;
use bitcoin_executor::reader;
use std::hash::sha2_256;

public struct BlockHeader has copy, drop{
    version: u32,
    parent: vector<u8>,
    merkle_root: vector<u8>,
    timestamp: u32,
    bits: u32,
    block_hash: vector<u8>
}


public fun new(raw_block_header: vector<u8>): BlockHeader {
    let mut r = reader::new(raw_block_header);
    BlockHeader {
        version: r.read_u32(),
        parent:r.read(32),
        merkle_root: r.read(32),
        timestamp: r.read_u32(),
        bits: r.read_u32(),
        block_hash: sha2_256(sha2_256(raw_block_header))
    }
}
