import Foundation

/// Integer cents avoid floating-point rounding bugs in expense math.
public struct Money: Codable, Hashable, Sendable, Comparable {
    public let cents: Int
    public let currencyCode: String

    public init(cents: Int, currencyCode: String = "USD") {
        self.cents = cents
        self.currencyCode = currencyCode
    }

    public init(amount: Decimal, currencyCode: String = "USD") {
        let rounded = NSDecimalNumber(decimal: amount * 100).rounding(
            accordingToBehavior: NSDecimalNumberHandler(
                roundingMode: .plain,
                scale: 0,
                raiseOnExactness: false,
                raiseOnOverflow: false,
                raiseOnUnderflow: false,
                raiseOnDivideByZero: false
            )
        )
        self.cents = rounded.intValue
        self.currencyCode = currencyCode
    }

    public var decimalValue: Decimal {
        Decimal(cents) / 100
    }

    public var formatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: NSDecimalNumber(decimal: decimalValue))
            ?? String(format: "%.2f", Double(cents) / 100.0)
    }

    public static func + (lhs: Money, rhs: Money) -> Money {
        precondition(lhs.currencyCode == rhs.currencyCode)
        return Money(cents: lhs.cents + rhs.cents, currencyCode: lhs.currencyCode)
    }

    public static func - (lhs: Money, rhs: Money) -> Money {
        precondition(lhs.currencyCode == rhs.currencyCode)
        return Money(cents: lhs.cents - rhs.cents, currencyCode: lhs.currencyCode)
    }

    public static func < (lhs: Money, rhs: Money) -> Bool {
        lhs.cents < rhs.cents
    }

    public static let zeroUSD = Money(cents: 0, currencyCode: "USD")
}

public enum MoneySplitter {
    /// Splits `totalCents` as evenly as possible across `count` people.
    /// Remainder cents go to the first participants so the sum always matches.
    public static func equalShares(totalCents: Int, count: Int) -> [Int] {
        precondition(count > 0, "Need at least one participant")
        let base = totalCents / count
        let remainder = totalCents % count
        return (0..<count).map { index in
            base + (index < remainder ? 1 : 0)
        }
    }
}
