import SwiftUI

enum SplitTheme {
    static let forest = Color(red: 0.09, green: 0.35, blue: 0.28)
    static let moss = Color(red: 0.22, green: 0.55, blue: 0.42)
    static let sand = Color(red: 0.96, green: 0.93, blue: 0.86)
    static let ink = Color(red: 0.12, green: 0.16, blue: 0.14)
    static let coral = Color(red: 0.86, green: 0.38, blue: 0.28)

    static var background: LinearGradient {
        LinearGradient(
            colors: [sand, Color.white, Color(red: 0.90, green: 0.95, blue: 0.92)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
