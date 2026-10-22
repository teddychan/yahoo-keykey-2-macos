import Foundation
import DragonKit

// Observable bridge between the DragonKit settings UI (SwiftUI) and KeyKey's persisted
// preferences. Every property forwards to the existing `Preferences` accessors, which the
// input engine, candidate window, and SharedResources read LIVE — so a change in the
// General pane applies on the next composition without restarting the IME, exactly as the
// input-menu toggles do.
//
// Settings preservation: this deliberately does NOT introduce a new UserDefaults suite or a
// single JSON blob. It reads and writes the SAME individual keys in the SAME domain
// (UserDefaults.standard, i.e. the IME's bundle-id domain) that `Preferences` has always
// used, so an existing install's settings are read unchanged and never reset. `DragonBackup`
// still snapshots the whole domain by name (see AppMenuController.backupConfig).
@MainActor
@Observable
final class SettingsModel {
    // The domain KeyKey has always persisted into: the IME process's standard defaults, whose
    // name is the app's bundle id. Backup snapshots this whole domain.
    static var suiteName: String { Bundle.main.bundleIdentifier ?? "com.dragonapp.inputmethod.yahoo-keykey" }

    private var preferencesRevision: UInt = 0

    var outputSimplified: Bool {
        get {
            _ = preferencesRevision
            return Preferences.outputSimplifiedEnabled
        }
        set { Preferences.outputSimplifiedEnabled = newValue }
    }

    var fullWidthPunctuation: Bool {
        get {
            _ = preferencesRevision
            return Preferences.fullWidthPunctuationEnabled
        }
        set { Preferences.fullWidthPunctuationEnabled = newValue }
    }

    // Shift + 空白鍵輸入全形空白 (issue #135). A plain toggle, so a computed forwarder is fine;
    // InputController reads Preferences live on every key press.
    var shiftSpaceFullWidthSpace: Bool {
        get {
            _ = preferencesRevision
            return Preferences.shiftSpaceFullWidthSpaceEnabled
        }
        set { Preferences.shiftSpaceFullWidthSpaceEnabled = newValue }
    }

    var associatedPhrases: Bool {
        get {
            _ = preferencesRevision
            return Preferences.associatedPhrasesEnabled
        }
        set { Preferences.associatedPhrasesEnabled = newValue }
    }

    // 聯想只顯示接續字 (v2.2.0 feature): show only the continuation after the committed character
    // in the 聯想 window. Forwards to the pre-existing Preferences key (not redefined here).
    var associationContinuationOnly: Bool {
        get {
            _ = preferencesRevision
            return Preferences.associationContinuationOnly
        }
        set { Preferences.associationContinuationOnly = newValue }
    }

    // 反查/拆碼提示: show each single character's 倉頡 code in the candidate window.
    var codeHint: Bool {
        get {
            _ = preferencesRevision
            return Preferences.codeHintEnabled
        }
        set { Preferences.codeHintEnabled = newValue }
    }

    // 以空白鍵確認字根 (issue #61): in 速成 / 倉頡-with-`*`, require one Space press to confirm the
    // typed strokes before Space resumes paging or committing. A plain toggle, so a computed
    // forwarder is fine here — only Picker/Slider need the stored-property treatment below.
    // 智慧選字. A computed forwarder (it drives a Toggle, not a menu Picker); the write also posts the
    // notification every live engine rebuilds on, the same one the input menu's toggle posts.
    var zhuyinSmart: Bool {
        get { Preferences.zhuyinSmartEnabled }
        set {
            guard newValue != Preferences.zhuyinSmartEnabled else { return }
            Preferences.zhuyinSmartEnabled = newValue
            NotificationCenter.default.post(name: .zhuyinLayoutChanged, object: nil)
        }
    }

    var strokeConfirmation: Bool {
        get {
            _ = preferencesRevision
            return Preferences.strokeConfirmationEnabled
        }
        set { Preferences.strokeConfirmationEnabled = newValue }
    }

    // 顯示字根開頭相同的字: list 倉頡/速成 completions after the exact matches. A plain toggle; the
    // engines read Preferences live, so the next code typed picks it up.
    var completions: Bool {
        get {
            _ = preferencesRevision
            return Preferences.completionsEnabled
        }
        set { Preferences.completionsEnabled = newValue }
    }

    // 依選字習慣調整候選字順序 (issue #85): whether user learning ranks candidates and 聯想, or the
    // built-in order stands. Another plain toggle, so a computed forwarder is right — InputController
    // reads Preferences live on every sort and every commit, so nothing needs rebuilding here.
    var adaptiveCandidateOrder: Bool {
        get {
            _ = preferencesRevision
            return Preferences.adaptiveCandidateOrderEnabled
        }
        set { Preferences.adaptiveCandidateOrderEnabled = newValue }
    }

