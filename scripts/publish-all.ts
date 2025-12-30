#!/usr/bin/env bun zx
import { $ } from "zx";
import { readFileSync, writeFileSync } from "fs";
import { join } from "path";
import { fileURLToPath } from "url";
import { getNetworkConfig, Network } from "@ika.xyz/sdk";
import * as toml from "smol-toml";

const SCRIPT_DIR = fileURLToPath(new URL(".", import.meta.url));
const PROJECT_ROOT = join(SCRIPT_DIR, "..");

import { getPublishedPackageId } from "./config";

async function getActiveNetwork(): Promise<Network> {
  const output = await $`sui client active-env`.quiet();
  return output.stdout.trim() as Network;
}

function formatDependenciesInline(parsed: any): string {
  let tomlLines: string[] = [];
  let processedDeps = new Set<string>();

  if (parsed.dependencies) {
    tomlLines.push("[dependencies]");
    for (const [name, dep] of Object.entries(parsed.dependencies)) {
      const entries = Object.entries(dep)
        .map(([key, val]: [string, any]) => `${key} = ${typeof val === "string" ? `"${val}"` : val}`)
        .join(", ");
      tomlLines.push(`${name} = { ${entries} }`);
      processedDeps.add(name);
    }
    tomlLines.push("");
  }

  for (const [key, value] of Object.entries(parsed)) {
    if (key === "dependencies") continue;
    if (key.startsWith("dependencies.") && processedDeps.has(key.replace("dependencies.", ""))) continue;

    const section = toml.stringify({ [key]: value }).trim();
    tomlLines.push(section);
    tomlLines.push("");
  }

  return tomlLines.join("\n").trim();
}

function updateIkaCoordinator(network: Network): void {
  const nbtctomlPath = join(PROJECT_ROOT, "nBTC", "Move.toml");
  const config = getNetworkConfig(network);
  const coordinatorId = config.objects.ikaDWalletCoordinator.objectID;

  const parsed = toml.parse(readFileSync(nbtctomlPath, "utf-8")) as any;
  parsed.addresses.ika_coordinator = coordinatorId;

  const tomlString = formatDependenciesInline(parsed);
  writeFileSync(nbtctomlPath, tomlString);
  console.log(`Updated ika_coordinator from SDK: ${coordinatorId}`);
}

async function publishPackage(packageName: string, network: string, force: boolean): Promise<void> {
  if (!force) {
    const publishedId = getPublishedPackageId(packageName, network);
    if (publishedId) {
      console.log(`${packageName} already published at ${publishedId}`);
      return;
    }
  }

  const packagePath = join(PROJECT_ROOT, packageName);
  console.log(`Publishing ${packageName}${force ? " (forced)" : ""}...`);

  if (packageName === "nBTC") {
    updateIkaCoordinator(network as Network);
  }

  $.cwd = packagePath;
  await $`sui move build --skip-fetch-latest-git-deps`;
  await $`sui client publish --gas-budget 1000000000`;
}

const packages = [
  "bitcoin_lib",
  "bitcoin_spv",
  "nBTC",
];

async function main(): Promise<void> {
  const args = process.argv.slice(2);
  const force = args.includes("--redeploy") || args.includes("-f");

  const network = await getActiveNetwork();
  console.log(`Active network: ${network}${force ? " (redeploy all)" : ""}`);

  try {
    for (const pkg of packages) {
      await publishPackage(pkg, network, force);
    }
    console.log("Publishing completed");
  } catch (error) {
    console.error("Publishing failed:", error);
    process.exit(1);
  }
}

main();
