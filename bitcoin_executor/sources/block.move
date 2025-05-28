module bitcoin_executor::block;
use bitcoin_executor::block_header::BlockHeader;
use bitcoin_executor::tx::Transaction;

public struct Block {
    block_header: BlockHeader,
    transactions: vector<Transaction>
}
