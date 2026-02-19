import { spawnSync } from "node:child_process";

export class BitcoinCli {
	private readonly cliPath = "/srv/explorer/bitcoin-27.2/bin/bitcoin-cli";
	private readonly docker = "docker";
	private readonly container = "esplora-regtest";
	private readonly baseArgs = [
		"exec",
		this.container,
		this.cliPath,
		"-regtest",
		"-datadir=/data/bitcoin",
	];

	run(command: string, ...params: string[]): string {
		const result = spawnSync(
			this.docker,
			[...this.baseArgs, command, ...params],
			{ encoding: "utf-8" },
		);

		if (result.status !== 0) {
			throw new Error(
				`bitcoin-cli ${command} failed (exit ${result.status}):\n${result.stderr}`,
			);
		}

		return result.stdout.trim();
	}

	getnewaddress(): string {
		return this.run("getnewaddress");
	}

	generatetoaddress(blocks: number, address: string): void {
		this.run("generatetoaddress", blocks.toString(), address);
	}

	getnetworkinfo(): any {
		return JSON.parse(this.run("getnetworkinfo"));
	}

	createrawtransaction(inputs: any[], outputs: any): string {
		return this.run(
			"createrawtransaction",
			JSON.stringify(inputs),
			JSON.stringify(outputs),
		);
	}

	signrawtransactionwithwallet(hex: string): { hex: string; complete: boolean } {
		const result = this.run("signrawtransactionwithwallet", hex);
		return JSON.parse(result);
	}

	sendrawtransaction(hex: string): string {
		return this.run("sendrawtransaction", hex);
	}

	loadwallet(name: string): void {
		try {
			this.run("loadwallet", name);
		} catch (e: any) {
			// Wallet already loaded or doesn't exist - ignore
		}
	}

	checkContainer(): boolean {
		const result = spawnSync("docker", [
			"ps",
			"-q",
			"-f",
			`name=${this.container}`,
		], { encoding: "utf-8" });

		return result.stdout.trim() !== "";
	}

	mineBlocks(blocks: number): void {
		this.generatetoaddress(blocks, this.getnewaddress());
	}

	getTx(txid: string): any {
		return JSON.parse(this.run("gettransaction", txid));
	}
}
