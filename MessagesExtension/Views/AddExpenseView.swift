import SwiftUI
import SplitCore

struct AddExpenseView: View {
    @ObservedObject var model: SplitSessionModel
    @FocusState private var amountFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                amountField
                titleField
                paidByPicker
                splitWithPicker

                if let error = model.errorMessage {
                    Text(error)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(SplitTheme.coral)
                }

                Button {
                    model.submitExpense()
                } label: {
                    Text("Split & send in Messages")
                        .font(.system(.headline, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(.white)
                        .background(SplitTheme.forest, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .onAppear { amountFocused = true }
    }

    private var amountField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Amount")
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(.secondary)
            TextField("0.00", text: $model.draftAmountText)
                .keyboardType(.decimalPad)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(SplitTheme.ink)
                .focused($amountFocused)
        }
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What for?")
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(.secondary)
            TextField("Dinner, taxi, groceries…", text: $model.draftTitle)
                .font(.system(.title3, design: .rounded))
                .padding(12)
                .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var paidByPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Paid by")
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(model.participants) { person in
                        let selected = model.draftPaidById == person.id
                        Button {
                            model.draftPaidById = person.id
                        } label: {
                            Text(person.displayName)
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .foregroundStyle(selected ? .white : SplitTheme.ink)
                                .background(
                                    selected ? SplitTheme.moss : Color.white.opacity(0.8),
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var splitWithPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Split equally with")
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(.secondary)
            FlowParticipantGrid(model: model)
        }
    }
}

struct FlowParticipantGrid: View {
    @ObservedObject var model: SplitSessionModel

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
            ForEach(model.participants) { person in
                let selected = model.selectedParticipantIds.contains(person.id)
                Button {
                    model.toggleParticipant(person.id)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        Text(person.displayName)
                            .lineLimit(1)
                    }
                    .font(.system(.subheadline, design: .rounded))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(selected ? SplitTheme.forest : SplitTheme.ink)
                    .background(
                        selected ? SplitTheme.moss.opacity(0.18) : Color.white.opacity(0.8),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
