import XCTest
import Observation
import KeyKeyEngine
@testable import KeyKeyApp

final class SettingsModelRestoreTests: XCTestCase {
    private let defaults = UserDefaults.standard
    private var domain = ""
    private var original: [String: Any]?

    override func setUpWithError() throws {
        try super.setUpWithError()
        let candidate = Bundle.main.bundleIdentifier ?? ProcessInfo.processInfo.processName
        guard !candidate.hasPrefix("com.dragonapp."),
              candidate.contains("xctest") || candidate.contains("KeyKeyAppPackageTests") else {
            throw NSError(domain: "UnsafePreferencesTestDomain", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: candidate])
        }
        domain = candidate
        print("SettingsModel tests use isolated test process domain: \(domain)")
        original = defaults.persistentDomain(forName: domain)
        defaults.removePersistentDomain(forName: domain)
        Preferences.registerDefaults()
    }

    override func tearDownWithError() throws {
        if !domain.isEmpty {
            if let original { defaults.setPersistentDomain(original, forName: domain) }
            else { defaults.removePersistentDomain(forName: domain) }
        }
        try super.tearDownWithError()
    }

    @MainActor
    func testSyncRereadsAllFourControlsWithoutReloadingResources() {
        let model = SettingsModel(onCangjieVersionChange: {
            XCTFail("Reading restored preferences must not reload resources through a UI setter")
        })
        defaults.setPersistentDomain([
            "candidateFontSize": 24.0,
            "cangjieVersion": "3",
            "zhuyinLayout": "eten",
            "associationSelectionTrigger": "shift",
        ], forName: domain)
        let restored = defaults.persistentDomain(forName: domain)! as NSDictionary

        model.syncFromPreferences()

        XCTAssertEqual(model.candidateFontSize, 24)
        XCTAssertEqual(model.cangjieVersion, .v3)
        XCTAssertEqual(model.zhuyinLayout, .eten)
        XCTAssertEqual(model.associationTrigger, .shift)
        XCTAssertEqual(defaults.persistentDomain(forName: domain)! as NSDictionary, restored)
    }

    @MainActor
    func testSyncPreservesAnAbsentDefaultsSnapshotAndConverges() {
        Preferences.candidateFontSize = 26
        Preferences.cangjieVersion = .v3
        Preferences.zhuyinLayout = .eten
        Preferences.associationSelectionTrigger = .shift
        let model = SettingsModel(onCangjieVersionChange: {
            XCTFail("Synchronizing a restored snapshot must not invoke the UI resource callback")
        })
        defaults.setPersistentDomain(["restoredMarker": "keep"], forName: domain)
        let restored = defaults.persistentDomain(forName: domain)! as NSDictionary

        model.syncFromPreferences()
        model.syncFromPreferences()

        XCTAssertEqual(model.candidateFontSize, 18)
        XCTAssertEqual(model.cangjieVersion, .v5)
        XCTAssertEqual(model.zhuyinLayout, .dachen)
        XCTAssertEqual(model.associationTrigger, .number)
        XCTAssertEqual(defaults.persistentDomain(forName: domain)! as NSDictionary, restored)
    }

    @MainActor
    func testBooleanOnlyRestoreInvalidatesEveryComputedBinding() async {
        let model = SettingsModel(onCangjieVersionChange: {
            XCTFail("A boolean-only reload must not invoke the UI resource callback")
        })
        let bindings: [(KeyPath<SettingsModel, Bool>, String, Bool)] = [
            (\.outputSimplified, "outputSimplifiedEnabled", true),
            (\.fullWidthPunctuation, "fullWidthPunctuationEnabled", false),
            (\.shiftSpaceFullWidthSpace, "shiftSpaceFullWidthSpaceEnabled", true),
            (\.associatedPhrases, "associatedPhrasesEnabled", false),
            (\.associationContinuationOnly, "associationContinuationOnly", true),
            (\.codeHint, "codeHintEnabled", true),
            (\.zhuyinSmart, "zhuyinSmartEnabled", true),
            (\.strokeConfirmation, "strokeConfirmationEnabled", true),
            (\.completions, "completionsEnabled", true),
            (\.adaptiveCandidateOrder, "adaptiveCandidateOrderEnabled", false),
        ]
        let invalidations = bindings.map { binding in
            let invalidation = expectation(description: "restored binding " + binding.1)
            withObservationTracking {
                _ = model[keyPath: binding.0]
            } onChange: {
                invalidation.fulfill()
            }
            return invalidation
        }
        let restored = Dictionary(uniqueKeysWithValues: bindings.map { ($0.1, $0.2) })
        defaults.setPersistentDomain(restored, forName: domain)

        model.syncFromPreferences()

        await fulfillment(of: invalidations, timeout: 1)
        for binding in bindings {
            XCTAssertEqual(model[keyPath: binding.0], binding.2)
        }
        XCTAssertEqual(model.candidateFontSize, 18)
        XCTAssertEqual(model.cangjieVersion, .v5)
        XCTAssertEqual(model.zhuyinLayout, .dachen)
        XCTAssertEqual(model.associationTrigger, .number)
        XCTAssertEqual(defaults.persistentDomain(forName: domain)! as NSDictionary, restored as NSDictionary)
    }

    @MainActor
    func testInputMenuSmartSelectionChangeInvalidatesTheSettingsBinding() async {
        let model = SettingsModel(onCangjieVersionChange: {})
        let invalidation = expectation(description: "smart selection changed in the input menu")
        withObservationTracking {
            _ = model.zhuyinSmart
        } onChange: {
            invalidation.fulfill()
        }

        Preferences.zhuyinSmartEnabled = true
        NotificationCenter.default.post(name: .zhuyinLayoutChanged, object: nil)

        await fulfillment(of: [invalidation], timeout: 1)
        XCTAssertTrue(model.zhuyinSmart)
    }

    @MainActor
    func testOrdinaryControlEditsPersistAndReloadChangedTablesOnce() {
        var tableReloads = 0
        let model = SettingsModel(onCangjieVersionChange: { tableReloads += 1 })

        model.candidateFontSize = 22
        model.cangjieVersion = .v3
        model.zhuyinLayout = .eten
        model.associationTrigger = .shift

        XCTAssertEqual(Preferences.candidateFontSize, 22)
        XCTAssertEqual(Preferences.cangjieVersion, .v3)
        XCTAssertEqual(Preferences.zhuyinLayout, .eten)
        XCTAssertEqual(Preferences.associationSelectionTrigger, .shift)
        XCTAssertEqual(tableReloads, 1)
        model.syncFromPreferences()
        XCTAssertEqual(tableReloads, 1)
    }

    @MainActor
    func testChoosingAnAlreadyDisplayedValueStillUpdatesChangedPreferences() {
        var tableReloads = 0
        let model = SettingsModel(onCangjieVersionChange: { tableReloads += 1 })
        Preferences.candidateFontSize = 24
        Preferences.cangjieVersion = .v3
        Preferences.associationSelectionTrigger = .shift

        model.candidateFontSize = 18
        model.cangjieVersion = .v5
        model.associationTrigger = .number

        XCTAssertEqual(Preferences.candidateFontSize, 18)
        XCTAssertEqual(Preferences.cangjieVersion, .v5)
        XCTAssertEqual(Preferences.associationSelectionTrigger, .number)
        XCTAssertEqual(tableReloads, 1)
    }
}