    // Candidate text size. Like `cangjieVersion` below, this is a STORED, observation-tracked
    // property (seeded from Preferences at init) — NOT a computed forwarder. An @Observable
    // *computed* property bound to a Slider never registers an observation dependency in its
    // getter, so SwiftUI drops the change: the slider (and its "N pt" label) appear frozen while
    // dragging. A stored property is tracked, so the value updates live. `didSet` writes through
    // to Preferences, which the candidate window reads directly on the next composition.
    var candidateFontSize: Double = Double(Preferences.candidateFontSize) {
        didSet {
            guard CGFloat(candidateFontSize) != Preferences.candidateFontSize else { return }
            Preferences.candidateFontSize = CGFloat(candidateFontSize)
        }
    }

    // 倉頡版本 (Cangjie table). This is a STORED, observation-tracked property (seeded from
    // Preferences at init) — NOT a computed forwarder like the toggles above. A menu-style
    // Picker bound to an @Observable *computed* property silently reverts its selection (the
    // getter never registers an observation dependency, so SwiftUI drops the change); a stored
    // property is tracked, so the Picker sticks. `didSet` writes through to Preferences (the
    // engine reads that directly) and reloads the shared tables + live engines.
    var cangjieVersion: CangjieVersion = Preferences.cangjieVersion {
        didSet {
            guard cangjieVersion != Preferences.cangjieVersion else { return }
            Preferences.cangjieVersion = cangjieVersion
            onCangjieVersionChange()
        }
    }

    // 注音鍵盤. Stored + observation-tracked like `cangjieVersion` above (a computed forwarder
    // would make the menu-style Picker's selection silently revert). `didSet` writes through to
    // Preferences and posts the notification every live engine rebuilds on — the same one the
    // input menu's 注音鍵盤 items post, so both routes to this setting behave identically.
    // Nothing in SharedResources is reloaded: the ㄅ半 table is the same table whichever keyboard
    // types it.
    //
    // Unlike cangjieVersion, this setting has a SECOND writer — the input menu writes Preferences
    // directly — so this mirror can fall behind it. Two things keep that harmless. The guard
    // compares against Preferences, not oldValue, so picking the value a stale Picker already
    // shows is still written; comparing against oldValue made that pick a no-op, and the user could
    // not switch back from Settings at all. And init follows .zhuyinLayoutChanged, so the Picker
    // tracks an input-menu change even while the window is open; a value re-seeded from there
    // already matches Preferences, so the guard stops it re-posting.
    var zhuyinLayout: ZhuyinLayout = Preferences.zhuyinLayout {
        didSet {
            guard zhuyinLayout != Preferences.zhuyinLayout else { return }
            Preferences.zhuyinLayout = zhuyinLayout
            NotificationCenter.default.post(name: .zhuyinLayoutChanged, object: nil)
        }
    }

    // Never removed: the one SettingsModel lives as long as the process (AppMenuController.shared),
    // and the block holds it weakly.
    @ObservationIgnored private var zhuyinLayoutObserver: NSObjectProtocol?

    @ObservationIgnored private let onCangjieVersionChange: () -> Void

    init(onCangjieVersionChange: @escaping () -> Void) {
        self.onCangjieVersionChange = onCangjieVersionChange
        zhuyinLayoutObserver = NotificationCenter.default.addObserver(
            forName: .zhuyinLayoutChanged, object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            // Only when behind: a change made in this window already matches Preferences, and
            // skipping it avoids re-entering didSet from inside its own post.
            MainActor.assumeIsolated {
                let current = Preferences.zhuyinLayout
                if self.zhuyinLayout != current { self.zhuyinLayout = current }
            }
        }
    }

    // 聯想選字鍵 (issue #52). Stored + observation-tracked like `cangjieVersion` above so the
    // menu-style Picker selection sticks (a computed forwarder would silently revert). `didSet`
    // writes through to Preferences, which InputController reads live on the next composition.
    var associationTrigger: AssociationTrigger = Preferences.associationSelectionTrigger {
        didSet {
            guard associationTrigger != Preferences.associationSelectionTrigger else { return }
            Preferences.associationSelectionTrigger = associationTrigger
        }
    }

    var minFontSize: Double { Double(Preferences.minFontSize) }
    var maxFontSize: Double { Double(Preferences.maxFontSize) }

    // Restoring a domain bypasses UI setters. Read all mirrors without persisting default values,
    // then invalidate computed bindings even when only a boolean changed in the snapshot.
    func syncFromPreferences() {
        candidateFontSize = Double(Preferences.candidateFontSize)
        cangjieVersion = Preferences.cangjieVersion
        zhuyinLayout = Preferences.zhuyinLayout
        associationTrigger = Preferences.associationSelectionTrigger
        preferencesRevision &+= 1
    }
}
