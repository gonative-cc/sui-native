import { createHash } from "crypto";
import { Transaction } from "bitcoinjs-lib";

function sha256(data: Buffer): Buffer {
	return createHash("sha256").update(data).digest();
}

interface MerkleNode {
	hash: Buffer;
	preimage: Buffer;
}

export class BitcoinMerkleTree {
	private tree: MerkleNode[][];
	private readonly root: Buffer;

	constructor(transactions: Transaction[]) {
		if (!transactions || transactions.length === 0) {
			throw new Error("Cannot construct Merkle tree from empty transaction list.");
		}
		const leafNodes: MerkleNode[] = transactions.map((tx) => {
			const txClone = tx.clone();
			txClone.stripWitnesses();
			const legacyBuffer = txClone.toBuffer();
			return {
				hash: Buffer.from(tx.getHash()),
				preimage: sha256(Buffer.from(legacyBuffer)),
			};
		});

		this.tree = [leafNodes];
		this.buildTree();
		const lastLevel = this.tree[this.tree.length - 1];
		if (!lastLevel || lastLevel.length === 0) {
			throw new Error("Merkle tree has no levels or empty last level");
		}
		const firstNode = lastLevel[0];
		if (!firstNode) {
			throw new Error("Merkle tree root node is missing");
		}
		this.root = firstNode.hash;
	}

	private buildTree(): void {
		let currentLevel = this.tree[0];
		if (!currentLevel) {
			throw new Error("Merkle tree has no initial level");
		}
		while (currentLevel.length > 1) {
			const nextLevel: MerkleNode[] = [];

			if (currentLevel.length % 2 === 1) {
				const lastNode = currentLevel[currentLevel.length - 1];
				if (!lastNode) {
					throw new Error(
						"Merkle tree last node is missing when duplicating for odd count",
					);
				}
				currentLevel.push(lastNode);
			}

			for (let i = 0; i < currentLevel.length; i += 2) {
				const left = currentLevel[i];
				const right = currentLevel[i + 1];

				if (!left || !right) {
					throw new Error(
						"Merkle tree has missing left or right node during construction",
					);
				}

				const combined = Buffer.concat([left.hash, right.hash]);
				nextLevel.push({
					hash: sha256(sha256(combined)),
					preimage: sha256(combined),
				});
			}
			currentLevel = nextLevel;
			this.tree.push(currentLevel);
		}
	}

	public getRoot(bigEndian = false): Buffer {
		return bigEndian ? Buffer.from(this.root).reverse() : this.root;
	}

	public getProof(targetTx: Transaction): Buffer[] {
		const proof: Buffer[] = [];
		const targetHash = targetTx.getHash();

		const firstLevel = this.tree[0];
		if (!firstLevel) {
			throw new Error("Merkle tree is empty");
		}
		let targetIndex = firstLevel.findIndex((node) => node.hash.equals(targetHash));
		if (targetIndex === -1) {
			throw new Error("Target leaf not found in the tree.");
		}

		for (let level = 0; level < this.tree.length - 1; level++) {
			const currentLevelNodes = this.tree[level];
			if (!currentLevelNodes) {
				throw new Error("Merkle tree is invalid");
			}
			let siblingIndex: number;

			const isRightNode = targetIndex % 2 === 1;
			const isLastNodeOnLevel = targetIndex === currentLevelNodes.length - 1;
			const levelHasOddNodes = currentLevelNodes.length % 2 === 1;

			if (isLastNodeOnLevel && levelHasOddNodes) {
				siblingIndex = targetIndex;
			} else if (isRightNode) {
				siblingIndex = targetIndex - 1;
			} else {
				siblingIndex = targetIndex + 1;
			}

			const siblingNode = currentLevelNodes[siblingIndex];
			if (!siblingNode) {
				throw new Error("Merkle tree is invalid");
			}
			proof.push(siblingNode.preimage);

			targetIndex = Math.floor(targetIndex / 2);
		}
		return proof;
	}
}
