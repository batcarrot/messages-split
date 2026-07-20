# Split — Splitwise for Messages

An **iMessage app extension** that splits expenses with everyone in a chat: pick who’s on the bill, add a title / optional note / optional photo, track balances, and settle with **Apple Pay**.

## What it does

- Pulls participants from the active Messages conversation
- **Select people per bill** (All / None / tap to include) with live per-person amounts
- **Title**, optional **description**, optional **receipt photo**
- Equal split with fair remainder cents
- Net balances + simplified “who owes whom”
- **Apple Pay settle-up** for amounts you owe (plus mark-as-paid fallback)
- Interactive `MSMessage` bubbles + App Group ledger persistence

## Apple Pay notes

Personal (free) Apple IDs **cannot** use the Apple Pay capability — it is turned off by default so you can build and run.

To enable later (paid Apple Developer Program only):

1. Create a Merchant ID in [Apple Developer](https://developer.apple.com/account/resources/identifiers/list/merchant)
2. Set it in `Packages/SplitCore/Sources/SplitCore/ApplePayConfig.swift`
3. Add the Apple Pay entitlement / capability on both targets
4. Wire `payment.token` in `ApplePaySettler` to your payment processor

Until then, use **Mark as paid**. Receipt photos cover “I paid with Apple Pay at the restaurant” for expense entry.

## Project layout

```
Packages/SplitCore/          Money, ledger, balances, payload, image store, Apple Pay config
MessagesExtension/           iMessage UI + MSMessagesAppViewController + PassKit
SplitMessages/               Lightweight host app (onboarding)
project.yml                  XcodeGen project definition
scripts/validate_split_logic.py
```

## Requirements

- macOS with Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- Apple Developer team (for device / Messages testing)
- App Group: `group.com.batcarrot.messages-split`
- Optional later: Apple Pay (paid Apple Developer Program only)

## Setup

```bash
# Generate the Xcode project
xcodegen generate

# Open in Xcode
open SplitMessages.xcodeproj
```

1. Select the **SplitMessages** scheme.
2. Set your **Development Team** on both `SplitMessages` and `MessagesExtension`.
3. Confirm the App Group capability matches `group.com.batcarrot.messages-split`.
4. (Optional) Enable Apple Pay with your merchant ID.
5. Run on a **physical iPhone** (Messages extensions are limited in Simulator).
6. In Messages → App Store icon → enable **Split**.

### Run SplitCore unit tests (on a Mac)

```bash
cd Packages/SplitCore
swift test
```

### Validate split math without Xcode (Linux / CI)

```bash
python3 scripts/validate_split_logic.py -v
```

## Using it in a chat

1. Open a 1:1 or group thread in Messages.
2. Open the app drawer and tap **Split**.
3. **Add** — amount, title, optional description/photo, who paid, who’s on the bill.
4. Tap **Split & send** — everyone gets a bubble with the update.
5. **Balances** — see debts, pay with Apple Pay, or mark paid.
6. **Activity** — browse the ledger with notes and photos.

## How sync works

Each bubble embeds a `splitmessages://ledger?...` URL (`MessagePayload`) with the ledger JSON. Opening a bubble merges that payload with local App Group storage. Bill photos live in the App Group container and are shown on the message bubble layout; they are not stuffed into the URL (size limits).

## Notes

- Messages does not expose contact names to extensions; rename people under Balances.
- Exact / percent splits are modeled in `SplitMode` but only equal split is wired in the UI for v1.
- Currency defaults to USD; `Money` is cents-based to avoid float errors.

## License

MIT
