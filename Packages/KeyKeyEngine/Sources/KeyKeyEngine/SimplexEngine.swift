// Simplex (簡易) engine: accumulate radical letter keys (a–z), look up the matching
// characters in the SimplexTable, then select/commit. Mirrors the CangjieEngine surface
// (handleKey/composingText/candidates/selectCandidate/commit/backspace). Reuses
// CangjieEngine.radicals for the composing-display glyphs.
public final class SimplexEngine {
    // A 速成 code is the 倉頡 first + last radical, so it is never longer than two keys —
    // see SimplexTable.simplexCode(for:). Used by keyStartsNewComposition(_:).
    private static let maxRadicals = 2

    private let table: SimplexTable
    private let characterRank: [Character: Double]
    // Which 倉頡 table this 速成 table was derived from ("5"/"3"). Part of the list identity,
    // because the two tables answer the same code with different characters.
    private let tableVersion: String
    // How many times a candidate has been committed in a given list. Consulted on every sort, so
    // a freshly-committed candidate leads next time without rebuilding the engine.
    private let usageCount: (CandidateListKey, String) -> Int
    // Whether completions follow the exact matches; read live, as on `CangjieEngine`.
    private let showsCompletions: () -> Bool
    private var code: String = ""
    private var selected: String?
    // Cached result of the candidate computation; invalidated (nil) on any state
    // change to the code. `candidates` is read multiple times per keydown.
    private var cachedTiers: TieredCandidates?

    /// `tableVersion` has no default, for the reason on `CangjieEngine.init`.
    public init(table: SimplexTable, characterRank: [Character: Double] = [:],
                tableVersion: String,
                usageCount: @escaping (CandidateListKey, String) -> Int = { _, _ in 0 },
                showsCompletions: @escaping () -> Bool = { false }) {
        self.table = table
        self.characterRank = characterRank
        self.tableVersion = tableVersion
        self.usageCount = usageCount
        self.showsCompletions = showsCompletions
    }

    /// Returns true if the key was consumed by the engine. Accepts a–z radical keys.
    @discardableResult
    public func handleKey(_ key: Character) -> Bool {
        guard CangjieEngine.radicals[key] != nil else { return false }
        code.append(key)
        selected = nil
        cachedTiers = nil
        return true
    }

    /// Whether typing `key` now must END this composition and begin a new one (issue #113).
    ///
    /// A 速成 code is two radicals at most, so a further radical key cannot belong to the code
    /// being typed — it is the start of the next character, and the original Yahoo! KeyKey
    /// commits the character in progress and carries on. Appending it instead would build a
    /// 3-key code that no 速成 table contains, leaving a composition with no candidate to pick
    /// and no way out but Backspace.
    ///
    /// The caller (InputController) commits, then feeds the key to `handleKey` on the fresh
    /// composition; false for anything `handleKey` would reject, since there is no key to carry
    /// over. Deliberately not folded into `handleKey`, which cannot commit into the client.
    public func keyStartsNewComposition(_ key: Character) -> Bool {
        code.count >= Self.maxRadicals && CangjieEngine.radicals[key] != nil
    }

    /// The radical glyphs accumulated so far (selected char once chosen).
    public var composingText: String {
        if let selected { return selected }
        return String(code.map { CangjieEngine.radicals[$0] ?? $0 })
    }

    /// Characters whose Simplex code matches the current radical sequence, then, with
    /// completions on, those of every longer code it starts. Each tier is ordered frequency-first
    /// over the built-in order (see `CandidateOrdering`); with no committed usage the table/rank
    /// order is preserved unchanged.
    public var candidates: [String] { tiers.all }

    /// How many leading `candidates` match the code exactly; the rest are completions.
    public var exactCandidateCount: Int { tiers.exactCount }

    private var tiers: TieredCandidates {
        if let cachedTiers { return cachedTiers }
        let result = computeTiers()
        cachedTiers = result
        return result
    }

    private func computeTiers() -> TieredCandidates {
        guard let list = candidateListKey else { return .none }
        let exact = ordered(table.characters(forCode: code), in: list)
        guard showsCompletions() else { return TieredCandidates(exact: exact, in: list) }
        let completionList = CandidateListKey.simplexCompletion(tableVersion: tableVersion, code: code)
        return TieredCandidates(exact: exact, in: list,
                                completions: ordered(table.characters(extending: code), in: completionList),
                                in: completionList)
    }

    private func ordered(_ matches: [String], in list: CandidateListKey) -> [String] {
        CandidateOrdering.ordered(matches, rank: characterRank) { usageCount(list, $0) }
    }

    /// Which candidate list the current code's exact matches form, or nil when nothing is being
    /// composed. Separate from the 倉頡 list of the same code, which offers a different set of
    /// characters, and from this code's completions (`.simplexCompletion`).
    public var candidateListKey: CandidateListKey? {
        code.isEmpty ? nil : .simplex(tableVersion: tableVersion, code: code)
    }

    /// What a commit right now would credit; empty after `commit()` has cleared the code, so a
    /// caller MUST read this first. See `CangjieEngine.pendingUsage`.
    public var pendingUsage: [CandidateUsage] {
        guard let candidate = selected ?? candidates.first else { return [] }
        return tiers.usage(of: candidate)
    }

    public func selectCandidate(_ index: Int) {
        let cands = candidates
        guard index >= 0, index < cands.count else { return }
        selected = cands[index]
    }

    public func backspace() {
        selected = nil
        if !code.isEmpty { code.removeLast() }
        cachedTiers = nil
    }

    @discardableResult
    public func commit() -> String {
        let text = selected ?? candidates.first ?? ""
        code = ""
        selected = nil
        cachedTiers = nil
        return text
    }
}
