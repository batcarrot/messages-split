import SwiftUI
import SplitCore

struct CompactRootView: View {
    @ObservedObject var model: SplitSessionModel

    var body: some View {
        ZStack {
            SplitTheme.background.ignoresSafeArea()

            HStack(spacing: 12) {
                balanceChip

                Button {
                    model.expand()
                } label: {
                    Label("Add expense", systemImage: "plus.circle.fill")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(SplitTheme.forest, in: Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    model.sendBalances()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.headline)
                        .foregroundStyle(SplitTheme.forest)
                        .padding(12)
                        .background(.white.opacity(0.8), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Send balances")
            }
            .padding(.horizontal, 16)
        }
    }

    private var balanceChip: some View {
        let cents = model.personalBalanceCents
        let label: String
        if cents > 0 {
            label = "Owed \(model.moneyString(cents))"
        } else if cents < 0 {
            label = "Owe \(model.moneyString(cents))"
        } else {
            label = "Settled"
        }

        return Text(label)
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundStyle(SplitTheme.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.white.opacity(0.75), in: Capsule())
    }
}
