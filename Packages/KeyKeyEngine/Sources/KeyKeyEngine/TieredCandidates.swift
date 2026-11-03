// The candidates for one 倉頡 or 速成 code: its exact matches, then its completions (characters
// whose code goes on past the typed one), which are empty unless the typist turned completions on.
//
// Each tier is its own candidate list, ordered and learned on its own. That is what keeps the
// exact matches first however often a completion is picked, and what leaves the exact list's
// learning untouched when completions are switched on or off.
struct TieredCandidates {
    static let none = TieredCandidates(exact: [], in: nil)

    let all: [String]
    /// How many leading entries of `all` are exact matches.
    let exactCount: Int
    private let exactList: CandidateListKey?
    private let completionList: CandidateListKey?

    /// A completion that is also an exact match (a character with two codes) is shown once, as
    /// the exact match.
    init(exact: [String], in exactList: CandidateListKey?,
         completions: [String] = [], in completionList: CandidateListKey? = nil) {
        let exactSet = Set(exact)
        all = exact + completions.filter { !exactSet.contains($0) }
        exactCount = exact.count
        self.exactList = exactList
        self.completionList = completionList
    }

    /// What committing `candidate` credits: the candidate, in the tier it is picked from. Empty
    /// for a tier of one, which has no order to learn.
    func usage(of candidate: String) -> [CandidateUsage] {
        guard let index = all.firstIndex(of: candidate) else { return [] }
        let (list, size) = index < exactCount
            ? (exactList, exactCount)
            : (completionList, all.count - exactCount)
        guard size > 1, let list else { return [] }
        return [CandidateUsage(list: list, candidate: candidate)]
    }
}
