# BSB — Berean Standard Bible

Public domain. Closest open-license modern English equivalent to NASB/ESV (formal-equivalence style).

Source: https://bereanbible.com/  (canonical) or https://ebible.org/find/details.php?id=engBSB

Drop one JSON file per book into this directory, named to match `lib/data/books.dart` (e.g. `genesis.json`, `1corinthians.json`, ...).

Format: same flat array as `web/`:
```json
[
  { "type": "paragraph text", "chapterNumber": 1, "verseNumber": 1, "value": "..." },
  ...
]
```

To populate, run:
```
dart run tools/fetch_bsb.dart
```
(see tools/fetch_bsb.dart for source URLs and conversion logic)
