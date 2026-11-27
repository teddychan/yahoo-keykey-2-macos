import XCTest
@testable import KeyKeyEngine

// Runs only when Resources/cangjie.txt is present (the bundled real Cangjie 5 table).
// Loaded lazily by path so the unit tests above stay independent of the large file.
final class RealCangjieTableTests: XCTestCase {
    private func tableURL() -> URL? {
        var dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        for _ in 0..<8 {
            let candidate = dir.appendingPathComponent("Resources/cangjie.txt")
            if FileManager.default.fileExists(atPath: candidate.path) { return candidate }
            dir = dir.deletingLastPathComponent()
        }
        return nil
    }

    func testRealTableLoadsAndLooksUpCommonCharacters() throws {
        guard let url = tableURL() else {
            throw XCTSkip("Resources/cangjie.txt not present")
        }
        let table = try CangjieTable(contentsOf: url)
        // 日 is encoded by a single "a" radical; 明 by "ab" (日月).
        XCTAssertTrue(table.characters(forCode: "a").contains("日"))
        XCTAssertTrue(table.characters(forCode: "ab").contains("明"))

        let e = CangjieEngine(table: table, tableVersion: "5")
        _ = e.handleKey("a"); _ = e.handleKey("b")
        XCTAssertEqual(e.composingText, "日月")
        XCTAssertTrue(e.candidates.contains("明"))
    }

    func testRealTableSpells應As戈土心AsWellAs戈人土心() throws {
        guard let url = tableURL() else {
            throw XCTSkip("Resources/cangjie.txt not present")
        }
        let table = try CangjieTable(contentsOf: url)
        // 應's classical 五代 code is 戈人土心 (iogp), but 戈土心 (igp) is the shorthand many
        // 倉頡 typists have always used (and what the 三代 Yahoo table carries). Keep both, so
        // 戈土心 is not a dead code here.
        XCTAssertTrue(table.characters(forCode: "iogp").contains("應"))
        XCTAssertTrue(table.characters(forCode: "igp").contains("應"))
    }

    func testRealTableOffers有And冇For大月() throws {
        guard let url = tableURL() else {
            throw XCTSkip("Resources/cangjie.txt not present")
        }
        let table = try CangjieTable(contentsOf: url)
        let engine = CangjieEngine(table: table, tableVersion: "5")
        _ = engine.handleKey("k"); _ = engine.handleKey("b")
        // The multi-candidate case Space / 1–9 has to decide: 大月 is 有 or 冇.
        XCTAssertGreaterThan(engine.candidates.count, 1)
        XCTAssertTrue(engine.candidates.contains("有"))
        XCTAssertTrue(engine.candidates.contains("冇"))
    }

    func testRealTableContainsNoTofuCharacters() throws {
        guard let url = tableURL() else {
            throw XCTSkip("Resources/cangjie.txt not present")
        }
        let table = try CangjieTable(contentsOf: url)
        var checked = 0
        table.forEachEntry { _, chars in
            for char in chars {
                XCTAssertTrue(
                    char.count == 1 && CangjieTable.isRenderableCJK(char.first!),
                    "Tofu/unrenderable character survived the load-time filter: \(char.unicodeScalars.map { String(format: "U+%04X", $0.value) }.joined())"
                )
                checked += 1
            }
        }
        XCTAssertGreaterThan(checked, 0)
    }
}
