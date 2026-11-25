import XCTest
@testable import KeyKeyEngine

// The ordering rule itself (issue #130): committed count first, built-in order second, and
// nothing else — no weight, no bonus added to the language-model score, no recency, and no
// stand-in number for "the language model has never heard of this character".
final class CandidateOrderingTests: XCTestCase {
    private func order(_ candidates: [String],
                       rank: [Character: Double] = [:],
                       counts: [String: Int] = [:]) -> [String] {
        CandidateOrdering.ordered(candidates, rank: rank) { counts[$0] ?? 0 }
    }

    // MARK: - The baseline (no usage at all)

    func testAFreshStorePreservesAnUntrainedListExactly() {
        // Every count zero: the list is exactly what the table and rank produced.
        let cands = ["明", "冒", "韻", "漏"]
        XCTAssertEqual(order(cands), cands)
        XCTAssertEqual(order(cands, rank: ["韻": -1.0, "漏": -2.0]), ["韻", "漏", "明", "冒"])
    }

    func testEmptyListStaysEmpty() {
        XCTAssertEqual(order([]), [])
    }

    func testTwoRankedCandidatesOrderByTheHigherRank() {
        XCTAssertEqual(order(["低", "高"], rank: ["低": -8.0, "高": -1.0]), ["高", "低"])
        XCTAssertEqual(order(["高", "低"], rank: ["低": -8.0, "高": -1.0]), ["高", "低"])
    }

    func testARankedCandidateComesBeforeAnUnrankedOne() {
        // Compared as optionals, so this holds whichever side the ranked one starts on — there
        // is no stand-in number whose magnitude has to be got right.
        XCTAssertEqual(order(["無", "有"], rank: ["有": -9.0]), ["有", "無"])
        XCTAssertEqual(order(["有", "無"], rank: ["有": -9.0]), ["有", "無"])
    }

    func testTwoUnrankedCandidatesKeepTheirSourceOrder() {
        XCTAssertEqual(order(["丙", "甲", "乙"]), ["丙", "甲", "乙"])
    }

    // MARK: - Candidates the language model has no rank for

    func testUnrankedCandidatesOrderByHowCommonTheyAre() {
        // 我 is Big5 常用, 淼 次常用, 嘅 a Hong Kong (HKSCS) character, 薬 the Japanese form of 藥.
        // None is ranked here, so how common each one is decides, whatever order they came in.
        XCTAssertEqual(order(["薬", "嘅", "淼", "我"]), ["我", "淼", "嘅", "薬"])
        XCTAssertEqual(order(["淼", "我", "薬", "嘅"]), ["我", "淼", "嘅", "薬"])
    }

    func testARankedCandidateStillBeatsAMoreCommonUnrankedOne() {
        // The commonness tier only orders the unranked tail; it never lifts a character over one
        // the language model actually ranks.
        XCTAssertEqual(order(["我", "嘅"], rank: ["嘅": -9.0]), ["嘅", "我"])
    }

    func testPunctuationKeepsItsSourceOrder() {
        // Big5 levels say nothing about punctuation, so z-code marks stay in the table's order.
        XCTAssertEqual(order(["〖", "〗", "【", "】"]), ["〖", "〗", "【", "】"])
    }

    func testKeepingTheTableOrderIgnoresRankAndTier() {
        // 三代's exact codes: Yahoo! KeyKey's own order for the code stands.
        let ordered = CandidateOrdering.ordered(["薬", "嘅", "我"], rank: ["我": -1.0],
                                                keepingTableOrder: true) { _ in 0 }
        XCTAssertEqual(ordered, ["薬", "嘅", "我"])
    }

    func testKeepingTheTableOrderStillLetsLearningLead() {
        let ordered = CandidateOrdering.ordered(["甲", "乙"], rank: [:],
                                                keepingTableOrder: true) { $0 == "乙" ? 1 : 0 }
        XCTAssertEqual(ordered, ["乙", "甲"])
    }

    func testEvenAVeryLowRankStillBeatsUnranked() {
        // A real log-probability can be large and negative; "unranked" is not a number, so no
        // magnitude of rank can accidentally fall below it.
        XCTAssertEqual(order(["無", "有"], rank: ["有": -1e9]), ["有", "無"])
        XCTAssertEqual(order(["無", "有"], rank: ["有": -.greatestFiniteMagnitude]), ["有", "無"])
    }

