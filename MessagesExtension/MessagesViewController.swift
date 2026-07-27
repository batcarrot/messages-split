import Messages
import SwiftUI
import SplitCore
import UIKit

@objc(MessagesViewController)
final class MessagesViewController: MSMessagesAppViewController {
    private let store = LedgerStore(appGroupID: SplitCoreInfo.appGroupID)
    private var hostingController: UIHostingController<AnyView>?
    private var model = SplitSessionModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.93, green: 0.88, blue: 0.78, alpha: 1)
        overrideUserInterfaceStyle = .light
    }

    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        bootstrap(with: conversation)
        presentUI(for: presentationStyle)
    }

    override func didResignActive(with conversation: MSConversation) {
        super.didResignActive(with: conversation)
    }

    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        super.didReceive(message, conversation: conversation)
        if let url = message.url, let payload = try? MessagePayload.decode(from: url) {
            applyIncoming(payload, conversation: conversation)
            presentUI(for: presentationStyle)
        }
    }

    override func didSelect(_ message: MSMessage, conversation: MSConversation) {
        super.didSelect(message, conversation: conversation)
        bootstrap(with: conversation)
        requestPresentationStyle(.expanded)
    }

    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.willTransition(to: presentationStyle)
        presentUI(for: presentationStyle)
    }

    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.didTransition(to: presentationStyle)
        presentUI(for: presentationStyle)
    }

    // MARK: - Bootstrap

    private func bootstrap(with conversation: MSConversation) {
        // Stable across participants: sorted union of everyone in the chat.
        let groupId = ([conversation.localParticipantIdentifier]
            + conversation.remoteParticipantIdentifiers)
            .map(\.uuidString)
            .sorted()
            .joined(separator: ".")

        var participants = conversation.remoteParticipantIdentifiers.map { uuid in
            Participant(
                id: uuid.uuidString,
                displayName: shortName(for: uuid)
            )
        }
        let me = Participant(
            id: conversation.localParticipantIdentifier.uuidString,
            displayName: "You"
        )
        participants.insert(me, at: 0)

        var ledger = store.load(groupId: groupId) ?? GroupLedger(
            groupId: groupId,
            title: "Chat split",
            participants: participants
        )
        for participant in participants {
            ledger.upsert(participant: participant)
        }

        if let selected = conversation.selectedMessage?.url,
           let payload = try? MessagePayload.decode(from: selected) {
            ledger = store.merge(local: ledger, incoming: payload.ledger)
        } else {
            store.save(ledger)
        }

        model.configure(
            ledger: ledger,
            localParticipantId: me.id,
            presentationStyle: presentationStyle
        )
        model.onSendExpense = { [weak self] expense in
            self?.send(expense: expense, in: conversation)
        }
        model.onSendBalances = { [weak self] in
            self?.sendBalances(in: conversation)
        }
        model.onExpand = { [weak self] in
            self?.requestPresentationStyle(.expanded)
        }
        model.onCompact = { [weak self] in
            self?.requestPresentationStyle(.compact)
        }
        model.onLedgerChanged = { [weak self] ledger in
            self?.store.save(ledger)
        }
    }

    private func applyIncoming(_ payload: MessagePayload, conversation: MSConversation) {
        let merged = store.merge(local: model.ledger, incoming: payload.ledger)
        model.configure(
            ledger: merged,
            localParticipantId: conversation.localParticipantIdentifier.uuidString,
            presentationStyle: presentationStyle
        )
    }

    private func shortName(for uuid: UUID) -> String {
        let hex = uuid.uuidString.replacingOccurrences(of: "-", with: "")
        return "Friend \(hex.prefix(4))"
    }

    // MARK: - Send

    private func send(expense: Expense, in conversation: MSConversation) {
        model.addExpense(expense)
        store.save(model.ledger)

        let summary = MessagePayload.makeSummary(ledger: model.ledger, expense: expense)
        let payload = MessagePayload(
            ledger: model.ledger,
            highlightExpenseId: expense.id,
            summary: summary
        )
        insertMessage(
            payload: payload,
            conversation: conversation,
            caption: summary,
            title: expense.title,
            details: expense.details,
            expenseImage: model.image(for: expense)
        )
    }

    private func sendBalances(in conversation: MSConversation) {
        store.save(model.ledger)
        let summary = MessagePayload.makeSummary(ledger: model.ledger)
        let payload = MessagePayload(ledger: model.ledger, summary: summary)
        insertMessage(payload: payload, conversation: conversation, caption: summary)
    }

    private func insertMessage(
        payload: MessagePayload,
        conversation: MSConversation,
        caption: String,
        title: String? = nil,
        details: String? = nil,
        expenseImage: UIImage? = nil
    ) {
        guard let url = try? payload.makeURL() else { return }

        let session = conversation.selectedMessage?.session ?? MSSession()
        let message = MSMessage(session: session)
        let layout = MSMessageTemplateLayout()
        layout.caption = title ?? "Split"
        layout.subcaption = caption
        if let details, !details.isEmpty {
            layout.trailingSubcaption = details
        }
        layout.trailingCaption = balanceTrailingCaption()
        layout.image = expenseImage ?? renderBubbleImage(caption: caption)
        message.layout = layout
        message.url = url
        message.summaryText = caption

        conversation.insert(message) { [weak self] error in
            if let error {
                print("Failed to insert message: \(error)")
            }
            self?.requestPresentationStyle(.compact)
        }
    }

    private func balanceTrailingCaption() -> String {
        let cents = BalanceEngine.personalBalance(
            viewerId: model.localParticipantId,
            ledger: model.ledger
        )
        let money = Money(cents: abs(cents), currencyCode: model.ledger.currencyCode)
        if cents > 0 { return "You're owed \(money.formatted)" }
        if cents < 0 { return "You owe \(money.formatted)" }
        return "Settled up"
    }

    private func renderBubbleImage(caption: String) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 300))
        return renderer.image { context in
            let rect = CGRect(x: 0, y: 0, width: 600, height: 300)
            UIColor(red: 0.09, green: 0.35, blue: 0.28, alpha: 1).setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: 28).fill()

            let title = "Split" as NSString
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 42, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            title.draw(at: CGPoint(x: 36, y: 48), withAttributes: titleAttrs)

            let bodyAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .medium),
                .foregroundColor: UIColor(white: 1, alpha: 0.9)
            ]
            let bodyRect = CGRect(x: 36, y: 120, width: 528, height: 120)
            (caption as NSString).draw(with: bodyRect, options: [.usesLineFragmentOrigin], attributes: bodyAttrs, context: nil)

            _ = context
        }
    }

    // MARK: - UI hosting

    private func presentUI(for style: MSMessagesAppPresentationStyle) {
        model.presentationStyle = style
        let root: AnyView
        switch style {
        case .compact:
            root = AnyView(CompactRootView(model: model))
        case .expanded:
            root = AnyView(ExpandedRootView(model: model))
        @unknown default:
            root = AnyView(CompactRootView(model: model))
        }

        if let hostingController {
            hostingController.rootView = root
            hostingController.view.backgroundColor = .clear
            hostingController.view.isUserInteractionEnabled = true
            hostingController.overrideUserInterfaceStyle = .light
        } else {
            let host = UIHostingController(rootView: root)
            host.view.backgroundColor = .clear
            host.view.isUserInteractionEnabled = true
            host.overrideUserInterfaceStyle = .light
            addChild(host)
            host.view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(host.view)
            NSLayoutConstraint.activate([
                host.view.topAnchor.constraint(equalTo: view.topAnchor),
                host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            host.didMove(toParent: self)
            hostingController = host
        }
    }
}
