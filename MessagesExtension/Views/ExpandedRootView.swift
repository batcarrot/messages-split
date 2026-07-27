import SwiftUI
import SplitCore

struct ExpandedRootView: View {
    @ObservedObject var model: SplitSessionModel
    @State private var tab: Tab = .add

    enum Tab: String, CaseIterable {
        case add = "Add"
        case balances = "Balances"
        case activity = "Activity"
    }

    var body: some View {
        ZStack {
            SplitTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Picker("Section", selection: $tab) {
                    ForEach(Tab.allCases, id: \.self) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .onChange(of: tab) { _ in
                    Keyboard.dismiss()
                }

                Group {
                    switch tab {
                    case .add:
                        AddExpenseView(model: model)
                    case .balances:
                        BalancesView(model: model)
                    case .activity:
                        ActivityView(model: model)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .keyboardDismissBridge()
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Split")
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundStyle(SplitTheme.forest)
                Text(personalLine)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(SplitTheme.ink.opacity(0.75))
            }
            Spacer()
            Button {
                Keyboard.dismiss()
                model.compact()
            } label: {
                Text("Close")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(SplitTheme.forest)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(SplitTheme.field, in: Capsule())
                    .overlay(Capsule().strokeBorder(SplitTheme.stroke, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var personalLine: String {
        let cents = model.personalBalanceCents
        if cents > 0 { return "You're owed \(model.moneyString(cents))" }
        if cents < 0 { return "You owe \(model.moneyString(cents))" }
        return "You're all settled up"
    }
}

struct ActivityView: View {
    @ObservedObject var model: SplitSessionModel

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                if model.ledger.expenses.isEmpty {
                    Text("No expenses yet. Add one to start the ledger.")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(SplitTheme.muted)
                        .padding(.top, 24)
                } else {
                    ForEach(model.ledger.expenses.reversed()) { expense in
                        expenseRow(expense)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    private func expenseRow(_ expense: Expense) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let image = model.image(for: expense) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            HStack(alignment: .firstTextBaseline) {
                Text(expense.title)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(SplitTheme.ink)
                Spacer()
                Text(Money(cents: expense.amountCents, currencyCode: expense.currencyCode).formatted)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(SplitTheme.ink)
            }

            if let details = expense.details, !details.isEmpty {
                Text(details)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(SplitTheme.ink.opacity(0.75))
            }

            if expense.kind == .settlement {
                let to = model.ledger.displayName(for: expense.shares.first?.participantId ?? "")
                let via = expense.paymentMethod == .applePay ? " · Apple Pay" : " · manual"
                Text("\(model.ledger.displayName(for: expense.paidById)) paid \(to)\(via)")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(SplitTheme.muted)
            } else {
                let names = expense.shares
                    .map { model.ledger.displayName(for: $0.participantId) }
                    .joined(separator: ", ")
                Text("Paid by \(model.ledger.displayName(for: expense.paidById)) · \(names)")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(SplitTheme.muted)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SplitTheme.cardBackground())
    }
}
