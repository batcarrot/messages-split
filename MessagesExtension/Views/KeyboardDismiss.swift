import SwiftUI

/// Keyboard helpers for the Messages extension.
/// Avoid UIView bridges / toolbars here — they can leave a stuck grey dimming layer.
enum Keyboard {
    static func dismiss() {
        // Callers should also clear @FocusState. No UIKit window bridge:
        // that has caused the entire extension UI to appear greyed out.
    }
}
