import SwiftUI
import UIKit

/// Dismisses the keyboard in an app extension without using `UIApplication.shared`.
enum Keyboard {
    static func dismiss() {
        // Posted so any hosted UIView in the hierarchy can end editing.
        NotificationCenter.default.post(name: .splitDismissKeyboard, object: nil)
    }
}

extension Notification.Name {
    static let splitDismissKeyboard = Notification.Name("split.dismissKeyboard")
}

/// Invisible bridge that calls `endEditing` on its window when asked.
struct KeyboardDismissHost: UIViewRepresentable {
    func makeUIView(context: Context) -> HostView {
        HostView()
    }

    func updateUIView(_ uiView: HostView, context: Context) {}

    final class HostView: UIView {
        private var observer: NSObjectProtocol?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if observer == nil {
                observer = NotificationCenter.default.addObserver(
                    forName: .splitDismissKeyboard,
                    object: nil,
                    queue: .main
                ) { [weak self] _ in
                    self?.window?.endEditing(true)
                }
            }
        }

        deinit {
            if let observer {
                NotificationCenter.default.removeObserver(observer)
            }
        }
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
        .background(KeyboardDismissHost())
    }
}
