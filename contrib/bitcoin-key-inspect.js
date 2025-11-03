import bip39 from "bip39";
import { BIP32Factory } from "bip32";
import bitcoin from "bitcoinjs-lib";
import * as ecc from "tiny-secp256k1";
import { getProperty } from "./objutil";

// We must wrap a tiny-secp256k1 compatible implementation
const bip32 = BIP32Factory(ecc);

// derivation paths using BIP 44 (derives from BIP 32)
const mainnetBIP32 = {
	p2wpkh: "m/84'/0'/0'/0/0", // segwit
	p2sh: "m/49'/0'/0'/0/0", // nested segwit = p2sh__p2wpkh
	p2tr: "m/86'/0'/0'/0/0", // taproot
	legacy_p2pkh: "m/44'/0'/0'/0/0", // deprecated
};
// NOTE: apparently this is not used - the mainnet is also used in testnet!
// const testnetBIP32 = {
// 	p2wpkh: "m/84'/1'/0'/0/0", // segwit
// 	p2sh: "m/49'/1'/0'/0/0", // nested segwit
// 	p2tr: "m/86'/1'/0'/0/0", // taproot
// 	legacy_p2pkh: "m/44'/1'/0'/0/0", // deprecated
// };

/**
 * @param {Uint8Array} - bytes.
 * @returns {string} - hex string of a hash160 (sha256 + ripmed160).
 */
function hash160Hex(input) {
	let x = bitcoin.crypto.sha256(input);
	x = bitcoin.crypto.ripemd160(x);
	return Buffer.from(x).toString("hex");
}

/**
 * @param {string} mnemonic - one string of 12 mnemonic words separated with spaces.
 * @returns {object} - bitcoinKey.
 */
function keyFromMnemonic(mnemonic, keyType) {
	const seed = bip39.mnemonicToSeedSync(mnemonic);
	const rootKey = bip32.fromSeed(seed);

	const path = getProperty(keyType, mainnetBIP32, "key type");

	return rootKey.derivePath(path);
}

/**
 * Converts a BIP32 extended private key to a P2WPKH (Pay-to-Witness-Public-Key-Hash) address.
 *
 * @param {object} bitcoinKey - A BitcoinKey BIP32 object.
 * @returns {string | null} - The P2WPKH address, or null on error.
 */
function keyToP2WPKHAddress(bitcoinKey, keyConfig) {
	const paymentConstructor = getProperty(keyConfig.typ, bitcoin.payments, "key type");
	const n = getProperty(keyConfig.network, bitcoin.networks, "key type");

	const p = paymentConstructor({
		pubkey: Buffer.from(bitcoinKey.publicKey),
		network: n,
	});

	if (!p.address) {
		console.error("Failed to generate P2WPKH address.");
		return null;
	}

	return p.address;
}

//
// Playground
//

let keyConfig = {
	network: "testnet", // "bitcoin" | "testnet" | "regtest"
	typ: "p2wpkh", // "p2wpkh" | "p2sh" | "p2tr" | "legacy_p2pkh"
};

let mnemonic =
	"abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";

let key = keyFromMnemonic(mnemonic, keyConfig.typ);

// Wallet Import Format - a format for private key containing:
// version, key, compression byte and checksum
console.log("Bitcoin Private Key (WIF):", key.toWIF());
console.log("Bitcoin Private Key (hex):", Buffer.from(key.privateKey).toString("hex"));
console.log("Bitcoin Public Key (hex):", Buffer.from(key.publicKey).toString("hex"));
// this is probably what we need in the move transaction
console.log("Bitcoin Public Key hash160 (hex):", hash160Hex(key.publicKey));
console.log("P2WPKH testnet address", keyToP2WPKHAddress(key, keyConfig));
