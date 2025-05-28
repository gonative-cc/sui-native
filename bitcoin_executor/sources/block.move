module bitcoin_executor::block;
use bitcoin_executor::block_header::{BlockHeader, Self};
use bitcoin_executor::tx::{Transaction, Self};
use bitcoin_executor::reader;

public struct Block {
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