    // MARK: - Counting

    func testOneCommitLeadsEveryZeroCountCandidate() {
        // The whole of issue #130: a rare candidate picked once leads next time.
        XCTAssertEqual(order(["甲", "乙", "丙"], counts: ["丙": 1]), ["丙", "甲", "乙"])
    }

    func testAnUnrankedCandidateCanLeadARankedOne() {
        // Known issue #6's own example: under 卜月卜尸心, 龍 is in the language model and the
        // variant 㡣 is not. One commit of 㡣 puts it first — previously impossible at any count.
        XCTAssertEqual(order(["龍", "㡣"], rank: ["龍": -4.0]), ["龍", "㡣"])
        XCTAssertEqual(order(["龍", "㡣"], rank: ["龍": -4.0], counts: ["㡣": 1]), ["㡣", "龍"])
    }

    func testHigherCountBeatsLowerCount() {
        XCTAssertEqual(order(["日", "曰"], counts: ["日": 5, "曰": 7]), ["曰", "日"])
        XCTAssertEqual(order(["日", "曰"], counts: ["日": 7, "曰": 5]), ["日", "曰"])
    }

    func testAHigherCountHoldsItsLeadUntilTheOtherCatchesUp() {
        // A genuinely more-committed candidate stays ahead; equalling it does NOT overtake it,
        // because the built-in order decides at equal counts and there is no recency term.
        let cands = ["日", "曰"]
        XCTAssertEqual(order(cands, counts: ["日": 3, "曰": 1]), ["日", "曰"])
        XCTAssertEqual(order(cands, counts: ["日": 3, "曰": 2]), ["日", "曰"])
        XCTAssertEqual(order(cands, counts: ["日": 3, "曰": 3]), ["日", "曰"])   // caught up: built-in order
        XCTAssertEqual(order(cands, counts: ["日": 3, "曰": 4]), ["曰", "日"])   // passed it
    }

    func testEqualCountsPreserveTheBuiltInOrder() {
        let cands = ["明", "冒", "韻", "漏"]
        XCTAssertEqual(order(cands, counts: ["明": 4, "冒": 4, "韻": 4, "漏": 4]), cands)
    }

    func testEqualCountsFallBackToTheRankedBaselineNotToRecency() {
        // The same counts must give the same order however they were reached, so ordering cannot
        // depend on which candidate was committed last.
        let rank: [Character: Double] = ["曰": -2.0]
        XCTAssertEqual(order(["日", "曰"], rank: rank, counts: ["日": 5, "曰": 5]), ["曰", "日"])
        XCTAssertEqual(order(["日", "曰"], rank: rank, counts: ["曰": 5, "日": 5]), ["曰", "日"])
    }

    func testACountIsNotBlendedWithTheRank() {
        // Two candidates one commit apart order by that commit alone, no matter how far apart
        // their ranks are — there is no weight for a rank gap to outrun.
        XCTAssertEqual(order(["常", "稀"], rank: ["常": 0.0, "稀": -12.0], counts: ["稀": 1]),
                       ["稀", "常"])
        // And a rank gap never overturns a count gap, however small the count gap is.
        XCTAssertEqual(order(["常", "稀"], rank: ["常": 0.0, "稀": -12.0], counts: ["常": 1, "稀": 2]),
                       ["稀", "常"])
    }

    func testOrderingIsStableAcrossRepeatedCalls() {
        let cands = ["明", "冒", "韻", "漏"]
        let counts = ["冒": 2, "漏": 2]
        let first = order(cands, counts: counts)
        XCTAssertEqual(first, order(cands, counts: counts))
        XCTAssertEqual(first, ["冒", "漏", "明", "韻"])   // equal counts keep the built-in order
    }

    func testEachCandidateIsCountedOnce() {
        // The count reaches a locked store, so it must be read once per candidate per sort.
        var asked: [String] = []
        _ = CandidateOrdering.ordered(["明", "冒", "韻"], rank: [:]) { asked.append($0); return 0 }
        XCTAssertEqual(asked.sorted(), ["冒", "明", "韻"])
    }
}
