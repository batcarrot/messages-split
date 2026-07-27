import PhotosUI
import SplitCore
import SwiftUI
import UIKit

struct AddExpenseView: View {
    @ObservedObject var model: SplitSessionModel
    @FocusState private var focusedField: Field?
    @State private var photoItem: PhotosPickerItem?

    private enum Field: Hashable {
        case amount, title, details
    }

    private var isEditing: Bool { focusedField != nil }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if isEditing {
                    HStack {
                        Text("Editing")
                            .font(.system(.footnote, design: .rounded).weight(.semibold))
                            .foregroundStyle(SplitTheme.muted)
                        Spacer()
                        Button("Done") {
                            endEditing()
                        }
                        .font(.system(.body, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(SplitTheme.forest, in: Capsule())
                    }
                }

                amountField
                titleField
                detailsField
                photoField
                paidByPicker
                peoplePicker

                if let perPerson = model.draftPerPersonCents {
                    Text("≈ \(model.moneyString(perPerson)) each · \(model.selectedParticipantIds.count) people")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(SplitTheme.forest)
                }

                if let error = model.errorMessage {
                    Text(error)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(SplitTheme.coral)
                }

                Button {
                    endEditing()
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
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: photoItem) { newItem in
            endEditing()
            Task {
                await loadPhoto(from: newItem)
            }
        }
    }

    private func endEditing() {
        focusedField = nil
        Keyboard.dismiss()
    }

    private var amountField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Amount")
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(SplitTheme.muted)
            TextField(
                "",
                text: $model.draftAmountText,
                prompt: Text("0.00").foregroundColor(SplitTheme.muted)
            )
            .keyboardType(.decimalPad)
            .font(.system(size: 44, weight: .bold, design: .rounded))
            .foregroundStyle(SplitTheme.ink)
            .focused($focusedField, equals: .amount)
            .submitLabel(.done)
            .onSubmit { endEditing() }
        }
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Title")
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(SplitTheme.muted)
            TextField(
                "",
                text: $model.draftTitle,
                prompt: Text("Dinner, taxi, groceries…").foregroundColor(SplitTheme.muted)
            )
            .font(.system(.title3, design: .rounded))
            .foregroundStyle(SplitTheme.ink)
            .padding(12)
            .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .focused($focusedField, equals: .title)
            .submitLabel(.done)
            .onSubmit { endEditing() }
        }
    }

    private var detailsField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Description")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(SplitTheme.muted)
                Text("(optional)")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(SplitTheme.muted.opacity(0.85))
            }
            TextField(
                "",
                text: $model.draftDetails,
                prompt: Text("Add a note, venue, or receipt details…").foregroundColor(SplitTheme.muted),
                axis: .vertical
            )
            .lineLimit(3...6)
            .font(.system(.body, design: .rounded))
            .foregroundStyle(SplitTheme.ink)
            .padding(12)
            .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .focused($focusedField, equals: .details)
            .submitLabel(.done)
            .onSubmit { endEditing() }
        }
    }

    private var photoField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Picture")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(SplitTheme.muted)
                Text("(optional)")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(SplitTheme.muted.opacity(0.85))
            }

            if let image = model.draftImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Button {
                        endEditing()
                        model.draftImage = nil
                        photoItem = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .black.opacity(0.55))
                            .padding(10)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    HStack(spacing: 10) {
                        Image(systemName: "camera.fill")
                        Text("Add receipt or photo")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(SplitTheme.muted)
                    }
                    .foregroundStyle(SplitTheme.ink)
                    .padding(14)
                    .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .simultaneousGesture(TapGesture().onEnded { endEditing() })
            }
        }
    }

    private var paidByPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Paid by")
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(SplitTheme.muted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(model.participants) { person in
                        let selected = model.draftPaidById == person.id
                        Button {
                            endEditing()
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

    private var peoplePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("On this bill")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(SplitTheme.muted)
                    Text(model.selectedPeopleSummary)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(SplitTheme.ink.opacity(0.7))
                        .lineLimit(2)
                }
                Spacer()
                Button("All") {
                    endEditing()
                    model.selectAllParticipants()
                }
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(SplitTheme.forest)
                Button("None") {
                    endEditing()
                    model.clearSelectedParticipants()
                }
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(SplitTheme.coral)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 108), spacing: 8)], spacing: 8) {
                ForEach(model.participants) { person in
                    let selected = model.selectedParticipantIds.contains(person.id)
                    Button {
                        endEditing()
                        model.toggleParticipant(person.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selected ? SplitTheme.forest : SplitTheme.muted)
                                Text(person.displayName)
                                    .lineLimit(1)
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            }
                            if selected, let perPerson = model.draftPerPersonCents {
                                Text(model.moneyString(perPerson))
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(SplitTheme.muted)
                            } else {
                                Text(selected ? "Included" : "Tap to include")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(SplitTheme.muted)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(SplitTheme.ink)
                        .background(
                            selected ? SplitTheme.moss.opacity(0.18) : Color.white.opacity(0.8),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(selected ? SplitTheme.forest.opacity(0.45) : .clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            await MainActor.run {
                model.draftImage = image
            }
        }
    }
}
