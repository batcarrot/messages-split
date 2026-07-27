import SwiftUI
import UIKit

/// Dismisses the keyboard in an app extension without `UIApplication.shared`.
enum Keyboard {
    static func dismiss() {
        NotificationCenter.default.post(name: .splitDismissKeyboard, object: nil)
    }
}

extension Notification.Name {
    static let splitDismissKeyboard = Notification.Name("split.dismissKeyboard")
}

/// Zero-size, non-interactive bridge that calls `endEditing` on its window.
private struct KeyboardDismissHost: UIViewRepresentable {
    func makeUIView(context: Context) -> HostView {
        let view = HostView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        view.isHidden = true
        return view
    }

    func updateUIView(_ uiView: HostView, context: Context) {}

    final class HostView: UIView {
        private var observer: NSObjectProtocol?

        override var intrinsicContentSize: CGSize { .zero }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard observer == nil else { return }
            observer = NotificationCenter.default.addObserver(
                forName: .splitDismissKeyboard,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.window?.endEditing(true)
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
    /// Installs the extension-safe keyboard dismiss bridge (no visible chrome).
    func keyboardDismissBridge() -> some View {
        background(
            KeyboardDismissHost()
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
                .allowsHitTesting(false)
        )
    }
}
