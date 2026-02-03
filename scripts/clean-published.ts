#!/usr/bin/env bun
import { unlinkSync, existsSync } from "fs";
import { join } from "path";
import { PROJECT_ROOT } from "./utils";

const Packages = ["bitcoin_lib", "bitcoin_spv", "nBTC"];

function main(): Promise<void> {
	const args = process.argv.slice(2);
	const packageArg = args.find((arg) => !arg.startsWith("-"));
	const packagesToClean = packageArg ? [packageArg] : Packages;

	console.log(`Cleaning Published.toml for: ${packagesToClean.join(", ")}`);

	for (const pkg of packagesToClean) {
		if (!Packages.includes(pkg)) {
			console.error(`Unknown package: ${pkg}`);
			continue;
		}

		const publishedTomlPath = join(PROJECT_ROOT, pkg, "Published.toml");

		if (existsSync(publishedTomlPath)) {
			unlinkSync(publishedTomlPath);
			console.log(`✓ Deleted ${pkg}/Published.toml`);
		} else {
			console.log(`- ${pkg}/Published.toml does not exist`);
		}
	}

	console.log("\nDone! You can now republish packages.");
}

if (import.meta.main) {
   main()
}
