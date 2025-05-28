module bitcoin_executor::block;
use bitcoin_executor::block_header::{BlockHeader, Self};
use bitcoin_executor::tx::{Transaction, Self};
use bitcoin_executor::reader;

public struct Block has copy, drop{
    block_header: BlockHeader,
    transactions: vector<Transaction>
}


public fun new_block(raw_block: vector<u8>): Block {
    let mut r = reader::new(raw_block);
    let block_header = block_header::new(r.read(80));
    let number_tx = r.read_compact_size();
    let mut transactions = vector[];
    number_tx.do!(|_| {
        transactions.push_back(tx::deserialize(&mut r));
    });

    Block {
        block_header,
        transactions
    }
}

#[test]
fun parse_block_test() {
    let data = x"0100000000000000000000000000000000000000000000000000000000000000000000003ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4adae5494dffff7f20020000000101000000010000000000000000000000000000000000000000000000000000000000000000ffffffff4d04ffff001d0104455468652054696d65732030332f4a616e2f32303039204368616e63656c6c6f72206f6e206272696e6b206f66207365636f6e64206261696c6f757420666f722062616e6b73ffffffff0100f2052a01000000434104678afdb0fe5548271967f1a67130b7105cd6a828e03909a67962e0ea1f61deb649f6bc3f4cef38c4f35504e51ec112de5c384df7ba0b8d578a4c702b6bf11d5fac00000000";

    let block = new_block(data);

    std::debug::print(&block);

}
