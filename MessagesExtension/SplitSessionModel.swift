import Foundation
import Messages
import SplitCore
import SwiftUI
import UIKit

@MainActor
final class SplitSessionModel: ObservableObject {
    @Published var ledger = GroupLedger(groupId: "empty")
    @Published var localParticipantId = ""
    @Published var presentationStyle: MSMessagesAppPresentationStyle = .compact

    @Published var draftTitle = ""
    @Published var draftDetails = ""
    @Published var draftAmountText = ""
    @Published var draftPaidById = ""
    @Published var selectedParticipantIds: Set<String> = []
    @Published var draftImage: UIImage?
    @Published var errorMessage: String?
    @Published var infoMessage: String?

    private let imageStore = ImageStore(appGroupID: SplitCoreInfo.appGroupID)
    private let applePay = ApplePaySettler()

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

    /// Debts the local user currently owes.
    var myPayableSettlements: [Settlement] {
        settlements.filter { $0.fromId == localParticipantId }
    }

    var selectedPeopleSummary: String {
        let names = participants
            .filter { selectedParticipantIds.contains($0.id) }
            .map(\.displayName)
        if names.isEmpty { return "No one selected" }
        if names.count == participants.count { return "Everyone (\(names.count))" }
        return names.joined(separator: ", ")
    }

    var draftPerPersonCents: Int? {
        guard selectedParticipantIds.count > 0,
              let amount = parsedAmountCents() else { return nil }
        return MoneySplitter.equalShares(
            totalCents: amount,
            count: selectedParticipantIds.count
        ).first
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
        infoMessage = nil

        guard let amountCents = parsedAmountCents(), amountCents > 0 else {
            errorMessage = "Enter a valid amount."
            return
        }
        let title = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            errorMessage = "Add a title for this bill."
            return
        }
        guard !selectedParticipantIds.isEmpty else {
            errorMessage = "Select at least one person on this bill."
            return
        }
        guard participants.contains(where: { $0.id == draftPaidById }) else {
            errorMessage = "Choose who paid."
            return
        }

        let details = draftDetails.trimmingCharacters(in: .whitespacesAndNewlines)
        let expenseId = UUID()
        var imageFileName: String?
        var hasImage = false

        if let draftImage,
           let data = ImageStore.compressedJPEG(from: draftImage) {
            imageFileName = imageStore.saveJPEG(data: data, expenseId: expenseId)
            hasImage = imageFileName != nil
        }

        let orderedIds = participants.map(\.id).filter { selectedParticipantIds.contains($0) }
        let expense = Expense.equalSplit(
            id: expenseId,
            title: title,
            details: details.isEmpty ? nil : details,
            amountCents: amountCents,
            paidById: draftPaidById,
            participantIds: orderedIds,
            currencyCode: ledger.currencyCode,
            imageFileName: imageFileName,
            hasImage: hasImage
        )

        onSendExpense?(expense)
        clearDraft()
    }

    func clearDraft() {
        draftTitle = ""
        draftDetails = ""
        draftAmountText = ""
        draftImage = nil
        errorMessage = nil
    }

    func toggleParticipant(_ id: String) {
        if selectedParticipantIds.contains(id) {
            selectedParticipantIds.remove(id)
        } else {
            selectedParticipantIds.insert(id)
        }
    }

    func selectAllParticipants() {
        selectedParticipantIds = Set(participants.map(\.id))
    }

    func clearSelectedParticipants() {
        selectedParticipantIds.removeAll()
    }

    func renameParticipant(id: String, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let index = ledger.participants.firstIndex(where: { $0.id == id }) else { return }
        ledger.participants[index].displayName = trimmed
        ledger.updatedAt = Date()
        onLedgerChanged?(ledger)
    }

    func image(for expense: Expense) -> UIImage? {
        guard let fileName = expense.imageFileName,
              let data = imageStore.loadData(fileName: fileName) else { return nil }
        return UIImage(data: data)
    }

    // MARK: - Settlements / Apple Pay

    func settleWithApplePay(_ settlement: Settlement) {
        errorMessage = nil
        infoMessage = nil
        let toName = ledger.displayName(for: settlement.toId)
        applePay.settle(
            amountCents: settlement.amountCents,
            currencyCode: ledger.currencyCode,
            label: "Split · pay \(toName)"
        ) { [weak self] result in
            Task { @MainActor in
                self?.handleApplePay(result, settlement: settlement)
            }
        }
    }

    func settleManually(_ settlement: Settlement) {
        recordSettlement(settlement, method: .manual, note: "Marked paid")
    }

    private func handleApplePay(_ result: ApplePaySettleResult, settlement: Settlement) {
        switch result {
        case .success:
            recordSettlement(settlement, method: .applePay, note: "Paid with Apple Pay")
        case .cancelled:
            break
        case .unavailable(let message):
            // Wallet history / peer Apple Cash isn't available via public API.
            // Fall back to manual settle when merchant Pay isn't set up yet.
            infoMessage = message + " You can mark it paid manually."
        case .failed(let message):
            errorMessage = message
        }
    }

    private func recordSettlement(
        _ settlement: Settlement,
        method: PaymentMethod,
        note: String
    ) {
        let expense = Expense.settlement(
            fromId: settlement.fromId,
            toId: settlement.toId,
            amountCents: settlement.amountCents,
            currencyCode: ledger.currencyCode,
            method: method,
            note: note
        )
        onSendExpense?(expense)
        infoMessage = method == .applePay ? "Apple Pay settlement sent." : "Marked as paid."
    }

    func sendBalances() {
        onSendBalances?()
    }

    func expand() { onExpand?() }
    func compact() { onCompact?() }

    func moneyString(_ cents: Int) -> String {
        Money(cents: abs(cents), currencyCode: ledger.currencyCode).formatted
    }

    private func parsedAmountCents() -> Int? {
        let cleaned = draftAmountText
            .replacingOccurrences(of: "$", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let amount = Decimal(string: cleaned), amount > 0 else { return nil }
        return Money(amount: amount, currencyCode: ledger.currencyCode).cents
    }
}
