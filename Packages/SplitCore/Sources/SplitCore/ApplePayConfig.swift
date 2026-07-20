import Foundation

/// Apple Pay merchant configuration.
///
/// Personal (free) Apple Developer teams **cannot** use the Apple Pay capability.
/// Leave `merchantIdentifier` empty until you have a paid Apple Developer Program
/// membership and a Merchant ID. Settle-up still works via **Mark as paid**.
public enum ApplePayConfig {
    /// Set this only after enabling Apple Pay on a paid team, e.g.
    /// `merchant.com.batcarrot.messages-split`. Keep empty for personal teams.
    public static let merchantIdentifier = ""

    /// ISO country code for the payment request.
    public static let countryCode = "US"

    /// Supported networks for settle-up.
    public static let supportedNetworksRaw = ["visa", "masterCard", "amex", "discover"]

    /// Live Apple Pay is off until a merchant ID is set (requires paid team + entitlement).
    public static var isConfigured: Bool {
        !merchantIdentifier.isEmpty && merchantIdentifier.hasPrefix("merchant.")
    }
}
