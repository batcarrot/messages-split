import SwiftUI
import UIKit

enum Keyboard {
    /// Hard dismiss for Messages extensions, where focus can stick.
    static func dismiss() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

extension View {
    /// Done button above the keyboard.
    func dismissKeyboardToolbar(onDismiss: @escaping () -> Void) -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    onDismiss()
                    Keyboard.dismiss()
                }
                .font(.body.weight(.semibold))
            }
        }
    }
}
