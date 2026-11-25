import Foundation

public struct Unigram: Equatable {
    public let value: String
    public let score: Double
    public init(value: String, score: Double) { self.value = value; self.score = score }
}

// Loads the McBopomofo "sorted" plain-text LM. Format per line: "<key> <phrase> <score>".
public struct LanguageModel {
    private var table: [String: [Unigram]] = [:]

    public init(text: String) {
        for rawLine in text.split(separator: "\n", omittingEmptySubsequences: true) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") { continue }
            let parts = line.split(separator: " ")
            guard parts.count == 3, let score = Double(parts[2]) else { continue }
            let key = String(parts[0])
            table[key, default: []].append(Unigram(value: String(parts[1]), score: score))
        }
    }

    public init(contentsOf url: URL) throws {
        try self.init(text: String(contentsOf: url, encoding: .utf8))
    }

    public func unigrams(forKey key: String) -> [Unigram] { table[key] ?? [] }
    public func hasKey(_ key: String) -> Bool { table[key] != nil }

    /// Single-character max scores derived directly from already-split LM lines, WITHOUT
    /// building the full `[String: [Unigram]]` table. Keeps only single-character values, and
    /// skips control keys (see `isControlKey`).
    /// Callers that already have the file split into lines (e.g. to also build
    /// `AssociatedPhrases` from the same lines) should use this to avoid re-splitting.
    public static func characterScores(fromLines lines: [Substring]) -> [Character: Double] {
        var scores: [Character: Double] = [:]
        scores.reserveCapacity(16_000)
        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") { continue }
            let parts = line.split(separator: " ")
            guard parts.count == 3, let score = Double(parts[2]) else { continue }
            guard !Self.isControlKey(parts[0]) else { continue }
            let value = parts[1]
            guard value.count == 1, let ch = value.first else { continue }
            if let existing = scores[ch] { scores[ch] = max(existing, score) }
            else { scores[ch] = score }
        }
        return scores
    }

    /// Single-character max scores derived directly from the LM text, WITHOUT building the
    /// full `[String: [Unigram]]` table. Streams each line once and keeps only single-character
    /// values. Equivalent to `LanguageModel(text:).characterScores()`, but avoids the transient
    /// ~55–80 MB table when only the character ranking is needed (the app's launch path).
    public static func characterScores(fromText text: String) -> [Character: Double] {
        characterScores(fromLines: text.split(separator: "\n", omittingEmptySubsequences: true))
    }

    /// Maps each single-character value to the MAX score seen for it across all
    /// unigrams. Multi-character values and control keys are excluded. Higher score = more common.
    public func characterScores() -> [Character: Double] {
        var scores: [Character: Double] = [:]
        for (key, grams) in table where !Self.isControlKey(key[...]) {
            for g in grams {
                guard let ch = g.value.first, g.value.count == 1 else { continue }
                if let existing = scores[ch] { scores[ch] = max(existing, g.score) }
                else { scores[ch] = g.score }
            }
        }
        return scores
    }

    /// McBopomofo's `_`-prefixed keys (`_punctuation_list`, `_kana_dou`, `_letter_A`…) map a key
    /// to a character at a placeholder score of 0.0, which says nothing about how often the
    /// character is used. Counted as a frequency, they put the rare 仝 above 的 and every other
    /// real character, so the character scores read only real readings.
    private static func isControlKey(_ key: Substring) -> Bool { key.hasPrefix("_") }
}
