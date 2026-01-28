#[test_only]
extend module ika_dwallet_2pc_mpc::coordinator_inner;

use ika_dwallet_2pc_mpc::pricing;

public fun dwallet_coordinator_internal(ctx: &mut TxContext): DWalletCoordinatorInner {
    let pricing = pricing::empty();
    let mut inner = DWalletCoordinatorInner {
        current_epoch: 0,
        sessions_manager: sessions_manager::create(ctx),
        dwallets: object_table::new(ctx),
        dwallet_network_encryption_keys: object_table::new(ctx),
        epoch_dwallet_network_encryption_keys_reconfiguration_completed: 0,
        encryption_keys: object_table::new(ctx),
        presign_sessions: object_table::new(ctx),
        partial_centralized_signed_messages: object_table::new(ctx),
        pricing_and_fee_manager: pricing_and_fee_manager::create(pricing, ctx),
        active_committee: bls_committee::empty(),
        next_epoch_active_committee: option::none(),
        total_messages_processed: 0,
        last_processed_checkpoint_sequence_number: 0,
        previous_epoch_last_checkpoint_sequence_number: 0,
        support_config: support_config::create(
            vec_map::empty(),
        ),
        received_end_of_publish: true,
        extra_fields: bag::new(ctx),
    };
    inner
}

public fun set_signature_for_testing(
    inner: &mut DWalletCoordinatorInner,
    dwallet_id: ID,
    sign_id: ID,
    signature: vector<u8>,
) {
    let (dwallet, _) = inner.get_active_dwallet_and_public_output_mut(dwallet_id);
    let sign = dwallet.sign_sessions.borrow_mut(sign_id);
    sign.state = SignState::Completed { signature };
}

public fun add_dwallet_for_testing(
    inner: &mut DWalletCoordinatorInner,
    dwallet_id: ID,
    dwallet_cap_id: ID,
    curve: u32,
    public_output: vector<u8>,
    ctx: &mut TxContext,
) {
    let dwallet = DWallet {
        id: object::new(ctx),
        created_at_epoch: 0,
        curve,
        public_user_secret_key_share: option::none(),
        dwallet_cap_id,
        dwallet_network_encryption_key_id: object::id_from_address(@0x0),
        is_imported_key_dwallet: false,
        encrypted_user_secret_key_shares: object_table::new(ctx),
        sign_sessions: object_table::new(ctx),
        state: DWalletState::Active { public_output },
    };
    inner.dwallets.add(dwallet_id, dwallet);
}

public fun add_sign_session_for_testing(
    inner: &mut DWalletCoordinatorInner,
    dwallet_id: ID,
    sign_id: ID,
    ctx: &mut TxContext,
) {
    let (dwallet, _) = inner.get_active_dwallet_and_public_output_mut(dwallet_id);
    let sign_session = SignSession {
        id: object::new(ctx),
        created_at_epoch: 0,
        dwallet_id,
        state: SignState::Requested,
    };
    dwallet.sign_sessions.add(sign_id, sign_session);
}
