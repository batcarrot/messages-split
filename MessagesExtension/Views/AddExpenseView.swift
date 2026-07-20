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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
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
        .dismissKeyboardToolbar {
            endEditing()
        }
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

    private var sectionLabel: Font {
        .system(.caption, design: .rounded).weight(.semibold)
    }

    private var amountField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Amount")
                .font(sectionLabel)
                .foregroundStyle(SplitTheme.muted)
            TextField("0.00", text: $model.draftAmountText)
                .keyboardType(.decimalPad)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(SplitTheme.ink)
                .splitField(cornerRadius: 14)
                .focused($focusedField, equals: .amount)
                .submitLabel(.done)
                .onSubmit { endEditing() }
        }
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Title")
                .font(sectionLabel)
                .foregroundStyle(SplitTheme.muted)
            TextField("Dinner, taxi, groceries…", text: $model.draftTitle)
                .font(.system(.title3, design: .rounded))
                .foregroundStyle(SplitTheme.ink)
                .splitField()
                .focused($focusedField, equals: .title)
                .submitLabel(.done)
                .onSubmit { endEditing() }
        }
    }

    private var detailsField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("Description")
                    .font(sectionLabel)
                    .foregroundStyle(SplitTheme.muted)
                Text("optional")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(SplitTheme.muted.opacity(0.8))
            }
            TextField("Add a note, venue, or receipt details…", text: $model.draftDetails, axis: .vertical)
                .lineLimit(3...6)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(SplitTheme.ink)
                .splitField()
                .focused($focusedField, equals: .details)
                .submitLabel(.done)
                .onSubmit { endEditing() }
        }
    }

    private var photoField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("Picture")
                    .font(sectionLabel)
                    .foregroundStyle(SplitTheme.muted)
                Text("optional")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(SplitTheme.muted.opacity(0.8))
            }

            if let image = model.draftImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(SplitTheme.stroke, lineWidth: 1.5)
                        )

                    Button {
                        endEditing()
                        model.draftImage = nil
                        photoItem = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, SplitTheme.ink.opacity(0.7))
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
                    .splitField(cornerRadius: 14)
                }
                .buttonStyle(.plain)
                .simultaneousGesture(TapGesture().onEnded { endEditing() })
            }
        }
    }

    private var paidByPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Paid by")
                .font(sectionLabel)
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
                                .foregroundStyle(selected ? Color.white : SplitTheme.ink)
                                .background(
                                    Capsule()
                                        .fill(selected ? SplitTheme.moss : SplitTheme.field)
                                        .overlay(
                                            Capsule().strokeBorder(
                                                selected ? SplitTheme.moss : SplitTheme.stroke,
                                                lineWidth: 1.5
                                            )
                                        )
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
                        .font(sectionLabel)
                        .foregroundStyle(SplitTheme.muted)
                    Text(model.selectedPeopleSummary)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(SplitTheme.ink.opacity(0.75))
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
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(selected ? SplitTheme.moss.opacity(0.16) : SplitTheme.field)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(
                                            selected ? SplitTheme.forest.opacity(0.55) : SplitTheme.stroke,
                                            lineWidth: 1.5
                                        )
                                )
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
