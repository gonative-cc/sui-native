import type { StorageModule } from ".";
import type { nBTCContractModule, RedeemRequestModule } from ".";

// Storage types
export type DWalletMetadata = typeof StorageModule.DWalletMetadata.$inferInput;
export type Storage = typeof StorageModule.Storage.$inferInput;

// nBTC contract types
export type NbtcContract = typeof nBTCContractModule.NbtcContract.$inferInput;
export type MintEvent = typeof nBTCContractModule.MintEvent.$inferInput;
export type InactiveDepositEvent = typeof nBTCContractModule.InactiveDepositEvent.$inferInput;
export type OpCap = typeof nBTCContractModule.OpCap.$inferInput;
export type AdminCap = typeof nBTCContractModule.AdminCap.$inferInput;

// Redeem request types
export type RedeemRequest = typeof RedeemRequestModule.RedeemRequest.$inferInput;
export type RedeemStatus = typeof RedeemRequestModule.RedeemStatus.$inferInput;
export type SolvedEvent = typeof RedeemRequestModule.SolvedEvent.$inferInput;
export type RequestSignatureEvent = typeof RedeemRequestModule.RequestSignatureEvent.$inferInput;
