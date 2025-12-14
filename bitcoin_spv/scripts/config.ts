// Configuration for Bitcoin SPV Light Client
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";

export interface LightClientConfig {
	spvPackageId: string;
	bitcoinLibPackageId: string;
	network: string;
	headers: string[];
	btcNetwork: number;
	btcHeight: number;
	parentChainWork: string;
	confirmationDepth: number;
}

export interface AppConfig extends LightClientConfig {
	signer: Ed25519Keypair;
}

// Validate Bitcoin block headers
function validateHeaders(headers: string[]): string[] {
	for (const header of headers) {
		if (!header.startsWith("0x")) {
			throw new Error(`Header must start with 0x: ${header.substring(0, 20)}...`);
		}
		if (header.slice(2).length !== 160) {
			throw new Error(`Header must be 80 bytes (160 hex chars): ${header.substring(0, 20)}...`);
		}
	}
	return headers;
}

export function getLightClientConfig(): LightClientConfig {
	// TODO: Replace these values with your actual configuration
	const config = {
		spvPackageId: "0x0",           // Replace with your SPV package ID
		bitcoinLibPackageId: "0x1",      // Replace with your bitcoin_lib package ID
		network: "testnet",              // Sui network: mainnet/testnet/devnet/localnet
		headers: [                       // Replace with your trusted Bitcoin headers (at least 11 blocks)
			"0x0100000000000000000000000000000000000000000000000000000000000000000000000003ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4adae5494dffff7f2002000000",
			"0x0000002006226e46111a0b59caaf126043eb5bbf28c34f3a5e332a1fc7b2b73cf188910ffb0dd614054da3af7d91122635cdb36b7eeeca85e967648911fdbdf2b51702bd1c5db868ffff7f2001000000",
			"0x0000002004a846cb2d72dfa89452886f2f699933872665ef45bf9c928f0c8128dbea4a00b8ce629fe8c24b559585f477612ba4178da25f301ce6fd00a6de438c0cc068441f5db868ffff7f2001000000",
			"0x000000201832558c8d45b9d57a0d4f248942b3e61e3e6a4b1d0645dba44d2b90e5bfcd6219150aeb47d81d59754d6a3f2d3d60f33454a3346fe0fa5262ade3098780f619225db868ffff7f2000000000",
			"0x0000002073c0756ad6c4b2f5fd92f8a2922a13ab2c4a4905d4536258a602da83fd1f4750aabcd7116f304e8a4b929c6030bffab8e422e2b00ea63257366581f637b8c748245db868ffff7f2002000000",
			"0x00000020572bc0f876f3708a52fa2a70f6478ecee12bb420be522a773948eead8e3f68541f4285a84140a5346811719ff015f1b005a19dc34db5ce56882b8e1130ddda6c275db868ffff7f2004000000",
			"0x0000002057b6a06de227d6084ce106903f3d3a2bb2210f0805c15ce19e5670186329391c8787159b37cb999ef13a0cd55309439121f5cbff56d5f6b29e042d8632310fa62b5db868ffff7f2006000000",
			"0x00000020064ec14f185e3c5ff2d71121d316c4a26e2e4c2d2a083b0bfa67358ad475502dceb32eda73f0192b026d7d5ee3737a460844f077e41771b5524ddb69fa6fb17c355db868ffff7f2000000000",
			"0x00000020e11b10fa5be38b4188ced63df62e1f3577e94860b8ba751472d0ce14af8faa66c3223d1be5162187e073b257a5ec36810a3a77d508e0f2f9e17fb6171bfc0406385db868ffff7f2002000000",
			"0x000000200f9b470ee338a358a0dca13cd0673c544d4ef25eec1f739795f0de102e5bc802e23a6dd12b577f3ee638cde2f2995b9a35db5c8b3bff54e61b101a4ed3955d83395db868ffff7f2000000000",
			"0x0000002024bc9c53032d0aa6c709c66db034f45cd3b5567bf05a6a85a476efd97d46d02033dc1b309b065dea0e8542aadc0866f147a2b59c07470e1973877a01552e3f2f3c5db868ffff7f2002000000"
		],
		btcNetwork: 2,                   // Bitcoin network: 0=mainnet, 1=testnet, 2=regtest
		btcHeight: 0,                   // Starting block height
		parentChainWork: "0",            // Initial parent chain work
		confirmationDepth: 3              // Required confirmations
	};
	
	return {
		...config,
		headers: validateHeaders(config.headers)
	};
}