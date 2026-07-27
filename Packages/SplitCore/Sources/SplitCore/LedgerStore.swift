import Foundation

/// Persists ledgers per Messages conversation in the extension's local `UserDefaults`.
/// (App Groups are avoided so personal Apple teams can sign without entitlement rewrites.)
public final class LedgerStore: @unchecked Sendable {
    private let defaults: UserDefaults
    private let prefix = "ledger."

    public init(appGroupID: String? = nil) {
        if let appGroupID, let suite = UserDefaults(suiteName: appGroupID) {
            self.defaults = suite
        } else {
            self.defaults = .standard
        }
    }

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    public func load(groupId: String) -> GroupLedger? {
        guard let data = defaults.data(forKey: prefix + groupId) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(GroupLedger.self, from: data)
    }

    public func save(_ ledger: GroupLedger) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(ledger) else { return }
        defaults.set(data, forKey: prefix + ledger.groupId)
    }

    /// Prefers the newer of local storage vs an incoming message payload.
    public func merge(local: GroupLedger?, incoming: GroupLedger) -> GroupLedger {
        guard let local else {
            save(incoming)
            return incoming
        }

        var merged = local.updatedAt >= incoming.updatedAt ? local : incoming
        let other = local.updatedAt >= incoming.updatedAt ? incoming : local

        for participant in other.participants {
            merged.upsert(participant: participant)
        }

        let existingIDs = Set(merged.expenses.map(\.id))
        for expense in other.expenses where !existingIDs.contains(expense.id) {
            merged.expenses.append(expense)
        }
        merged.expenses.sort { $0.createdAt < $1.createdAt }
        merged.updatedAt = max(local.updatedAt, incoming.updatedAt)
        save(merged)
        return merged
    }
}
