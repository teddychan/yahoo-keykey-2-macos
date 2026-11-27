# 倉頡 result logic — handoff

This note records the candidate/commit behaviour changed for the adjusted 倉頡 build. It is
about **result logic only**; the separate per-mode icon work is in
[`docs/handoff-cangjie-icon.md`](handoff-cangjie-icon.md) and
[`docs/adr/0001-cangjie-mode-template-icon.md`](adr/0001-cangjie-mode-template-icon.md).

## Scope

Three changes:

1. `戈土心` (`igp`) produces 應 in the 五代 table.
2. A 倉頡 code with several exact matches treats the first Space as “show the choices”, not
   “commit the first one”. Numbers pick; any other printable character accepts the first
   candidate and is then processed normally.
3. Candidate order is stable by default: picking an item no longer moves it to the top.

The first is data. The second is controller/engine policy. The third is the existing adaptive
ordering feature, now off by default.

## 1. `戈土心` → 應

`Resources/cangjie.txt` now contains:

```text
igp	應
```

`iogp` (戈人土心) was already the classical 五代 code and remains. 三代 (`cangjie-yahoo.txt`)
already had `igp`. Because `CangjieCodeIndex` keeps the shortest code for a character, the
反查/拆碼 hint for 應 now shows 戈土心 rather than 戈人土心.

No engine special case was added: the table lookup and the existing exact-match logic produce
the character. No other aliases were added; only the code the typist reported is in the table.

## 2. Space and the candidate list

The behaviour is **two-step** for a code with more than one exact match. `大月` (大 + 月) is
the canonical example: the 五代 table offers 有 and 冇.

Each row after the first assumes the list is already open.

| Input | Result |
|---|---|
| `大月` | candidate list shows 有, 冇 |
| `大月` then Space | list stays open; nothing is committed |
| then `1` | commits 有 |
| then `2` | commits 冇 |
| then `k` | commits 有, then starts a new code with 大 |
| then `,` | commits 有, then inserts ， |
| then Space | commits 有 (does not insert a literal space) |
| then Return | commits 有 |
| then Backspace | deletes 月 and updates the list |
| then Esc | discards the composition |
| then arrows / Page Up / Page Down | pages the candidate list |

For a code with **one exact match**, the first Space commits directly. `戈土心` + Space → 應.

For 速成, 注音 and 拼音, Space keeps its previous meaning. This rule is 倉頡-only.

### Why the rule is conditional on exact matches

`exactCandidateCount`, not the total candidate count, decides whether Space opens the list.
Completions shown by **顯示字根開頭相同的字** sit behind the exact matches and must not turn a
one-character code into a forced choice. So:

- `戈土心` with completions enabled: one exact match → Space commits 應.
- `大月`: two exact matches → Space opens the choice.

### State and order of branches

`InputController` keeps a per-composition flag:

```swift
private var cangjieOptionsShown = false
```

It is set only when Space opens the list and is cleared by
`resetCompositionState()` (new radical, backspace, Esc, commit, engine swap, mode change).

The 倉頡 Space branch runs after the optional **以空白鍵確認字根** confirmation and before the
generic Space-paging branch:

```text
optional stroke confirmation
→ 倉頡 Space decision
→ arrow / Page paging
→ 1–9 selection
→ printable non-number accept + re-handle
→ generic Space paging / commit
→ Return / Backspace / Esc / engine keys
```

The pure decisions live in `App/KeyEventPolicy.swift`:

```swift
enum CangjieSpaceAction { case openChoices, acceptFirst }

static func cangjieSpaceAction(optionsShown: Bool,
                               exactCandidateCount: Int) -> CangjieSpaceAction
static func isCandidateAcceptCharacter(_ characters: String?) -> Bool
```

`cangjieSpaceAction` is:

```text
optionsShown || exactCandidateCount <= 1  → acceptFirst
otherwise                                 → openChoices
```

`isCandidateAcceptCharacter` returns true for letters, numbers, punctuation and symbols, but
**not** ASCII space or control characters. This is what makes a letter after Space start a new
code and a punctuation mark after Space be inserted after the committed character. Return, Tab,
Backspace, Esc and the arrow keys keep their own meanings.

