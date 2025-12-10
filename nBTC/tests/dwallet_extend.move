#[test_only]
extend module ika_dwallet_2pc_mpc::coordinator_inner;

public fun dwallet_cap_for_testing(dwallet_id: ID, ctx: &mut TxContext): DWalletCap {
    DWalletCap {
        dwallet_id,
        id: object::new(ctx),
    }
}
