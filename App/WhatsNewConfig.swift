import Foundation
import DragonKit

// "What's New" content for the current release. The version is not passed — it defaults to
// CFBundleShortVersionString and the kit adds the "v", so the pane cannot claim a release the
// binary isn't. That makes the entries and the date the only things to keep in sync with
// CHANGELOG.md on release.
//
// 2.19.0 is a maintenance release: the only change is the move to DragonKit 4.4.0. KeyKey passes no
// `BackupConfig.contents`, and the kit's new always-cleared `<bundle id>.settings` suite is one
// KeyKey never writes (its settings live in the bundle-id domain), so Backup & Restore and
// Uninstall behave as in 2.18.1. One `.changed` entry says exactly that, the same treatment 2.18.1
// got. There is no kind for "nothing you can see", and inventing a user-facing change to fill the
// slot is the one thing this pane must never do.
//
// Keys are the fleet's stable set (app.whatsNew.summary, .added1, .changed1, …), not named after
// this release's content — a release just overwrites the same keys' text in every locale's .strings
// file rather than adding new ones and stranding the last release's. 2.18.1 was also one `.changed`
// entry, so the keys are unchanged and only their text moves on, in all eight files.
enum WhatsNewConfig {
    @MainActor
    static var content: WhatsNewContent {
        WhatsNewContent(
            date: "2026-11-07",
            summary: L("app.whatsNew.summary"),
            sections: [
                ChangeSection(kind: .changed, entries: [
                    L("app.whatsNew.changed1"),
                ]),
            ]
        )
    }
}
