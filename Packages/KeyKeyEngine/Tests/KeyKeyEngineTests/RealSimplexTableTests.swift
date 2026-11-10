import XCTest
@testable import KeyKeyEngine

final class RealSimplexTableTests: XCTestCase {
    private func tableURL(_ resource: String = "cangjie") -> URL? {
        var dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        for _ in 0..<8 {
            let candidate = dir.appendingPathComponent("Resources/\(resource).txt")
            if FileManager.default.fileExists(atPath: candidate.path) { return candidate }
            dir = dir.deletingLastPathComponent()
        }
        return nil
    }

    func testRealTableDerivesAndLooksUpCommonCharacters() throws {
        guard let url = tableURL() else {
            throw XCTSkip("Resources/cangjie.txt not present")
        }
        let cangjie = try CangjieTable(contentsOf: url)
        let simplex = SimplexTable(cangjie: cangjie)
        // 日 is encoded by a single "a" radical -> simplex "a"; 明 by "ab" (日月) -> simplex "ab".
        XCTAssertTrue(simplex.characters(forCode: "a").contains("日"))
        XCTAssertTrue(simplex.characters(forCode: "ab").contains("明"))
    }

    func testYahooTableFiltersUnsupportedCharactersFromReportedCandidatePages() throws {
        let url = try XCTUnwrap(tableURL("simplex-yahoo"))
        let simplex = try SimplexTable(quickCodeContentsOf: url)
        let yl = simplex.characters(forCode: "yl")
        let isCode = simplex.characters(forCode: "is")

        XCTAssertEqual(yl.count, 55)
        XCTAssertEqual(Array(yl.dropFirst(18).prefix(9)), ["鄐", "鄣", "齗", "齘", "凁", "訠", "龂", "凘", "亣"])
        XCTAssertEqual(isCode.count, 25)
        XCTAssertEqual(Array(isCode.dropFirst(9).prefix(9)), ["勆", "㢚", "劺", "䄘", "书", "祎", "房", "诱", "诚"])
    }
}
