import SwiftUI

enum SplitTheme {
    static let forest = Color(red: 0.09, green: 0.35, blue: 0.28)
    static let moss = Color(red: 0.22, green: 0.55, blue: 0.42)
    static let sand = Color(red: 0.96, green: 0.93, blue: 0.86)
    static let ink = Color(red: 0.12, green: 0.16, blue: 0.14)
    /// Use instead of `.secondary` — Messages dark traits make `.secondary` nearly white.
    static let muted = Color(red: 0.32, green: 0.38, blue: 0.35)
    static let coral = Color(red: 0.86, green: 0.38, blue: 0.28)
    static let fieldFill = Color(red: 1.0, green: 0.99, blue: 0.96)
    static let fieldStroke = Color(red: 0.09, green: 0.35, blue: 0.28).opacity(0.28)

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
}

extension View {
    func splitFieldChrome(cornerRadius: CGFloat = 12) -> some View {
        padding(12)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(SplitTheme.fieldFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(SplitTheme.fieldStroke, lineWidth: 1.5)
                    )
            )
    }
}
