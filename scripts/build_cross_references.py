#!/usr/bin/env python3
"""
Build a compact cross_references.json from the OpenBible.info Treasury of
Scripture Knowledge (TSK) dataset.

The OpenBible.info TSK is public-domain (CC-BY 4.0). Source:
  https://a.openbible.info/data/cross-references.zip

Output schema:
  {
    "Genesis 1:1": [
      {"ref": "Hebrews 11:3", "votes": 149},
      {"ref": "John 1:1",     "votes": 72},
      ...
    ],
    ...
  }

  - Verses are keyed by the canonical book names used by `lib/data/books.dart`.
  - For each source verse, references are sorted by votes descending and
    capped at MAX_REFS (default 30) — the top 30 covers >95% of useful links.
  - Source verses with no canonical-book references after filtering are
    omitted entirely.

Run from anywhere:
  python3 scripts/build_cross_references.py

The script is idempotent — re-running it overwrites the JSON in place.
"""

from __future__ import annotations

import io
import json
import os
import sys
import urllib.request
import zipfile
from collections import defaultdict
from pathlib import Path

# ── Config ──
TSK_URL = "https://a.openbible.info/data/cross-references.zip"
MAX_REFS = 30  # cap per source verse

REPO_ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = REPO_ROOT / "build" / "tsk_raw"
RAW_TXT = RAW_DIR / "cross_references.txt"
OUT_PATH = REPO_ROOT / "assets" / "data" / "cross_references.json"

# OSIS abbreviation → canonical book name (matches kAllBooks in lib/data/books.dart)
OSIS_TO_NAME: dict[str, str] = {
    # OT
    "Gen": "Genesis", "Exod": "Exodus", "Lev": "Leviticus", "Num": "Numbers",
    "Deut": "Deuteronomy", "Josh": "Joshua", "Judg": "Judges", "Ruth": "Ruth",
    "1Sam": "1 Samuel", "2Sam": "2 Samuel", "1Kgs": "1 Kings", "2Kgs": "2 Kings",
    "1Chr": "1 Chronicles", "2Chr": "2 Chronicles", "Ezra": "Ezra",
    "Neh": "Nehemiah", "Esth": "Esther", "Job": "Job", "Ps": "Psalms",
    "Prov": "Proverbs", "Eccl": "Ecclesiastes", "Song": "Song of Solomon",
    "Isa": "Isaiah", "Jer": "Jeremiah", "Lam": "Lamentations", "Ezek": "Ezekiel",
    "Dan": "Daniel", "Hos": "Hosea", "Joel": "Joel", "Amos": "Amos",
    "Obad": "Obadiah", "Jonah": "Jonah", "Mic": "Micah", "Nah": "Nahum",
    "Hab": "Habakkuk", "Zeph": "Zephaniah", "Hag": "Haggai", "Zech": "Zechariah",
    "Mal": "Malachi",
    # NT
    "Matt": "Matthew", "Mark": "Mark", "Luke": "Luke", "John": "John",
    "Acts": "Acts", "Rom": "Romans", "1Cor": "1 Corinthians",
    "2Cor": "2 Corinthians", "Gal": "Galatians", "Eph": "Ephesians",
    "Phil": "Philippians", "Col": "Colossians",
    "1Thess": "1 Thessalonians", "2Thess": "2 Thessalonians",
    "1Tim": "1 Timothy", "2Tim": "2 Timothy", "Titus": "Titus",
    "Phlm": "Philemon", "Heb": "Hebrews", "Jas": "James",
    "1Pet": "1 Peter", "2Pet": "2 Peter",
    "1John": "1 John", "2John": "2 John", "3John": "3 John",
    "Jude": "Jude", "Rev": "Revelation",
}


def download_tsk() -> Path:
    """Download + extract cross_references.txt; cache in build/tsk_raw."""
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    if RAW_TXT.exists():
        print(f"  Using cached {RAW_TXT.relative_to(REPO_ROOT)}")
        return RAW_TXT

    print(f"  Downloading {TSK_URL} ...")
    with urllib.request.urlopen(TSK_URL) as resp:
        data = resp.read()
    print(f"  Got {len(data) / 1024:.1f} KB. Extracting ...")

    with zipfile.ZipFile(io.BytesIO(data)) as zf:
        # The zip contains a top-level cross_references.txt
        member = next(
            (n for n in zf.namelist() if n.endswith("cross_references.txt")),
            None,
        )
        if member is None:
            raise RuntimeError("cross_references.txt not found in zip")
        with zf.open(member) as src, open(RAW_TXT, "wb") as dst:
            dst.write(src.read())

    print(f"  Wrote {RAW_TXT.relative_to(REPO_ROOT)}")
    return RAW_TXT


