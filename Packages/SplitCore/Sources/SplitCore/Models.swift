import Foundation

public struct Participant: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public var displayName: String

    public init(id: String, displayName: String) {
        self.id = id
        self.displayName = displayName
    }
}

public enum SplitMode: String, Codable, Sendable, CaseIterable {
    case equal
    case exact
}

public struct ExpenseShare: Codable, Hashable, Sendable {
    public let participantId: String
    public let amountCents: Int

    public init(participantId: String, amountCents: Int) {
        self.participantId = participantId
        self.amountCents = amountCents
    }
}

public struct Expense: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public var title: String
    public var amountCents: Int
    public var paidById: String
    public var shares: [ExpenseShare]
    public var createdAt: Date
    public var currencyCode: String
    public var splitMode: SplitMode

    public init(
        id: UUID = UUID(),
        title: String,
        amountCents: Int,
        paidById: String,
        shares: [ExpenseShare],
        createdAt: Date = Date(),
        currencyCode: String = "USD",
        splitMode: SplitMode = .equal
    ) {
        self.id = id
        self.title = title
        self.amountCents = amountCents
        self.paidById = paidById
        self.shares = shares
        self.createdAt = createdAt
        self.currencyCode = currencyCode
        self.splitMode = splitMode
    }

    public static func equalSplit(
        title: String,
        amountCents: Int,
        paidById: String,
        participantIds: [String],
        currencyCode: String = "USD"
    ) -> Expense {
        let amounts = MoneySplitter.equalShares(totalCents: amountCents, count: participantIds.count)
        let shares = zip(participantIds, amounts).map { ExpenseShare(participantId: $0, amountCents: $1) }
        return Expense(
            title: title,
            amountCents: amountCents,
            paidById: paidById,
            shares: shares,
            currencyCode: currencyCode,
            splitMode: .equal
        )
    }
}

public struct Settlement: Codable, Hashable, Identifiable, Sendable {
    public var id: String { "\(fromId)->\(toId):\(amountCents)" }
    public let fromId: String
    public let toId: String
    public let amountCents: Int

    public init(fromId: String, toId: String, amountCents: Int) {
        self.fromId = fromId
        self.toId = toId
        self.amountCents = amountCents
    }
}

public struct GroupLedger: Codable, Hashable, Sendable {
    public var groupId: String
    public var title: String
    public var participants: [Participant]
    public var expenses: [Expense]
    public var currencyCode: String
    public var updatedAt: Date

    public init(
        groupId: String,
        title: String = "Group expenses",
        participants: [Participant] = [],
        expenses: [Expense] = [],
        currencyCode: String = "USD",
        updatedAt: Date = Date()
    ) {
        self.groupId = groupId
        self.title = title
        self.participants = participants
        self.expenses = expenses
        self.currencyCode = currencyCode
        self.updatedAt = updatedAt
    }

    public mutating func upsert(participant: Participant) {
        if let index = participants.firstIndex(where: { $0.id == participant.id }) {
            participants[index].displayName = participant.displayName
        } else {
            participants.append(participant)
        }
    }

    public mutating func addExpense(_ expense: Expense) {
        expenses.append(expense)
        updatedAt = Date()
    }

    public func participant(id: String) -> Participant? {
        participants.first { $0.id == id }
    }

    public func displayName(for id: String) -> String {
        participant(id: id)?.displayName ?? "Someone"
    }
}
