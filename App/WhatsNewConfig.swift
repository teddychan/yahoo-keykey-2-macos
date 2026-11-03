import Foundation
import DragonKit

// "What's New" content for the current release. The version is not passed — it defaults to
// CFBundleShortVersionString and the kit adds the "v", so the pane cannot claim a release the
// binary isn't. That makes the entries and the date the only things to keep in sync with
// CHANGELOG.md on release.
//
// 2.18.0 adds Russian: KeyKey's own ru.lproj, and DragonKit 4.3.0, which translates the shared
// panes and puts Русский in Settings ▸ General ▸ Language. One `.added` entry. 4.3.0's other
// change, menu icons kept on macOS 27, is not announced: KeyKey's 關於 / 設定… items sit in the
// input menu, which the system draws, and the fix is unconfirmed there.
//
// Keys are the fleet's stable set (app.whatsNew.summary, .added1, .changed1, …), not named after
// this release's content — a release just overwrites the same keys' text in every locale's .strings
// file rather than adding new ones and stranding the last release's. 2.17.0 was also one `.added`
// entry, so the keys are unchanged and only their text moves on, in all eight files.
enum WhatsNewConfig {
    @MainActor
    static var content: WhatsNewContent {
        WhatsNewContent(
            date: "2026-11-03",
            summary: L("app.whatsNew.summary"),
            sections: [
                ChangeSection(kind: .added, entries: [
                    L("app.whatsNew.added1"),
                ]),
            ]
        )
    }
}
