import SwiftUI

enum SplitTheme {
    static let forest = Color(red: 0.07, green: 0.32, blue: 0.26)
    static let moss = Color(red: 0.18, green: 0.50, blue: 0.38)
    static let sand = Color(red: 0.93, green: 0.88, blue: 0.78)
    static let parchment = Color(red: 0.99, green: 0.97, blue: 0.92)
    static let field = Color(red: 1.0, green: 0.99, blue: 0.96)
    static let ink = Color(red: 0.10, green: 0.14, blue: 0.12)
    static let muted = Color(red: 0.35, green: 0.40, blue: 0.37)
    static let coral = Color(red: 0.82, green: 0.32, blue: 0.24)
    static let stroke = Color(red: 0.07, green: 0.32, blue: 0.26).opacity(0.22)

    static var background: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.88, green: 0.93, blue: 0.89),
                sand,
                Color(red: 0.90, green: 0.86, blue: 0.76)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func fieldBackground(cornerRadius: CGFloat = 12) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(field)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(stroke, lineWidth: 1.5)
            )
    }

    static func cardBackground(cornerRadius: CGFloat = 16) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(parchment)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(stroke.opacity(0.7), lineWidth: 1)
            )
            .shadow(color: forest.opacity(0.08), radius: 8, y: 3)
    }
}

struct SplitFieldModifier: ViewModifier {
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(SplitTheme.fieldBackground(cornerRadius: cornerRadius))
    }
}

extension View {
    func splitField(cornerRadius: CGFloat = 12) -> some View {
        modifier(SplitFieldModifier(cornerRadius: cornerRadius))
    }

    func splitCard(cornerRadius: CGFloat = 16) -> some View {
        padding(14)
            .background(SplitTheme.cardBackground(cornerRadius: cornerRadius))
    }
}
