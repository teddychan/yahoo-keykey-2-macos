import Foundation
import DragonKit

// "What's New" content for the current release. The version is not passed — it defaults to
// CFBundleShortVersionString and the kit adds the "v", so the pane cannot claim a release the
// binary isn't. That makes the entries and the date the only things to keep in sync with
// CHANGELOG.md on release.
//
// Keys are the fleet's stable set (app.whatsNew.summary, .added1, .changed1, …), not named after
// this release's content — a release just overwrites the same keys' text in every locale's .strings
// file rather than adding new ones and stranding the last release's.
enum WhatsNewConfig {
    @MainActor
    static var content: WhatsNewContent {
        WhatsNewContent(
            date: "2026-11-08",
            summary: L("app.whatsNew.summary"),
            sections: [
                ChangeSection(kind: .fixed, entries: [
                    L("app.whatsNew.changed1"),
                ]),
            ]
        )
    }
}
