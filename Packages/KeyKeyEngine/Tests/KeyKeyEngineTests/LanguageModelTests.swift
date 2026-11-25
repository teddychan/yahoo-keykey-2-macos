import XCTest
@testable import KeyKeyEngine

final class LanguageModelTests: XCTestCase {
    static let fixture = """
    # format org.openvanilla.mcbopomofo.sorted
    ㄅㄚ 八 -3.27631260
    ㄅㄚ 吧 -3.59800309
    ㄇㄠ 貓 -4.10000000
    ㄇㄠ-ㄇㄧ 貓咪 -5.20000000
    """

    func testLookupReturnsUnigramsInOrder() {
        let lm = LanguageModel(text: Self.fixture)
        let u = lm.unigrams(forKey: "ㄅㄚ")
        XCTAssertEqual(u.map(\.value), ["八", "吧"])
        XCTAssertEqual(u.first?.score ?? 0, -3.27631260, accuracy: 1e-6)
    }

    func testMultiSyllableKey() {
        let lm = LanguageModel(text: Self.fixture)
        XCTAssertEqual(lm.unigrams(forKey: "ㄇㄠ-ㄇㄧ").map(\.value), ["貓咪"])
    }

    func testHeaderAndBlanksIgnored() {
        let lm = LanguageModel(text: Self.fixture)
        XCTAssertTrue(lm.unigrams(forKey: "# format org.openvanilla.mcbopomofo.sorted").isEmpty)
    }

    func testMissingKey() {
        let lm = LanguageModel(text: Self.fixture)
        XCTAssertTrue(lm.unigrams(forKey: "ㄓㄨ").isEmpty)
        XCTAssertFalse(lm.hasKey("ㄓㄨ"))
        XCTAssertTrue(lm.hasKey("ㄅㄚ"))
    }

    func testCharacterScoresKeepsSingleCharsAndMaxScore() {
        let lm = LanguageModel(text: Self.fixture)
        let scores = lm.characterScores()
        // Single-char values only; multi-char "貓咪" excluded.
        XCTAssertEqual(Set(scores.keys), Set(["八", "吧", "貓"]))
        // 貓 appears once at -4.1.
        XCTAssertEqual(scores["貓"] ?? 0, -4.10000000, accuracy: 1e-6)
    }

    func testCharacterScoresRecordsMaxAcrossEntries() {
        // 我 appears under two readings with different scores; keep the larger.
        let lm = LanguageModel(text: """
        ㄨㄛ 我 -5.00000000
        ㄜ 我 -3.00000000
        """)
        XCTAssertEqual(lm.characterScores()["我"] ?? 0, -3.00000000, accuracy: 1e-6)
    }

    func testControlKeyEntriesAreNotAFrequency() {
        // McBopomofo maps keys such as `_punctuation_list` and `_kana_dou` to characters at a
        // placeholder 0.0. That is not how often the character is used: counted, it put the rare
        // 仝 at the very top of the scale. Only the real readings may score a character.
        let text = """
        _punctuation_list 十 0.0
        ㄕˊ 十 -3.50000000
        _kana_dou 仝 0.0
        _punctuation_list ， 0.0
        """
        for scores in [LanguageModel(text: text).characterScores(),
                       LanguageModel.characterScores(fromText: text)] {
            XCTAssertEqual(Set(scores.keys), ["十"])
            XCTAssertEqual(scores["十"] ?? 0, -3.50000000, accuracy: 1e-6)
        }
    }

    func testStreamingCharacterScoresMatchesFullBuild() {
        // The streaming launch path must produce exactly the same ranking as building the full
        // LM and calling characterScores(); it just skips the transient full table.
        let cases = [
            Self.fixture,
            """
            ㄨㄛ 我 -5.00000000
            ㄜ 我 -3.00000000
            ㄋㄧ-ㄏㄠ 你好 -6.00000000
            """,
            "# only a header, no entries",
            "",
        ]
        for text in cases {
            XCTAssertEqual(LanguageModel.characterScores(fromText: text),
                           LanguageModel(text: text).characterScores())
        }
    }
}
