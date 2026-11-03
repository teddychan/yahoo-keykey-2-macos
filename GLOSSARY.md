# Yahoo! KeyKey 2

A Traditional Chinese input method for macOS: the typist types radicals or a reading, and picks
the intended character from a candidate list.

## Language

**Radical** (字根):
One of the 26 shapes a 倉頡 or 速成 typist types, one per letter key (`h` is 竹).
_Avoid_: stroke, key

**Code** (碼):
The radicals typed so far for one character, such as `hqi` (竹手戈) for 我.
_Avoid_: input, sequence

**Candidate list**:
The characters offered for one code, in the order they are shown. Each list learns its own order
from what the typist picks in it.
_Avoid_: suggestions

**Exact match**:
A character whose code is the typed code itself. `h` matches 竹 exactly.

**Completion** (字根開頭相同的字):
A character whose code starts with the typed code and goes on further. 我 (`hqi`) is a
completion of `h`. Shown after the exact matches, only when the typist turns completions on.
_Avoid_: prefix match, suggestion, auto-complete

**Wildcard** (`*`):
A radical the 倉頡 typist types to stand for one or more unknown radicals. Completions of `h`
are the characters `h*` matches.
