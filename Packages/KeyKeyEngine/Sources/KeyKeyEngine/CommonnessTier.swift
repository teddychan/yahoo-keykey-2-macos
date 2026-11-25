import Foundation

// How common a character is, by the two character sets Traditional Chinese computing grew up on:
// Big5, whose first level is Taiwan's 常用字 and whose second is its 次常用字, and HKSCS, which added
// the characters Hong Kong writes and Big5 lacks — 嘅 咗 啲 喺 among them. Everything else (CJK
// Extension A, Japanese forms such as 薬, simplified forms such as 丢) is the last tier.
//
// It decides only between candidates the language model has no frequency for (see
// CandidateOrdering): a rare character never overtakes one the model ranks. Almost every Big5
// character is ranked, so in practice it puts Hong Kong characters ahead of Japanese, simplified
// and variant forms at the end of a long wildcard list.
//
// Only Chinese characters have a tier worth comparing: Big5 levels say nothing about punctuation,
// so every non-ideograph is `.other` and a z-code punctuation list keeps the table's own order.
enum CommonnessTier: Int, Comparable {
    case common       // Big5 level 1 (A440–C67E): 5,401 characters
    case lessCommon   // Big5 level 2 (C940–F9D5): 7,652 characters
    case hongKong     // in HKSCS (macOS ships the 1999 set) but not in Big5
    case other

    init(_ character: Character) {
        guard character.unicodeScalars.count == 1, let scalar = character.unicodeScalars.first,
              Self.isIdeograph(scalar) else {
            self = .other
            return
        }
        let text = String(character)
        if let bytes = text.data(using: Self.big5), bytes.count == 2 {
            let code = Int(bytes[bytes.startIndex]) << 8 | Int(bytes[bytes.startIndex + 1])
            if (0xA440...0xC67E).contains(code) { self = .common; return }
            if (0xC940...0xF9D5).contains(code) { self = .lessCommon; return }
        }
        self = text.data(using: Self.hkscs) == nil ? .other : .hongKong
    }

    static func < (lhs: CommonnessTier, rhs: CommonnessTier) -> Bool { lhs.rawValue < rhs.rawValue }

    // The ideograph ranges the 倉頡 tables load (see CangjieTable.isRenderableCJK).
    private static func isIdeograph(_ scalar: Unicode.Scalar) -> Bool {
        (0x4E00...0x9FFF).contains(scalar.value)      // CJK Unified Ideographs
            || (0x3400...0x4DBF).contains(scalar.value)   // CJK Extension A
            || (0xF900...0xFAFF).contains(scalar.value)   // CJK Compatibility Ideographs
    }

    private static let big5 = encoding(.big5)
    private static let hkscs = encoding(.big5_HKSCS_1999)

    private static func encoding(_ cf: CFStringEncodings) -> String.Encoding {
        String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cf.rawValue)))
    }
}
