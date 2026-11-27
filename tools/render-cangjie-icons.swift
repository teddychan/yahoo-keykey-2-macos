import AppKit
import CoreText
import Foundation

// Draws the 倉頡 input-source icon at Apple's menu-icon size: 16 points.
// A 16×16 page at 72 dpi and a 32×32 page at 144 dpi are the same 16 points, so a
// Retina menu uses the sharp page without drawing the icon twice as large.
//
// One style only: a square glyph mask, black ink on transparent, inset 1.6 pt.
// tools/make-icon.sh turns that into gray+alpha (L = 0, alpha = glyph coverage),
// the same layout as Apple's cangjie.tiff. The switcher and the menu bar both
// tint that alpha: black on the light pill, white on the dark pill, white on the
// blue selection, and white on the dark menu bar.
//
// Usage: swift tools/render-cangjie-icons.swift <output-directory>

let character = "倉"
let pointSize: CGFloat = 16

func cangjieFont(size: CGFloat) -> NSFont {
    for name in ["PingFangTC-Semibold", "PingFangTC-Medium", "HiraginoSans-W6", "PingFangHK-Semibold"] {
        if let font = NSFont(name: name, size: size) { return font }
    }
    return NSFont.systemFont(ofSize: size, weight: .semibold)
}

func inkRect(font: NSFont) -> CGRect {
    let ct = font as CTFont
    var glyphs = [CGGlyph](repeating: 0, count: 1)
    var chars = Array(character.utf16)
    guard CTFontGetGlyphsForCharacters(ct, &chars, &glyphs, 1) else { return .null }
    var rect = CGRect.null
    CTFontGetBoundingRectsForGlyphs(ct, .horizontal, &glyphs, &rect, 1)
    return rect
}

/// Draw 倉 so its ink bounds fill `target` (AppKit coordinates, origin at the bottom left).
func drawGlyph(in target: CGRect, color: NSColor) {
    var lo: CGFloat = 1
    var hi: CGFloat = target.height * 4
    var best = cangjieFont(size: target.height)
    var bestInk = inkRect(font: best)
    for _ in 0..<24 {
        let mid = (lo + hi) / 2
        let font = cangjieFont(size: mid)
        let ink = inkRect(font: font)
        if ink.width > 0, ink.height > 0, ink.width <= target.width, ink.height <= target.height {
            best = font
            bestInk = ink
            lo = mid
        } else {
            hi = mid
        }
    }
    let ct = best as CTFont
    var glyphs = [CGGlyph](repeating: 0, count: 1)
    var chars = Array(character.utf16)
    guard CTFontGetGlyphsForCharacters(ct, &chars, &glyphs, 1),
          let cg = NSGraphicsContext.current?.cgContext else { return }
    var position = CGPoint(x: target.midX - bestInk.midX, y: target.midY - bestInk.midY)
    cg.saveGState()
    cg.setFillColor(color.cgColor)
    CTFontDrawGlyphs(ct, &glyphs, &position, 1, cg)
    cg.restoreGState()
}

func render(pointWidth: CGFloat, pointHeight: CGFloat, scale: Int) -> NSBitmapImageRep {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(pointWidth) * scale,
        pixelsHigh: Int(pointHeight) * scale,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fputs("render-cangjie-icons: could not allocate a bitmap\n", stderr)
        exit(1)
    }
    rep.size = NSSize(width: pointWidth, height: pointHeight)
    guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else {
        fputs("render-cangjie-icons: could not make a graphics context\n", stderr)
        exit(1)
    }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx
    ctx.imageInterpolation = .high
    ctx.shouldAntialias = true

    let canvas = CGRect(x: 0, y: 0, width: pointWidth, height: pointHeight)
    drawGlyph(in: canvas.insetBy(dx: 1.6, dy: 1.6), color: .black)

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func write(_ rep: NSBitmapImageRep, to url: URL) {
    guard let data = rep.representation(using: .tiff, properties: [
        .compressionMethod: NSBitmapImageRep.TIFFCompression.none.rawValue,
    ]) else {
        fputs("render-cangjie-icons: could not encode \(url.path)\n", stderr)
        exit(1)
    }
    do {
        try data.write(to: url)
    } catch {
        fputs("render-cangjie-icons: \(error)\n", stderr)
        exit(1)
    }
}

guard CommandLine.arguments.count == 2 else {
    fputs("usage: render-cangjie-icons.swift <output-directory>\n", stderr)
    exit(1)
}
let out = URL(fileURLWithPath: CommandLine.arguments[1])
do {
    try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
} catch {
    fputs("render-cangjie-icons: \(error)\n", stderr)
    exit(1)
}

for scale in [1, 2] {
    let rep = render(pointWidth: pointSize, pointHeight: pointSize, scale: scale)
    write(rep, to: out.appendingPathComponent("template-\(scale)x.tiff"))
}
