module nbtc::verify;

use bitcoin_spv::light_client::{verify_tx};
use bitcoin_spv::transaction::{op_return, p2pkh_address};