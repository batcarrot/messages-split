import Foundation

/// Wire format embedded in `MSMessage.url` so every participant can sync the ledger.
public struct MessagePayload: Codable, Hashable, Sendable {
    public static let scheme = "splitmessages"
    public static let host = "ledger"
    public static let currentVersion = 1

    public var version: Int
    public var ledger: GroupLedger
    public var highlightExpenseId: UUID?
    public var summary: String

    public init(
        version: Int = MessagePayload.currentVersion,
        ledger: GroupLedger,
        highlightExpenseId: UUID? = nil,
        summary: String
    ) {
        self.version = version
        self.ledger = ledger
        self.highlightExpenseId = highlightExpenseId
        self.summary = summary
    }

    public static func makeSummary(ledger: GroupLedger, expense: Expense? = nil) -> String {
        if let expense {
            let money = Money(cents: expense.amountCents, currencyCode: expense.currencyCode)
            let payer = ledger.displayName(for: expense.paidById)
            let count = expense.shares.count
            return "\(expense.title) · \(money.formatted) · paid by \(payer) · split \(count) ways"
        }

        let debts = BalanceEngine.simplifiedDebts(for: ledger)
        if debts.isEmpty {
            return "All settled up · \(ledger.expenses.count) expenses"
        }
        let total = debts.reduce(0) { $0 + $1.amountCents }
        let money = Money(cents: total, currencyCode: ledger.currencyCode)
        return "\(debts.count) open balance\(debts.count == 1 ? "" : "s") · \(money.formatted) moving"
    }

    public func makeURL() throws -> URL {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(self)
        let encoded = data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")

        var components = URLComponents()
        components.scheme = Self.scheme
        components.host = Self.host
        components.queryItems = [
            URLQueryItem(name: "v", value: String(version)),
            URLQueryItem(name: "d", value: encoded)
        ]
        guard let url = components.url else {
            throw PayloadError.invalidURL
        }
        return url
    }

    public static func decode(from url: URL) throws -> MessagePayload {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == scheme,
              let items = components.queryItems,
              let encoded = items.first(where: { $0.name == "d" })?.value
        else {
            throw PayloadError.missingData
        }

        var base64 = encoded
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padding = (4 - base64.count % 4) % 4
        base64.append(String(repeating: "=", count: padding))

        guard let data = Data(base64Encoded: base64) else {
            throw PayloadError.invalidBase64
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(MessagePayload.self, from: data)
    }

    public enum PayloadError: Error, LocalizedError {
        case invalidURL
        case missingData
        case invalidBase64

        public var errorDescription: String? {
            switch self {
            case .invalidURL: return "Could not build message URL."
            case .missingData: return "Message is missing ledger data."
            case .invalidBase64: return "Message data is corrupted."
            }
        }
    }
}
