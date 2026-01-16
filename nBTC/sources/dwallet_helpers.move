// SPDX-License-Identifier: MPL-2.0

module nbtc::dwallet_helpers;

use ika_dwallet_2pc_mpc::coordinator::{DWalletCoordinator, register_session_identifier};
use ika_dwallet_2pc_mpc::sessions_manager::SessionIdentifier;

/// Creates a new session identifier for Ika dWallet operations.
///
/// This helper function encapsulates the common pattern of generating
/// random bytes and registering a session identifier with the coordinator.
public(package) fun new_session_identifier(
    coordinator: &mut DWalletCoordinator,
    ctx: &mut TxContext,
): SessionIdentifier {
    let random_bytes = tx_context::fresh_object_address(ctx).to_bytes();
    register_session_identifier(coordinator, random_bytes, ctx)
}