def parse_osis_verse(token: str) -> tuple[str, int, int] | None:
    """Parse "Gen.1.1" → ("Genesis", 1, 1). Returns None on failure or
    if the book is outside the canonical 66 (e.g. Apocrypha)."""
    parts = token.split(".")
    if len(parts) != 3:
        return None
    osis_book, ch_str, vs_str = parts
    name = OSIS_TO_NAME.get(osis_book)
    if name is None:
        return None
    try:
        return name, int(ch_str), int(vs_str)
    except ValueError:
        return None


def parse_osis_range(token: str) -> tuple[str, int, int] | None:
    """Parse "Gen.1.1" or a range like "Gen.1.1-Gen.1.3" — we just take the
    starting verse (sufficient for cross-ref jumping)."""
    if "-" in token:
        token = token.split("-", 1)[0]
    return parse_osis_verse(token)


def build_index() -> tuple[dict[str, list[dict]], dict[str, int], int, int]:
    """Read TSK TSV, return:
      - mapping  source_id → ranked list of {ref, votes}
      - skipped_books counter
      - rows seen
      - rows kept
    """
    txt = download_tsk()
    raw_map: dict[str, list[tuple[int, str]]] = defaultdict(list)
    skipped_books: dict[str, int] = defaultdict(int)
    seen = 0
    kept = 0

    with open(txt, "r", encoding="utf-8") as f:
        # First line is the header
        header = f.readline()
        if not header.startswith("From Verse"):
            print(f"  WARN: unexpected header: {header.rstrip()}", file=sys.stderr)
        for line in f:
            seen += 1
            parts = line.rstrip("\n").split("\t")
            if len(parts) < 3:
                continue
            from_tok, to_tok, votes_str = parts[0], parts[1], parts[2]
            try:
                votes = int(votes_str)
            except ValueError:
                continue

            from_v = parse_osis_verse(from_tok)
            to_v = parse_osis_range(to_tok)

            if from_v is None:
                osis_book = from_tok.split(".", 1)[0]
                skipped_books[osis_book] += 1
                continue
            if to_v is None:
                osis_book = to_tok.split(".", 1)[0]
                skipped_books[osis_book] += 1
                continue

            from_id = f"{from_v[0]} {from_v[1]}:{from_v[2]}"
            to_id = f"{to_v[0]} {to_v[1]}:{to_v[2]}"
            raw_map[from_id].append((votes, to_id))
            kept += 1

    # Sort by votes desc, dedupe, cap at MAX_REFS, emit final shape
    final: dict[str, list[dict]] = {}
    for src, refs in raw_map.items():
        # Dedupe — keep highest votes per target
        best: dict[str, int] = {}
        for v, tgt in refs:
            if tgt == src:
                continue  # ignore self-refs
            if v > best.get(tgt, -1):
                best[tgt] = v
        ranked = sorted(best.items(), key=lambda kv: (-kv[1], kv[0]))[:MAX_REFS]
        if not ranked:
            continue
        final[src] = [{"ref": r, "votes": v} for r, v in ranked]

    return final, dict(skipped_books), seen, kept


def main() -> None:
    print("Building cross_references.json from OpenBible.info TSK ...")
    index, skipped_books, seen, kept = build_index()

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    # Compact JSON — no spaces, single line per top-level key would still be
    # multi-MB — so just dump compactly. Flutter's JsonDecoder is fine with it.
    with open(OUT_PATH, "w", encoding="utf-8") as f:
        json.dump(index, f, ensure_ascii=False, separators=(",", ":"))

    size = OUT_PATH.stat().st_size
    print()
    print(f"  Source rows seen:    {seen}")
    print(f"  Rows kept:           {kept}")
    print(f"  Source verses:       {len(index)}")
    print(f"  Output file:         {OUT_PATH.relative_to(REPO_ROOT)}")
    print(f"  Output size:         {size / (1024 * 1024):.2f} MB")

    if skipped_books:
        print()
        print(f"  Books skipped (not in kAllBooks — Apocrypha etc.):")
        for book, count in sorted(skipped_books.items(), key=lambda kv: -kv[1]):
            print(f"    {book}: {count} refs")
    else:
        print("  No skipped books.")


if __name__ == "__main__":
    main()
