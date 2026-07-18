# Split — Splitwise for Messages

An **iMessage app extension** that splits expenses with everyone in a chat: add a cost, pick who paid, split equally, and send an interactive bubble so the group ledger stays in the conversation.

## What it does

- Pulls participants from the active Messages conversation
- Adds expenses with equal split (remainder cents handled fairly)
- Tracks net balances and simplified “who owes whom”
- Sends / updates interactive `MSMessage` bubbles with the shared ledger
- Persists ledgers per chat via App Group storage

## Project layout

```
Packages/SplitCore/          Shared Swift package (money, ledger, balances, payload)
MessagesExtension/           iMessage UI + MSMessagesAppViewController
SplitMessages/               Lightweight host app (onboarding)
project.yml                  XcodeGen project definition
scripts/validate_split_logic.py
```

## Requirements

- macOS with Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- Apple Developer team (for device / Messages testing)
- App Group: `group.com.batcarrot.messages-split` (enable for both targets in the developer portal)

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
4. Run on a **physical iPhone** (Messages extensions are limited in Simulator).
5. In Messages → App Store icon → enable **Split**.

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
3. **Add expense** — amount, description, who paid, who shares.
4. Tap **Split & send** — everyone gets a bubble with the update.
5. Open **Balances** to see simplified debts, or **Share balances in chat**.

## How sync works

Each bubble embeds a `splitmessages://ledger?...` URL (`MessagePayload`) with the full ledger JSON. Opening a bubble merges that payload with local App Group storage so late joiners catch up. Sessions (`MSSession`) keep related bubbles linked as the ledger grows.

## Notes

- Messages does not expose contact names to extensions; remote people show as short IDs (`Friend AB12`) until you rename them locally in a future pass.
- Exact / percent splits are modeled in `SplitMode` but only equal split is wired in the UI for v1.
- Currency defaults to USD; `Money` is cents-based to avoid float errors.

## License

MIT
