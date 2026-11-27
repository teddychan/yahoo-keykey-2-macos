# ADR 0001: 倉頡’s mode icon is a per-mode template

## Status

Accepted

## Context

The inline language switcher and the menu bar both draw an input mode’s icon through
HIToolbox and `KLInputSourceIconManager`. Apple’s 倉 and あ are template images: the system
tints them black on a light pill, white on a dark pill, white on the blue selection, and white
on a dark menu bar.

`islCreateInputModeIconImage` does not read the top-level `TISIconIsTemplate`. When a mode
dict has `tsInputModeMenuIconFileKey`, it reads `TISIconIsTemplate` from **that mode’s dict**.
If the key is absent, the mode is a template only when it also has no
`tsInputModeAlternateMenuIconFileKey`. The top-level flag applies only to the input *method*
icon (`islCreateInputMethodIconImage`).

The inline HUD looks the source id up in a built-in table of Apple ids. A third-party id misses,
so `TISIconLabels` is never drawn. The HUD falls back to the mode’s bitmap and sets
`isTemplate` from `TSMInputSourcePropertyIconShouldBeTemplate`, which is the per-mode decision
above.

A white bitmap that stays white in the menu bar stays white on the light pill. A black bitmap
that shows on the light pill disappears on the dark pill and on a dark menu bar. A filled plate
covers the blue selection circle. Drawing another TIFF does not change the tint.

## Decision

The 倉頡 mode sets `TISIconIsTemplate` to true, omits `tsInputModeAlternateMenuIconFileKey`, and
points `tsInputModeMenuIconFileKey` and `tsInputModePaletteIconFileKey` at
`CangjieGlyphTemplate.tiff`: a 2-page gray+alpha TIFF, 16×16 at 72 dpi and 32×32 at 144 dpi,
L = 0, alpha = glyph coverage, PingFangTC-Semibold 倉 inset 1.6 pt.

The input method has no top-level `TISIconIsTemplate`. 速成, 注音 and 拼音 keep
`tsInputModeAlternateMenuIconFileKey` and set `TISIconIsTemplate` to false, so they stay the
full-colour `YahooKeyKey.tiff` (white tile and purple Y).

## Consequences

倉 follows the pill and the menu bar the way Apple’s 倉 and あ do. A menu-bar 倉 that stays
white on a *light* menu bar cannot be combined with a black 倉 on the light pill: both places
tint the same template.

Do not put `TISIconIsTemplate` only at the top level, and do not rely on `TISIconLabels`, a
filename ending in `Template`, or the palette key. None of those sets the mode’s template flag
or gives the HUD a separate image.
