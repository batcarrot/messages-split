import Foundation

/// Apple Pay merchant configuration.
///
/// Apple does **not** expose a public API to read a user's Apple Pay / Wallet
/// transaction history. Split uses PassKit to *collect or settle* balances with
/// Apple Pay when a merchant ID is configured.
public enum ApplePayConfig {
    /// Replace with your Merchant ID from Apple Developer → Certificates, Identifiers & Profiles.
    /// Example: `merchant.com.batcarrot.messages-split`
    public static let merchantIdentifier = "merchant.com.batcarrot.messages-split"

    /// ISO country code for the payment request.
    public static let countryCode = "US"

    /// Supported networks for settle-up.
    public static let supportedNetworksRaw = ["visa", "masterCard", "amex", "discover"]

    public static var isConfigured: Bool {
        !merchantIdentifier.isEmpty && merchantIdentifier.hasPrefix("merchant.")
    }
}
