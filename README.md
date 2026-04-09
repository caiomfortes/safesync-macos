# SafeSync

> Safe and predictable incremental backups for macOS.

SafeSync is a backup tool designed around two principles: **safety** (never lose your data) and **predictability** (always show what will happen before doing it).

🚧 **Currently in beta.** Looking for testers and feedback. See [Releases](../../releases) to download.

## Features

- **Backup mode** — Copies new and updated files. Never removes anything from the destination.
- **Sync mode** — Mirrors source to destination. Orphan files are moved to the Trash (not permanently deleted).
- **Multiple plans** — Manage multiple backup configurations with a sidebar.
- **Live preview** — See exactly what will be copied/removed before confirming.
- **Concurrent execution** — Run up to 3 backups simultaneously, with queueing for additional ones.
- **History tracking** — See past executions with outcomes and counts.
- **Menu bar access** — Quick status and controls without opening the main window.
- **Localized** — English, Portuguese (Brazil), Spanish.
- **Dark/Light mode** — Follows system appearance or can be forced.

## Requirements

- macOS 14 (Sonoma) or later
- Apple Silicon or Intel Mac

## Installation

1. Download the latest release from the [Releases page](../../releases).
2. Unzip and move `SafeSync.app` to your Applications folder.
3. **First time only:** right-click on `SafeSync.app` and choose **Open**. This bypasses Gatekeeper for unsigned apps. After the first launch, you can open it normally.
4. If macOS still blocks, go to **System Settings → Privacy & Security** and click **Open Anyway** next to the SafeSync warning.

## Why "right-click → Open"?

SafeSync is not currently signed with a paid Apple Developer ID. macOS shows a warning the first time you try to open unsigned apps, even when they're safe. Right-clicking and choosing Open bypasses this for that specific app. You only need to do this once.

If you're uncomfortable running unsigned apps, you can build SafeSync from source (see below).

## Building from source

1. Clone this repository
2. Open `SafeSync2.xcodeproj` in Xcode 15 or later
3. Cmd+R to build and run

## Reporting bugs and feedback

- For bugs: [open an issue](../../issues/new?template=bug_report.md) using the bug template
- For feature requests: [open an issue](../../issues/new?template=feature_request.md) using the feature template
- For questions and general discussion: [Discussions](../../discussions)

## Safety notes

- SafeSync is in **beta**. Don't rely on it as your only backup tool yet.
- Sync mode moves files to the Trash, not permanent deletion. You can recover them.
- Symbolic links are ignored to prevent unexpected behavior.
- When source folders appear empty (possibly due to errors), Sync operations are cancelled to prevent accidental data loss.

## License

[MIT License](LICENSE) — see LICENSE file for details.

## Acknowledgements

Built with SwiftUI for macOS.
