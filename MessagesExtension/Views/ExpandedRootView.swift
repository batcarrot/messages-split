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
        NavigationStack {
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
                    .padding()

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
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Split")
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundStyle(SplitTheme.forest)
                Text(personalLine)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(SplitTheme.ink.opacity(0.75))
            }
            Spacer()
            Button("Done") { model.compact() }
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(SplitTheme.forest)
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
                        .foregroundStyle(.secondary)
                        .padding(.top, 24)
                } else {
                    ForEach(model.ledger.expenses.reversed()) { expense in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(expense.title)
                                    .font(.system(.headline, design: .rounded))
                                Spacer()
                                Text(Money(cents: expense.amountCents, currencyCode: expense.currencyCode).formatted)
                                    .font(.system(.headline, design: .rounded))
                            }
                            Text("Paid by \(model.ledger.displayName(for: expense.paidById)) · split \(expense.shares.count) ways")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }
}
