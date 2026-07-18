#!/usr/bin/env python3
"""Mirror of SplitCore BalanceEngine — runnable without Xcode/Swift."""

from __future__ import annotations

import unittest
from dataclasses import dataclass, field
from typing import Dict, List, Tuple
from uuid import uuid4


def equal_shares(total_cents: int, count: int) -> List[int]:
    assert count > 0
    base, remainder = divmod(total_cents, count)
    return [base + (1 if i < remainder else 0) for i in range(count)]


@dataclass
class ExpenseShare:
    participant_id: str
    amount_cents: int


@dataclass
class Expense:
    title: str
    amount_cents: int
    paid_by_id: str
    shares: List[ExpenseShare]
    id: str = field(default_factory=lambda: str(uuid4()))

    @classmethod
    def equal_split(
        cls, title: str, amount_cents: int, paid_by_id: str, participant_ids: List[str]
    ) -> "Expense":
        amounts = equal_shares(amount_cents, len(participant_ids))
        shares = [
            ExpenseShare(pid, amt) for pid, amt in zip(participant_ids, amounts)
        ]
        return cls(title, amount_cents, paid_by_id, shares)


@dataclass
class Ledger:
    participants: List[str]
    expenses: List[Expense] = field(default_factory=list)


def net_balances(ledger: Ledger) -> Dict[str, int]:
    balances = {pid: 0 for pid in ledger.participants}
    for expense in ledger.expenses:
        balances[expense.paid_by_id] = balances.get(expense.paid_by_id, 0) + expense.amount_cents
        for share in expense.shares:
            balances[share.participant_id] = (
                balances.get(share.participant_id, 0) - share.amount_cents
            )
    return balances


def simplified_debts(ledger: Ledger) -> List[Tuple[str, str, int]]:
    nets = net_balances(ledger)
    debtors = sorted(
        [(pid, -cents) for pid, cents in nets.items() if cents < 0],
        key=lambda x: x[1],
        reverse=True,
    )
    creditors = sorted(
        [(pid, cents) for pid, cents in nets.items() if cents > 0],
        key=lambda x: x[1],
        reverse=True,
    )
    settlements: List[Tuple[str, str, int]] = []
    i = j = 0
    while i < len(debtors) and j < len(creditors):
        pay = min(debtors[i][1], creditors[j][1])
        if pay > 0:
            settlements.append((debtors[i][0], creditors[j][0], pay))
        debtors[i] = (debtors[i][0], debtors[i][1] - pay)
        creditors[j] = (creditors[j][0], creditors[j][1] - pay)
        if debtors[i][1] == 0:
            i += 1
        if creditors[j][1] == 0:
            j += 1
    return settlements


class SplitLogicTests(unittest.TestCase):
    def test_equal_shares_remainder(self):
        self.assertEqual(equal_shares(100, 3), [34, 33, 33])
        self.assertEqual(equal_shares(10, 2), [5, 5])
        self.assertEqual(equal_shares(1, 2), [1, 0])

    def test_dinner_split(self):
        ledger = Ledger(
            participants=["a", "b", "c"],
            expenses=[
                Expense.equal_split("Dinner", 9000, "a", ["a", "b", "c"]),
            ],
        )
        nets = net_balances(ledger)
        self.assertEqual(nets["a"], 6000)
        self.assertEqual(nets["b"], -3000)
        self.assertEqual(nets["c"], -3000)
        debts = simplified_debts(ledger)
        self.assertEqual(len(debts), 2)
        self.assertEqual(sum(d[2] for d in debts), 6000)
        self.assertTrue(all(d[1] == "a" for d in debts))

    def test_partial_settle(self):
        ledger = Ledger(
            participants=["a", "b"],
            expenses=[
                Expense.equal_split("Taxi", 4000, "a", ["a", "b"]),
                Expense.equal_split("Coffee", 1000, "b", ["a", "b"]),
            ],
        )
        self.assertEqual(net_balances(ledger), {"a": 1500, "b": -1500})
        self.assertEqual(simplified_debts(ledger), [("b", "a", 1500)])

    def test_shares_sum_to_total(self):
        for total in (1, 2, 3, 99, 100, 101, 9999):
            for count in range(1, 8):
                shares = equal_shares(total, count)
                self.assertEqual(sum(shares), total, f"{total}/{count}")


if __name__ == "__main__":
    unittest.main()
