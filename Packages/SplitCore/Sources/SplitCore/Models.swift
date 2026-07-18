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

public enum ExpenseKind: String, Codable, Sendable, CaseIterable {
    /// A normal shared cost.
    case expense
    /// A payment that settles balance between two people.
    case settlement
}

public enum PaymentMethod: String, Codable, Sendable, CaseIterable {
    case none
    case applePay
    case manual
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
    /// Optional longer note (receipt details, venue, etc.).
    public var details: String?
    public var amountCents: Int
    public var paidById: String
    public var shares: [ExpenseShare]
    public var createdAt: Date
    public var currencyCode: String
    public var splitMode: SplitMode
    public var kind: ExpenseKind
    public var paymentMethod: PaymentMethod
    /// App Group relative filename, e.g. `images/<uuid>.jpg`.
    public var imageFileName: String?
    /// Whether a receipt/photo is attached (may exist only on sender until synced via bubble).
    public var hasImage: Bool

    public init(
        id: UUID = UUID(),
        title: String,
        details: String? = nil,
        amountCents: Int,
        paidById: String,
        shares: [ExpenseShare],
        createdAt: Date = Date(),
        currencyCode: String = "USD",
        splitMode: SplitMode = .equal,
        kind: ExpenseKind = .expense,
        paymentMethod: PaymentMethod = .none,
        imageFileName: String? = nil,
        hasImage: Bool = false
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.amountCents = amountCents
        self.paidById = paidById
        self.shares = shares
        self.createdAt = createdAt
        self.currencyCode = currencyCode
        self.splitMode = splitMode
        self.kind = kind
        self.paymentMethod = paymentMethod
        self.imageFileName = imageFileName
        self.hasImage = hasImage
    }

    public var participantIds: [String] {
        shares.map(\.participantId)
    }

    public static func equalSplit(
        id: UUID = UUID(),
        title: String,
        details: String? = nil,
        amountCents: Int,
        paidById: String,
        participantIds: [String],
        currencyCode: String = "USD",
        imageFileName: String? = nil,
        hasImage: Bool = false
    ) -> Expense {
        let amounts = MoneySplitter.equalShares(totalCents: amountCents, count: participantIds.count)
        let shares = zip(participantIds, amounts).map { ExpenseShare(participantId: $0, amountCents: $1) }
        return Expense(
            id: id,
            title: title,
            details: details,
            amountCents: amountCents,
            paidById: paidById,
            shares: shares,
            currencyCode: currencyCode,
            splitMode: .equal,
            kind: .expense,
            imageFileName: imageFileName,
            hasImage: hasImage
        )
    }

    /// Records that `fromId` paid `toId` (reduces what from owes to to).
    public static func settlement(
        fromId: String,
        toId: String,
        amountCents: Int,
        currencyCode: String = "USD",
        method: PaymentMethod,
        note: String? = nil
    ) -> Expense {
        Expense(
            title: "Settlement",
            details: note,
            amountCents: amountCents,
            paidById: fromId,
            shares: [ExpenseShare(participantId: toId, amountCents: amountCents)],
            currencyCode: currencyCode,
            splitMode: .exact,
            kind: .settlement,
            paymentMethod: method
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
            // Keep a custom nickname if the user already renamed this person.
            let current = participants[index].displayName
            let looksGenerated = current == "You" || current.hasPrefix("Friend ")
            if looksGenerated {
                participants[index].displayName = participant.displayName
            }
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
