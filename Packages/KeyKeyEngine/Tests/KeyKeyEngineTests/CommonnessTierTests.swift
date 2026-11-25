import XCTest
@testable import KeyKeyEngine

final class CommonnessTierTests: XCTestCase {
    func testBig5LevelsAndHongKongCharacters() {
        XCTAssertEqual(CommonnessTier("我"), .common)
        XCTAssertEqual(CommonnessTier("藥"), .common)
        XCTAssertEqual(CommonnessTier("淼"), .lessCommon)
        XCTAssertEqual(CommonnessTier("靚"), .lessCommon)
        XCTAssertEqual(CommonnessTier("嘅"), .hongKong)
        XCTAssertEqual(CommonnessTier("咗"), .hongKong)
        XCTAssertEqual(CommonnessTier("啲"), .hongKong)
    }

    func testFormsOutsideBig5AndHKSCSAreOther() {
        XCTAssertEqual(CommonnessTier("薬"), .other)   // the Japanese form of 藥
        XCTAssertEqual(CommonnessTier("丢"), .other)   // the simplified form of 丟
        XCTAssertEqual(CommonnessTier("㭟"), .other)   // CJK Extension A
    }

    func testNonIdeographsHaveNoTierToCompare() {
        // Big5 encodes punctuation too, outside its two character levels; none of it is ranked
        // against anything, so a z-code punctuation list keeps the table's order.
        for ch: Character in ["，", "「", "【", "〖", "a", "1"] {
            XCTAssertEqual(CommonnessTier(ch), .other, "\(ch)")
        }
    }

    func testMoreCommonComparesFirst() {
        XCTAssertLessThan(CommonnessTier.common, .lessCommon)
        XCTAssertLessThan(CommonnessTier.lessCommon, .hongKong)
        XCTAssertLessThan(CommonnessTier.hongKong, .other)
    }

    func testLevelSizesMatchBig5() {
        // The tiers come from the converter macOS ships, so pin it to Big5's published level sizes:
        // a change in that converter fails here rather than quietly reordering candidate lists.
        var counts: [CommonnessTier: Int] = [:]
        for range in [0x3400...0x4DBF, 0x4E00...0x9FFF, 0xF900...0xFAFF] as [ClosedRange<UInt32>] {
            for value in range {
                guard let scalar = Unicode.Scalar(value) else { continue }
                counts[CommonnessTier(Character(scalar)), default: 0] += 1
            }
        }
        XCTAssertEqual(counts[.common], 5_401)
        XCTAssertEqual(counts[.lessCommon], 7_652)
    }
}
