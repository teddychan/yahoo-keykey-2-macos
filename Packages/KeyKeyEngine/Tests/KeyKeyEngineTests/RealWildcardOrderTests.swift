import XCTest
@testable import KeyKeyEngine

// Wildcard lists against the REAL bundled tables and language model, built the way the app builds
// its engines. In 三代, 廿*木 used to list its 93 candidates in code order, which put 藥 on page 8.
// Skips when the resources are absent — `Resources/data.txt` is generated, not committed.
final class RealWildcardOrderTests: XCTestCase {
    private struct Fixtures {
        let yahoo: CangjieTable
        let cangjie: CangjieTable
        let rank: [Character: Double]
    }

    private func url(_ rel: String) -> URL? {
        var dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        for _ in 0..<8 {
            let c = dir.appendingPathComponent(rel)
            if FileManager.default.fileExists(atPath: c.path) { return c }
            dir = dir.deletingLastPathComponent()
        }
        return nil
    }

    private func load() throws -> Fixtures {
        guard let yahooURL = url("Resources/cangjie-yahoo.txt"),
              let cangjieURL = url("Resources/cangjie.txt"),
              let dataURL = url("Resources/data.txt") else {
            throw XCTSkip("Resources/cangjie-yahoo.txt, cangjie.txt or data.txt not present")
        }
        let text = try String(contentsOf: dataURL, encoding: .utf8)
        return Fixtures(yahoo: try CangjieTable(contentsOf: yahooURL),
                        cangjie: try CangjieTable(contentsOf: cangjieURL),
                        rank: LanguageModel.characterScores(fromText: text))
    }

    /// The candidates a fresh 三代 or 五代 engine offers for `code`, configured as the app does.
    private func candidates(_ code: String, version: String, _ f: Fixtures) -> [String] {
        let e = CangjieEngine(table: version == "3" ? f.yahoo : f.cangjie, characterRank: f.rank,
                              keepsTableOrderForExactCodes: version == "3", tableVersion: version)
        code.forEach { _ = e.handleKey($0) }
        return e.candidates
    }

    func testThreeGenerationWildcardPutsCommonCharactersOnPageOne() throws {
        let f = try load()
        // 廿*木 for 藥 (廿女戈木): was #71 of 93.
        let tadeo = candidates("t*d", version: "3", f)
        XCTAssertEqual(tadeo.first, "業")
        XCTAssertTrue(tadeo.prefix(9).contains("藥"), "\(tadeo.prefix(9))")
        // 竹*戈: was 㿝 䇗 私 㦵 丟 丢 …, with 我 12th and 的 18th.
        XCTAssertEqual(Array(candidates("h*i", version: "3", f).prefix(2)), ["的", "我"])
    }

    func testThreeGenerationNarrowedWildcardLeadsWithTheCommonCharacter() throws {
        let f = try load()
        // 廿女*木: 藥 was second, behind the rare 虊.
        XCTAssertEqual(candidates("tv*d", version: "3", f).first, "藥")
    }

    func testWildcardListsEachCharacterOnce() throws {
        let f = try load()
        for version in ["3", "5"] {
            let list = candidates("h*i", version: version, f)
            XCTAssertEqual(Set(list).count, list.count, "竹*戈 in \(version)代 repeats a character")
        }
    }

    func testControlKeysNoLongerOutrankRealCharacters() throws {
        let f = try load()
        // 仝 took 0.0 from `_kana_dou`, above 的 (the most common character there is).
        let de = try XCTUnwrap(f.rank["的"])
        XCTAssertLessThan(f.rank["仝"] ?? -.infinity, de)
    }
}
