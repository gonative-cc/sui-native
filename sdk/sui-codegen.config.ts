import type { SuiCodegenConfig } from '@mysten/codegen';

const config: SuiCodegenConfig = {
	output: './src/generated',
	generateSummaries: true,
	prune: true,
	packages: [
		{
			package: '@local-pkg/nbtc',
			path: '../nBTC',
		},
		// Bug codegen can't run correct when contract constant a Transacion struct
		// {
		// 	package: '@local-pkg/bitcoin_spv',
		// 	path: "../bitcoin_spv"
		// },
		// {
		// 	package: '@local-pkg/bitcoin_lib',
		// 	path: "../bitcoin_lib"
		// }
	],
};

export default config;
