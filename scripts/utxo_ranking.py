#!/usr/bin/env python3
"""
UTXO Selection Ranking Algorithm 

Criteria:
1. Minimize UTXOs 
2. Avoid creating dust 
3. Prioritize inactive spend keys 
"""

from typing import List
from dataclasses import dataclass
import random


@dataclass
class UTXO:
    tx_id: str
    vout: int
    value: int
    spend_key: str


@dataclass
class UTXOProposal:
    utxos: List[UTXO]
    total_value: int


DUST_THRESHOLD = 10_000
SMALL_CHANGE_THRESHOLD = 100_000


def calculate_rank(proposal: UTXOProposal, withdraw_amount: int, active_key: str, fee: int = 0) -> int:
    num_utxos = len(proposal.utxos)
    total = proposal.total_value
    change = total - (withdraw_amount + fee)

    if change < 0:
        return 0

    rank = 1_000_000

    rank -= num_utxos * 100_000

    if change == 0:
        rank += 50_000  
    elif change < DUST_THRESHOLD:
        rank -= 200_000  
    else:
        rank -= 20_000  

    inactive_count = sum(1 for u in proposal.utxos if u.spend_key != active_key)
    rank += inactive_count * 200_000

    return max(0, rank)


def rank_proposals(proposals: List[UTXOProposal], withdraw_amount: int, active_key: str, fee: int = 0):
    ranked = [(p, calculate_rank(p, withdraw_amount, active_key, fee)) for p in proposals]
    return sorted(ranked, key=lambda x: x[1], reverse=True)


def batch_withdrawals(withdrawals: List[int], available_utxos: List[UTXO], active_key: str) -> UTXOProposal:
    """
    Batch multiple withdrawals into ONE Bitcoin tx.
    Use ONLY for same-time withdrawals.
    """
    total = sum(withdrawals)
    proposals = []

    for utxo in available_utxos:
        if utxo.value >= total:
            proposals.append(UTXOProposal([utxo], utxo.value))

    for i in range(len(available_utxos)):
        for j in range(i + 1, len(available_utxos)):
            val = available_utxos[i].value + available_utxos[j].value
            if val >= total:
                proposals.append(UTXOProposal([available_utxos[i], available_utxos[j]], val))

    if not proposals:
        raise ValueError("Insufficient funds")

    return rank_proposals(proposals, total, active_key)[0][0]


def test_basic():
    print("=" * 70)
    print("BASIC TESTS")
    print("=" * 70)

    active = "active"
    inactive = "inactive"

    print("\n### Test 1: Exact match vs change")
    p1 = UTXOProposal([UTXO("tx1", 0, 60_000_000, active), UTXO("tx2", 0, 40_000_000, active)], 100_000_000)
    p2 = UTXOProposal([UTXO("tx3", 0, 110_000_000, active)], 110_000_000)
    r1 = calculate_rank(p1, 100_000_000, active)
    r2 = calculate_rank(p2, 100_000_000, active)
    print(f"0.6+0.4 (exact): {r1:,}  |  1.1 (change): {r2:,}  →  Winner: {'Exact' if r1 > r2 else 'Change'}")

    print("\n### Test 2: Avoid dust")
    p3 = UTXOProposal([UTXO("tx4", 0, 100_005_000, active)], 100_005_000)
    p4 = UTXOProposal([UTXO("tx5", 0, 150_000_000, active)], 150_000_000)
    r3 = calculate_rank(p3, 100_000_000, active)
    r4 = calculate_rank(p4, 100_000_000, active)
    print(f"Dust (5k): {r3:,}  |  Large change (50M): {r4:,}  →  Winner: {'Dust' if r3 > r4 else 'Large'}")

    print("\n### Test 3: Inactive key priority")
    p5 = UTXOProposal([UTXO("tx6", 0, 60_000_000, active), UTXO("tx7", 0, 40_000_000, active)], 100_000_000)
    p6 = UTXOProposal([UTXO("tx8", 0, 60_000_000, inactive), UTXO("tx9", 0, 40_000_000, inactive)], 100_000_000)
    r5 = calculate_rank(p5, 100_000_000, active)
    r6 = calculate_rank(p6, 100_000_000, active)
    print(f"Active: {r5:,}  |  Inactive: {r6:,}  →  Winner: {'Active' if r5 > r6 else 'Inactive'}")

    print("\n### Test 4: Fee optimization - fewer inputs beats exact match")
    p7 = UTXOProposal([UTXO("tx10", 0, 130_000_000, active)], 130_000_000)  # 1 input + change
    p8 = UTXOProposal([UTXO("tx11", 0, 60_000_000, active), UTXO("tx12", 0, 40_000_000, active)], 100_000_000)  # 2 inputs exact
    r7 = calculate_rank(p7, 100_000_000, active)
    r8 = calculate_rank(p8, 100_000_000, active)
    print(f"1 input + change: {r7:,}  |  2 inputs exact: {r8:,}  →  Winner: {'1 input' if r7 > r8 else '2 inputs'}")

    print("\n### Test 5: High withdrawal (10 BTC) - prefer single UTXO")
    p9 = UTXOProposal([UTXO("tx12", 0, 1_000_000_000, active)], 1_000_000_000)
    p10 = UTXOProposal([UTXO(f"tx{i}", 0, 100_000_000, active) for i in range(10)], 1_000_000_000)
    r9 = calculate_rank(p9, 1_000_000_000, active)
    r10 = calculate_rank(p10, 1_000_000_000, active)
    print(f"1×10 BTC: {r9:,}  |  10×1 BTC: {r10:,}  →  Winner: {'Single' if r9 > r10 else 'Multiple'}")


def test_random():
    print("\n" + "=" * 70)
    print("RANDOM UTXO TESTS")
    print("=" * 70)

    active = "active"
    inactive1 = "inactive1"
    inactive2 = "inactive2"
    all_keys = [active, active, active, inactive1, inactive2]

    random.seed(42)

    for test_num in range(1, 4):
        print(f"\n### Random Test {test_num}")

        withdraw = random.randint(50_000_000, 500_000_000)
        print(f"Withdraw: {withdraw / 100_000_000:.2f} BTC")

        available_utxos = []
        for i in range(random.randint(5, 12)):
            utxo = UTXO(
                f"tx{test_num}_{i}",
                i,
                random.randint(10_000_000, 200_000_000),
                random.choice(all_keys)
            )
            available_utxos.append(utxo)

        print(f"Available: {len(available_utxos)} UTXOs")
        for u in available_utxos:
            key_type = "A" if u.spend_key == active else "I"
            print(f"  [{key_type}] {u.value / 100_000_000:.3f} BTC ({u.spend_key})")

        proposals = []
        for _ in range(5):
            num_pick = random.randint(1, min(4, len(available_utxos)))
            picked = random.sample(available_utxos, num_pick)
            total = sum(u.value for u in picked)
            if total >= withdraw:
                proposals.append(UTXOProposal(picked, total))

        if proposals:
            ranked = rank_proposals(proposals, withdraw, active)
            print(f"\nBest proposal (rank {ranked[0][1]:,}):")
            best = ranked[0][0]
            for u in best.utxos:
                key_type = "A" if u.spend_key == active else "I"
                print(f"  {key_type} {u.value / 100_000_000:.3f} BTC")
            change = best.total_value - withdraw
            print(f"Total: {best.total_value / 100_000_000:.3f} BTC → Change: {change / 100_000_000:.3f} BTC")
        else:
            print("No valid proposals (insufficient funds)")


if __name__ == "__main__":
    test_basic()
    test_random()
    print("\n" + "=" * 70)
