/// SplitCore — shared expense-splitting logic for the Split Messages iMessage app.
///
/// Use `Expense.equalSplit` to create costs, `BalanceEngine` for who-owes-whom,
/// and `MessagePayload` to encode ledgers into interactive Messages bubbles.
public enum SplitCoreInfo {
    public static let appGroupID = "group.com.batcarrot.messages-split"
    public static let displayName = "Split"
}
