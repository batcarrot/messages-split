import SwiftUI

@main
struct SplitMessagesApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.93, blue: 0.86),
                    Color(red: 0.90, green: 0.95, blue: 0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text("Split")
                    .font(.system(size: 48, weight: .bold, design: .serif))
                    .foregroundStyle(Color(red: 0.09, green: 0.35, blue: 0.28))

                Text("Split bills inside Messages — open a chat, tap the App Store icon, then Split.")
                    .font(.system(.title3, design: .rounded))
                    .foregroundStyle(Color(red: 0.12, green: 0.16, blue: 0.14).opacity(0.8))

                VStack(alignment: .leading, spacing: 10) {
                    step("1", "Open Messages and start a group chat")
                    step("2", "Tap the App Store button next to the composer")
                    step("3", "Choose Split, add an expense, send it")
                }
                .padding(.top, 12)

                Spacer()
            }
            .padding(28)
        }
    }

    private func step(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color(red: 0.22, green: 0.55, blue: 0.42), in: Circle())
            Text(text)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Color(red: 0.12, green: 0.16, blue: 0.14))
        }
    }
}
