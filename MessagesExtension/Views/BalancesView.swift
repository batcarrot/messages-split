import SplitCore
import SwiftUI

struct BalancesView: View {
    @ObservedObject var model: SplitSessionModel
    @State private var renamingId: String?
    @State private var renameDraft = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let info = model.infoMessage {
                    Text(info)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(SplitTheme.forest)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(SplitTheme.moss.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                if let error = model.errorMessage {
                    Text(error)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(SplitTheme.coral)
                }

                if model.settlements.isEmpty {
                    settledCard
                } else {
                    Text("Who owes whom")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(SplitTheme.ink)

                    ForEach(model.settlements) { settlement in
                        settlementRow(settlement)
                    }
                }

                if !model.myPayableSettlements.isEmpty {
                    paySection
                }

                netList
                peopleList

                Button {
                    model.sendBalances()
                } label: {
                    Label("Share balances in chat", systemImage: "bubble.left.and.bubble.right.fill")
                        .font(.system(.headline, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(.white)
                        .background(SplitTheme.moss, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .alert("Rename", isPresented: Binding(
            get: { renamingId != nil },
            set: { if !$0 { renamingId = nil } }
        )) {
            TextField("Name", text: $renameDraft)
            Button("Save") {
                if let id = renamingId {
                    model.renameParticipant(id: id, to: renameDraft)
                }
                renamingId = nil
            }
            Button("Cancel", role: .cancel) { renamingId = nil }
        } message: {
            Text("Messages hides contact names from apps — set a nickname for this chat.")
        }
    }

    private var paySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pay what you owe")
                .font(.system(.headline, design: .rounded))
            Text("Settle with Apple Pay, or mark paid if you already sent money.")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(.secondary)

            ForEach(model.myPayableSettlements) { settlement in
                let to = model.ledger.displayName(for: settlement.toId)
                let amount = model.moneyString(settlement.amountCents)

                VStack(alignment: .leading, spacing: 10) {
                    Text("\(amount) to \(to)")
                        .font(.system(.body, design: .rounded).weight(.semibold))

                    if ApplePaySettler.canMakePayments {
                        ApplePayButton(type: .plain, style: .black) {
                            model.settleWithApplePay(settlement)
                        }
                        .frame(height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }

                    Button("Mark as paid") {
                        model.settleManually(settlement)
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(SplitTheme.forest)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private var settledCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("All settled up")
                .font(.system(.title2, design: .serif).weight(.bold))
                .foregroundStyle(SplitTheme.forest)
            Text("No one owes anyone right now.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func settlementRow(_ settlement: Settlement) -> some View {
        let from = model.ledger.displayName(for: settlement.fromId)
        let to = model.ledger.displayName(for: settlement.toId)
        let amount = Money(cents: settlement.amountCents, currencyCode: model.ledger.currencyCode).formatted

        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(from) owes \(to)")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                Text(amount)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(SplitTheme.coral)
            }
            Spacer()
            Image(systemName: "arrow.right.circle.fill")
                .font(.title2)
                .foregroundStyle(SplitTheme.moss)
        }
        .padding(14)
        .background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var netList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Net balances")
                .font(.system(.headline, design: .rounded))
            ForEach(model.participants) { person in
                let cents = model.netBalances[person.id] ?? 0
                HStack {
                    Text(person.displayName)
                        .font(.system(.body, design: .rounded))
                    Spacer()
                    Text(netLabel(cents))
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(cents >= 0 ? SplitTheme.forest : SplitTheme.coral)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(14)
        .background(.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var peopleList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("People in this split")
                .font(.system(.headline, design: .rounded))
            ForEach(model.participants) { person in
                Button {
                    renamingId = person.id
                    renameDraft = person.displayName
                } label: {
                    HStack {
                        Text(person.displayName)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(SplitTheme.ink)
                        Spacer()
                        Text("Rename")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(SplitTheme.moss)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func netLabel(_ cents: Int) -> String {
        if cents == 0 { return "±0" }
        let prefix = cents > 0 ? "+" : "−"
        return prefix + model.moneyString(cents)
    }
}