When a printable non-number accepts the first candidate, the controller commits **without**
offering 聯想 and re-handles the original event:

```swift
engine.selectCandidate(candidatePage * InputController.pageSize)
_ = commitCurrent(to: client)
return handle(event, client: sender)
```

That re-handle is what makes `大月` Space `k` produce 有 and immediately start 大, rather than
appending `k` to the old code. A second Space also accepts without opening 聯想. A `1–9`
selection keeps the normal commit path, including 聯想.

### Things that deliberately did **not** change

- A radical letter typed **before** Space still extends the code. Auto-committing on every
  radical would make 3–5-radical codes impossible; Space is the “this code is finished” key.
- Space no longer pages the 倉頡 list. Arrows and Page Up / Page Down page instead. The generic
  Space-paging branch is only reached by 速成 and 注音.
- A number beyond the current page is swallowed, as before; it does not commit the first
  candidate.
- The stroke-confirmation option still runs first. With it on, the first Space confirms the
  strokes and the second Space opens the choice (or accepts, if only one exact match).
- `*` wildcards, completion lists and the third-radical 速成 run-on are untouched.

## 3. Stable candidate order by default

`Preferences.registerDefaults()` now registers:

```swift
Key.adaptiveCandidateOrderEnabled: false
```

The adaptive-ordering machinery is unchanged: it still records per-list commits and sorts by
count when enabled. Off by default means:

- `CandidateOrdering` receives a zero count for every candidate, so the table/rank order stands.
- No usage is recorded (`AdaptiveCandidateOrder.usageToRecord` is gated by the same flag).
- Counts already on disk are kept but ignored; turning the setting back on restores the learned
  order.
- 聯想 and 拼音 are gated by the same flag, so they also stay in their built-in order while it is
  off.

The example the change was made for: `大月` shows 有, 冇; press `2` for 冇; the next `大月`
still shows 有, 冇 rather than moving 冇 to the top.

The setting remains in **設定… ▸ 一般** as **依選字習慣調整候選字順序**. Turning it on restores
the previous adaptive behaviour. The default is global (all four methods and 聯想), not
倉頡-only, because the setting was already global.

## Verification

At the time of these changes:

- `swift test --package-path Packages/KeyKeyEngine` — 381 tests passed, including the real-table
  checks for `igp → 應` and `kb → 有 / 冇`.
- `swift test --package-path Packages/KeyKeyApp` — 143 tests passed, including
  `cangjieSpaceAction`, `isCandidateAcceptCharacter`, and the changed adaptive-order default.
- Manual sequence verified against the real 五代 table:

  ```text
  igp  → 應 (1 candidate)
  iogp → 應 (1 candidate)
  kb   → 有 / 冇 (2 candidates)
  ```

The decision functions are unit-tested. The controller branch order has to be checked manually:
`InputController` needs a live IMK server, so it is not part of the SwiftPM test targets.

## Files touched for this logic

| File | Change |
|---|---|
| `Resources/cangjie.txt` | `igp` → 應 |
| `App/InputController.swift` | `cangjieOptionsShown` state, 倉頡 Space branch, printable non-number accept + re-handle, reset |
| `App/KeyEventPolicy.swift` | `cangjieSpaceAction`, `isCandidateAcceptCharacter`, updated Space documentation |
| `App/Preferences.swift` | adaptive ordering default `false` |
| `Packages/KeyKeyApp/Tests/KeyKeyAppTests/KeyEventPolicyTests.swift` | Space action and accept-character tests |
| `Packages/KeyKeyApp/Tests/KeyKeyAppTests/PreferencesTests.swift` | stable-order default |
| `Packages/KeyKeyEngine/Tests/KeyKeyEngineTests/RealCangjieTableTests.swift` | real-table checks for 應 and 大月 |
| `README.md`, `CHANGELOG.md`, `known_issues.md` | user-facing description of the final behaviour |

## Known limitation

The “any printable non-number accepts the first candidate” rule applies **after Space has
opened the list**. Before that, a letter is a code key and extends the code. This is deliberate:
without it, typing the second or third radical could commit the first candidate and make longer
codes impossible. A typist who wants the first candidate should press Space (then any
character), Space again, Return, or a digit.
