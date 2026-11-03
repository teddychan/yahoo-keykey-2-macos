import Foundation
import DragonKit

// "What's New" content for the current release. The version is not passed — it defaults to
// CFBundleShortVersionString and the kit adds the "v", so the pane cannot claim a release the
// binary isn't. That makes the entries and the date the only things to keep in sync with
// CHANGELOG.md on release.
//
// 2.16.3 fixes keys leaking to the app over a live composition (issue #160): in 倉頡, 速成 and
// 注音, a comma, Tab, Shift+1 or similar key the engine does not take was handed to the app while
// the character was still marked, so it replaced the marked text and the next Space committed the
// character after it. The composition is now committed first and the key handled from idle.
//
// Announced as a single `.fixed` entry, naming the three methods and what the typist sees. 拼音
// is mentioned only in the summary, as already working this way.
//
// Deliberately NOT in the notes: the build script's SDK lookup, which a user never meets.
//
// Keys are the fleet's stable set (app.whatsNew.summary, .added1, .changed1, …), not named after
// this release's content — a release just overwrites the same keys' text in all seven .strings
// files rather than adding new ones and stranding the last release's. This release has no `.added`
// and no `.changed` entry, so 2.16.2's `.changed1` is retired from all seven files rather than
// left stranded.
enum WhatsNewConfig {
    @MainActor
    static var content: WhatsNewContent {
        WhatsNewContent(
            date: "2026-11-03",
            summary: L("app.whatsNew.summary"),
            sections: [
                ChangeSection(kind: .fixed, entries: [
                    L("app.whatsNew.fixed1"),
                ]),
            ]
        )
    }
}
