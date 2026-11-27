# 倉頡 mode icon

The inline switcher and the menu bar tint one template glyph. The artwork was never the
problem. See `docs/adr/0001-cangjie-mode-template-icon.md`.

## What it should look like

- Light pill: black 倉. Dark pill: white 倉. Selected: white 倉 on the blue circle.
- Menu bar: 倉 follows the menu bar. White on a dark menu bar.
- 速成, 注音 and 拼音: the full-colour purple Y on its white tile.

A menu-bar 倉 that stays white on a *light* menu bar cannot be combined with the light-pill
appearance. Both places tint the same template, the same way Apple’s 倉 and あ do.

## Why earlier attempts failed

HIToolbox reads `TISIconIsTemplate` from the **mode** dict
(`ComponentInputModeDict` › `tsInputModeListKey` › the mode), and only when that mode has
`tsInputModeMenuIconFileKey`. If the key is missing, a mode that also has
`tsInputModeAlternateMenuIconFileKey` is not a template. The top-level flag applies only to
the input-method icon.

The inline HUD (`KLInputSourceIconManager`) has no built-in entry for this input method, so
`TISIconLabels` is never drawn. It falls back to the mode bitmap and sets `isTemplate` from
that per-mode property. A top-level flag, a `Template` filename, and the palette key do not
reach it.

## What is set now

`App/Info.plist`, 倉頡 mode only:

- `TISIconIsTemplate` = true
- no `tsInputModeAlternateMenuIconFileKey`
- `tsInputModeMenuIconFileKey` and `tsInputModePaletteIconFileKey` = `CangjieGlyphTemplate.tiff`

速成, 注音 and 拼音 set `TISIconIsTemplate` = false and keep the Alternate key pointing at
`YahooKeyKey.tiff`. There is no top-level `TISIconIsTemplate`.

`CangjieGlyphTemplate.tiff` stays the 2-page gray+alpha glyph: 16×16 at 72 dpi, 32×32 at
144 dpi, L = 0, alpha = coverage, PingFangTC-Semibold 倉 from `CTFontDrawGlyphs`, centered
on `CTFontGetBoundingRectsForGlyphs`, inset 1.6 pt. Do not draw another variant.

The user tests `~/Library/Input Methods/Yahoo KeyKey 2 Debug.app`, installed by
`./tools/run-debug.sh`. The debug id rewrite in `tools/build-app.sh` renames the mode id and
keeps the per-mode flag. Ignore the root-owned `/Library/Input Methods/YahooKeyKey2.app`.

## How to check

`TSMInputSourcePropertyIconShouldBeTemplate` for
`com.dragonapp.inputmethod.yahoo-keykey.debug.yahoo-keykey.debug.Cangjie` must be 1, and
`indicatorImageForInputSource:` (it takes the source id string) must report `template=true`
with the URL ending in `CangjieGlyphTemplate.tiff` inside the Debug app. Apple’s 倉 and あ
report the same template flag.

If a reinstall still reports 0, `killall TextInputMenuAgent` and re-enable
`com.apple.inputmethod.TYIM.Cangjie`, `com.apple.inputmethod.TCIM.Cangjie`,
`com.dragonapp.inputmethod.yahoo-keykey.yahoo-keykey.Cangjie`, and
`com.dragonapp.inputmethod.yahoo-keykey.debug.yahoo-keykey.debug.Cangjie`.
`TISEnableInputSource` returns 0 even when the source does not stick; confirm with
`TISCreateInputSourceList(nil, false)`. Do not toggle
`com.apple.inputmethod.Kotoeri.KanaTyping.Japanese`. If it still does not stick, log out
and back in.
