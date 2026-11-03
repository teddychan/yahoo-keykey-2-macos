import Foundation
import DragonKit

// "What's New" content for the current release. The version is not passed — it defaults to
// CFBundleShortVersionString and the kit adds the "v", so the pane cannot claim a release the
// binary isn't. That makes the entries and the date the only things to keep in sync with
// CHANGELOG.md on release.
//
// 2.17.0 adds 顯示字根開頭相同的字, off by default: 倉頡 and 速成 list completions after the exact
// matches, so typing 竹 also offers 我 (竹手戈), as 竹* would.
//
// Announced as a single `.added` entry naming where the setting is, the 竹 → 我 example, and that
// Space still types the exact match.
//
// Keys are the fleet's stable set (app.whatsNew.summary, .added1, .changed1, …), not named after
// this release's content — a release just overwrites the same keys' text in all seven .strings
// files rather than adding new ones and stranding the last release's. This release has no `.fixed`
// entry, so 2.16.3's `.fixed1` is retired from all seven files rather than left stranded.
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
