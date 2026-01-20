#[test_only]
extend module ika_dwallet_2pc_mpc::coordinator;

use ika_dwallet_2pc_mpc::coordinator_inner::{
    dwallet_coordinator_internal,
    set_signature_for_testing as set_signature_in_inner,
    add_dwallet_for_testing as add_dwallet_to_inner,
    add_sign_session_for_testing as add_sign_session_to_inner
};

#[test_only]
/// Returns inner mutable reference without version check
/// For testing purposes only - bypasses version assertion
public fun inner_mut_unchecked(self: &mut DWalletCoordinator): &mut DWalletCoordinatorInner {
    dynamic_field::borrow_mut(&mut self.id, VERSION)
}

#[test_only]
public fun set_signature_for_testing(
    self: &mut DWalletCoordinator,
    dwallet_id: ID,
    sign_id: ID,
    signature: vector<u8>,
) {
    let inner = self.inner_mut_unchecked();
    set_signature_in_inner(inner, dwallet_id, sign_id, signature);
}

#[test_only]
public fun add_dwallet_for_testing(
    self: &mut DWalletCoordinator,
    dwallet_id: ID,
    dwallet_cap_id: ID,
    curve: u32,
    public_output: vector<u8>,
    ctx: &mut TxContext,
) {
    let inner = self.inner_mut_unchecked();
    add_dwallet_to_inner(inner, dwallet_id, dwallet_cap_id, curve, public_output, ctx);
}

#[test_only]
public fun add_sign_session_for_testing(
    self: &mut DWalletCoordinator,
    dwallet_id: ID,
    sign_id: ID,
    ctx: &mut TxContext,
) {
    let inner = self.inner_mut_unchecked();
    add_sign_session_to_inner(inner, dwallet_id, sign_id, ctx);
}

#[test_only]
public fun coordinator_for_test(
    ctx: &mut TxContext,
    dwallet_coordinator_inner: DWalletCoordinatorInner,
): DWalletCoordinator {
    let mut self = DWalletCoordinator {
        id: object::new(ctx),
        version: 0,
        package_id: object::id_from_address(@0x0789),
        new_package_id: option::none(),
        migration_epoch: option::none(),
    };
    dynamic_field::add(&mut self.id, VERSION, dwallet_coordinator_inner);
    self
}
