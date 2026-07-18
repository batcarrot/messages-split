import Foundation

public enum BalanceEngine {
    /// Net balance per participant in cents.
    /// Positive = others owe them money. Negative = they owe money.
    public static func netBalances(for ledger: GroupLedger) -> [String: Int] {
        var balances: [String: Int] = Dictionary(
            uniqueKeysWithValues: ledger.participants.map { ($0.id, 0) }
        )

        for expense in ledger.expenses {
            balances[expense.paidById, default: 0] += expense.amountCents
            for share in expense.shares {
                balances[share.participantId, default: 0] -= share.amountCents
            }
        }

        return balances
    }

    /// Greedy debt simplification: fewest transfers that settle all nets.
    public static func simplifiedDebts(for ledger: GroupLedger) -> [Settlement] {
        let nets = netBalances(for: ledger)
        var debtors: [(String, Int)] = []
        var creditors: [(String, Int)] = []

        for (id, cents) in nets {
            if cents < 0 {
                debtors.append((id, -cents))
            } else if cents > 0 {
                creditors.append((id, cents))
            }
        }

        debtors.sort { $0.1 > $1.1 }
        creditors.sort { $0.1 > $1.1 }

        var settlements: [Settlement] = []
        var i = 0
        var j = 0

        while i < debtors.count && j < creditors.count {
            let pay = min(debtors[i].1, creditors[j].1)
            if pay > 0 {
                settlements.append(
                    Settlement(fromId: debtors[i].0, toId: creditors[j].0, amountCents: pay)
                )
            }
            debtors[i].1 -= pay
            creditors[j].1 -= pay
            if debtors[i].1 == 0 { i += 1 }
            if creditors[j].1 == 0 { j += 1 }
        }

        return settlements
    }

    /// Balance of `viewerId` relative to the group (positive = they are owed).
    public static func personalBalance(viewerId: String, ledger: GroupLedger) -> Int {
        netBalances(for: ledger)[viewerId] ?? 0
    }
}
