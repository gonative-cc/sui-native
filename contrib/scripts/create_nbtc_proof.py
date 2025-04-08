# SPDX-License-Identifier: MPL-2.0

import hashlib
import json
import argparse

def double_sha256(data):
    data_bytes = bytes.fromhex(data)
    return hashlib.sha256(hashlib.sha256(data_bytes).digest()).hexdigest()


def merkle_root(hashes):
    """Computes the Merkle root from a list of hashes using double SHA-256."""
    if len(hashes) == 1:
        return hashes[0]

    # If odd number of hashes, duplicate the last one
    if len(hashes) % 2 != 0:
        hashes.append(hashes[-1])

    # Hash pairs and keep reducing
    new_hashes = []
    for i in range(0, len(hashes), 2):
        combined_hash = double_sha256(hashes[i] + hashes[i + 1])
        new_hashes.append(combined_hash)

    return merkle_root(new_hashes)


def merkle_proof(transaction_hash, all_hashes):
    """Computes the Merkle proof for a specific transaction hash."""
    proof = []

    # Find the position of the transaction in the list of all hashes
    index = all_hashes.index(transaction_hash)

    # Generate the proof by traversing up the tree
    while len(all_hashes) > 1:
        # If the index is even, get the next hash as the sibling
        if index % 2 == 0:
            if index + 1 < len(all_hashes):
                proof.append(all_hashes[index + 1])
            else:
                proof.append(all_hashes[index])  # If odd number, duplicate the last
                # If the index is odd, get the previous hash as the sibling
        else:
            proof.append(all_hashes[index - 1])
        if len(all_hashes) % 2 != 0:
            all_hashes.append(all_hashes[-1])

        # Pair up the hashes and hash them again
        all_hashes = [
            double_sha256(all_hashes[i] + all_hashes[i + 1])
            for i in range(0, len(all_hashes), 2)
        ]
        index = index // 2  # Move up one level in the tree

    return proof


# Example transaction hashes (replace with actual transaction hashes)


def big_endian_to_little_endian(hex_str):
    """Converts a big-endian hex string to little-endian."""
    # Ensure the hex string has an even length, as each byte is 2 characters
    if len(hex_str) % 2 != 0:
        raise ValueError("Hex string must have an even length.")

    # Reverse the order of bytes (pair of hex characters)
    little_endian = "".join(
        [hex_str[i : i + 2] for i in range(0, len(hex_str), 2)][::-1]
    )

    return little_endian


def read_byte_transaction(hex_str):
    tx_data = {
        "version": "",
        "input_count": 0,
        "inputs": "",
        "output_count": 0,
        "outputs": "",
        "lock_time": ""
    }

    i = 4;
    tx_data["version"] = hex_str[:i * 2]

    if (tx_data["version"] == "02000000"):
        i += 2
    
    tx_data["input_count"] = int(hex_str[i * 2: (i + 1) * 2], 16)
    i += 1
    for j in range(tx_data["input_count"]):
        tx_data["inputs"] = tx_data["inputs"] + hex_str[i * 2 : (i + 32 + 4) * 2]
        i += 32 + 4
        
        k = int(hex_str[i * 2: (i + 1) * 2], 16)
        tx_data["inputs"] = tx_data["inputs"] + hex_str[i * 2: (i + 1) * 2]                
        i += 1
        tx_data["inputs"] = tx_data["inputs"] + hex_str[i * 2 : (i + k + 4) * 2]
        i += k + 4

    tx_data["output_count"] = int(hex_str[i * 2: (i + 1) * 2], 16)
    i += 1;

    for j in range(tx_data["output_count"]):
        tx_data["outputs"] = tx_data["outputs"] + hex_str[i * 2 : (i + 8) * 2]
        i += 8
        k = int(hex_str[i * 2: (i + 1) * 2], 16)
        tx_data["outputs"] = tx_data["outputs"] + hex_str[i * 2: (i + 1) * 2]
        i += 1
        tx_data["outputs"] = tx_data["outputs"] + hex_str[i * 2 : (i + k) * 2]
        i += k
    tx_data["lock_time"] = hex_str[-8:]
    
    return tx_data
    
def main():
    parser = argparse.ArgumentParser(description="nBTC prepare data")
    parser.add_argument('block_hash', type=str, help='block hash')
    parser.add_argument('transaction_id', type=str, help='transaction id')
    args = parser.parse_args()
    block_hash = args.block_hash
    transaction_id = args.transaction_id
    with open(
            block_hash+".json"
    ) as file:
        data = json.load(file)
        tx_hashes = data["tx"]
        tx_hashes = list(map(big_endian_to_little_endian, tx_hashes))
        # Compute Merkle root
    merkle_root_hash = merkle_root(tx_hashes)
    print(f"Merkle root: {merkle_root_hash}")

    tx_hash = big_endian_to_little_endian(transaction_id)
    proof = merkle_proof(tx_hash, tx_hashes)
    # print(f"Merkle Proof for {tx_hash}: {proof}")

    proof_with_prefix = [f'x"{hash_value}"' for hash_value in proof]

    print(f"Merkle Proof for {tx_hash}: [{', '.join(proof_with_prefix)}]")
    height = data["height"]
    print(f"Height = {height}")
    with open(
            transaction_id+".json"
    ) as file:
        data = json.load(file)
        tx_hex = data['hex']
        print(read_byte_transaction(tx_hex))
        # Compute Merkle root

    
if __name__ == "__main__":
    main()
