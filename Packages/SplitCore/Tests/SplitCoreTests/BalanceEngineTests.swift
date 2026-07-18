import XCTest
@testable import SplitCore

final class BalanceEngineTests: XCTestCase {
    func testEqualSharesDistributeRemainder() {
        XCTAssertEqual(MoneySplitter.equalShares(totalCents: 100, count: 3), [34, 33, 33])
        XCTAssertEqual(MoneySplitter.equalShares(totalCents: 10, count: 2), [5, 5])
        XCTAssertEqual(MoneySplitter.equalShares(totalCents: 1, count: 2), [1, 0])
    }

    func testNetBalancesForSimpleDinner() {
        var ledger = GroupLedger(
            groupId: "chat-1",
            participants: [
                Participant(id: "a", displayName: "Alex"),
                Participant(id: "b", displayName: "Blake"),
                Participant(id: "c", displayName: "Casey")
            ]
        )
        ledger.addExpense(
            .equalSplit(
                title: "Dinner",
                amountCents: 9000,
                paidById: "a",
                participantIds: ["a", "b", "c"]
            )
        )

        let nets = BalanceEngine.netBalances(for: ledger)
        XCTAssertEqual(nets["a"], 6000)
        XCTAssertEqual(nets["b"], -3000)
        XCTAssertEqual(nets["c"], -3000)
    }

    func testSimplifiedDebts() {
        var ledger = GroupLedger(
            groupId: "chat-1",
            participants: [
                Participant(id: "a", displayName: "Alex"),
                Participant(id: "b", displayName: "Blake"),
                Participant(id: "c", displayName: "Casey")
            ]
        )
        ledger.addExpense(
            .equalSplit(
                title: "Dinner",
                amountCents: 9000,
                paidById: "a",
                participantIds: ["a", "b", "c"]
            )
        )

        let debts = BalanceEngine.simplifiedDebts(for: ledger)
        XCTAssertEqual(debts.count, 2)
        XCTAssertEqual(Set(debts.map(\.toId)), Set(["a"]))
        XCTAssertEqual(debts.map(\.amountCents).reduce(0, +), 6000)
    }

    func testMultipleExpensesSettlePartially() {
        var ledger = GroupLedger(
            groupId: "chat-1",
            participants: [
                Participant(id: "a", displayName: "Alex"),
                Participant(id: "b", displayName: "Blake")
            ]
        )
        ledger.addExpense(
            .equalSplit(title: "Taxi", amountCents: 4000, paidById: "a", participantIds: ["a", "b"])
        )
        ledger.addExpense(
            .equalSplit(title: "Coffee", amountCents: 1000, paidById: "b", participantIds: ["a", "b"])
        )

        let nets = BalanceEngine.netBalances(for: ledger)
        // a paid 40, owes 20+5 = 25 → net +15
        // b paid 10, owes 20+5 = 25 → net -15
        XCTAssertEqual(nets["a"], 1500)
        XCTAssertEqual(nets["b"], -1500)

        let debts = BalanceEngine.simplifiedDebts(for: ledger)
        XCTAssertEqual(debts, [Settlement(fromId: "b", toId: "a", amountCents: 1500)])
    }

    func testMessagePayloadRoundTrip() throws {
        var ledger = GroupLedger(
            groupId: "chat-1",
            participants: [Participant(id: "a", displayName: "Alex")]
        )
        let expense = Expense.equalSplit(
            title: "Snacks",
            amountCents: 500,
            paidById: "a",
            participantIds: ["a"]
        )
        ledger.addExpense(expense)

        let payload = MessagePayload(
            ledger: ledger,
            highlightExpenseId: expense.id,
            summary: MessagePayload.makeSummary(ledger: ledger, expense: expense)
        )
        let url = try payload.makeURL()
        let decoded = try MessagePayload.decode(from: url)
        XCTAssertEqual(decoded.ledger.groupId, "chat-1")
        XCTAssertEqual(decoded.ledger.expenses.count, 1)
        XCTAssertEqual(decoded.highlightExpenseId, expense.id)
    }

    func testSettlementClearsDebt() {
        var ledger = GroupLedger(
            groupId: "chat-1",
            participants: [
                Participant(id: "a", displayName: "Alex"),
                Participant(id: "b", displayName: "Blake")
            ]
        )
        ledger.addExpense(
            .equalSplit(title: "Taxi", amountCents: 4000, paidById: "a", participantIds: ["a", "b"])
        )
        ledger.addExpense(
            .settlement(fromId: "b", toId: "a", amountCents: 2000, method: .applePay)
        )

        let nets = BalanceEngine.netBalances(for: ledger)
        XCTAssertEqual(nets["a"], 0)
        XCTAssertEqual(nets["b"], 0)
        XCTAssertTrue(BalanceEngine.simplifiedDebts(for: ledger).isEmpty)
    }

    func testExpenseKeepsOptionalDetailsAndImageFlag() {
        let expense = Expense.equalSplit(
            title: "Brunch",
            details: "Saturday at Lighthouse",
            amountCents: 6000,
            paidById: "a",
            participantIds: ["a", "b"],
            hasImage: true
        )
        XCTAssertEqual(expense.details, "Saturday at Lighthouse")
        XCTAssertTrue(expense.hasImage)
        XCTAssertEqual(expense.shares.count, 2)
    }

    func testLedgerMergeKeepsUniqueExpenses() {
        let store = LedgerStore(defaults: UserDefaults(suiteName: "test.\(UUID().uuidString)")!)
        var local = GroupLedger(groupId: "g", participants: [Participant(id: "a", displayName: "A")])
        let e1 = Expense.equalSplit(title: "One", amountCents: 100, paidById: "a", participantIds: ["a"])
        local.addExpense(e1)
        store.save(local)

        var remote = GroupLedger(groupId: "g", participants: [Participant(id: "b", displayName: "B")])
        remote.updatedAt = Date().addingTimeInterval(10)
        let e2 = Expense.equalSplit(title: "Two", amountCents: 200, paidById: "b", participantIds: ["b"])
        remote.addExpense(e2)

        let merged = store.merge(local: local, incoming: remote)
        XCTAssertEqual(merged.expenses.count, 2)
        XCTAssertEqual(Set(merged.participants.map(\.id)), Set(["a", "b"]))
    }
}
