import Foundation
import SplitCore
import Messages
import SwiftUI

@MainActor
final class SplitSessionModel: ObservableObject {
    @Published var ledger = GroupLedger(groupId: "empty")
    @Published var localParticipantId = ""
    @Published var presentationStyle: MSMessagesAppPresentationStyle = .compact
    @Published var draftTitle = ""
    @Published var draftAmountText = ""
    @Published var draftPaidById = ""
    @Published var selectedParticipantIds: Set<String> = []
    @Published var errorMessage: String?

    var onSendExpense: ((Expense) -> Void)?
    var onSendBalances: (() -> Void)?
    var onExpand: (() -> Void)?
    var onCompact: (() -> Void)?
    var onLedgerChanged: ((GroupLedger) -> Void)?

    var participants: [Participant] { ledger.participants }

    var netBalances: [String: Int] {
        BalanceEngine.netBalances(for: ledger)
    }

    var settlements: [Settlement] {
        BalanceEngine.simplifiedDebts(for: ledger)
    }

    var personalBalanceCents: Int {
        BalanceEngine.personalBalance(viewerId: localParticipantId, ledger: ledger)
    }

    func configure(
        ledger: GroupLedger,
        localParticipantId: String,
        presentationStyle: MSMessagesAppPresentationStyle
    ) {
        self.ledger = ledger
        self.localParticipantId = localParticipantId
        self.presentationStyle = presentationStyle
        if draftPaidById.isEmpty {
            draftPaidById = localParticipantId
        }
        if selectedParticipantIds.isEmpty {
            selectedParticipantIds = Set(ledger.participants.map(\.id))
        }
    }

    func addExpense(_ expense: Expense) {
        ledger.addExpense(expense)
    }

    func submitExpense() {
        errorMessage = nil
        let cleaned = draftAmountText
            .replacingOccurrences(of: "$", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let amount = Decimal(string: cleaned), amount > 0 else {
            errorMessage = "Enter a valid amount."
            return
        }
        let title = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            errorMessage = "Add a short description."
            return
        }
        guard !selectedParticipantIds.isEmpty else {
            errorMessage = "Pick at least one person to split with."
            return
        }
        guard participants.contains(where: { $0.id == draftPaidById }) else {
            errorMessage = "Choose who paid."
            return
        }

        let money = Money(amount: amount, currencyCode: ledger.currencyCode)
        let orderedIds = participants.map(\.id).filter { selectedParticipantIds.contains($0) }
        let expense = Expense.equalSplit(
            title: title,
            amountCents: money.cents,
            paidById: draftPaidById,
            participantIds: orderedIds,
            currencyCode: ledger.currencyCode
        )
        onSendExpense?(expense)
        draftTitle = ""
        draftAmountText = ""
    }

    func toggleParticipant(_ id: String) {
        if selectedParticipantIds.contains(id) {
            selectedParticipantIds.remove(id)
        } else {
            selectedParticipantIds.insert(id)
        }
    }

    func renameParticipant(id: String, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let index = ledger.participants.firstIndex(where: { $0.id == id }) else { return }
        ledger.participants[index].displayName = trimmed
        ledger.updatedAt = Date()
        onLedgerChanged?(ledger)
    }

    func sendBalances() {
        onSendBalances?()
    }

    func expand() { onExpand?() }
    func compact() { onCompact?() }

    func moneyString(_ cents: Int) -> String {
        Money(cents: abs(cents), currencyCode: ledger.currencyCode).formatted
    }
}
