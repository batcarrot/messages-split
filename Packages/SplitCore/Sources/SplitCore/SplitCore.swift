/// SplitCore — shared expense-splitting logic for the Split Messages iMessage app.
///
/// Use `Expense.equalSplit` to create costs, `BalanceEngine` for who-owes-whom,
/// and `MessagePayload` to encode ledgers into interactive Messages bubbles.
public enum SplitCoreInfo {
    /// Reserved for a future paid-team App Group. Empty = local extension storage.
    public static let appGroupID: String? = nil
    public static let displayName = "Split"
}
