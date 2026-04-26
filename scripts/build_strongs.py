#!/usr/bin/env python3
"""
Build compact Strong's tagging assets from STEPBible's TAGNT/TAHOT and the
TBESG/TBESH lexicons (CC BY 4.0).

Outputs (under assets/data/):
  strongs_kjv.json     — per-verse maps "Book Chapter:Verse" → list of
                         {word, strongs?, lemma?, translit?}
  strongs_lexicon.json — Strong's number → {original, translit, pos, def}

The data sources are tab-separated text files. Each verse-row in TAGNT/TAHOT
has the following relevant columns:
  Col  0: "Mat.1.18#01=NKO"  (Book.Chap.Verse#WordIndex=Editions)
  Col  1: original word with parenthesised transliteration "Τοῦ (Tou)"
  Col  2: English translation, sometimes wrapped in <...>
  Col  3: dStrong=Grammar, e.g. "G3588=T-GSM"
  Col  4: lemma=gloss, e.g. "ὁ=the/this/who"

For TBESG/TBESH lexicon rows:
  Col  0: Strong's #
  Col  3: original lexical form
  Col  4: transliteration
  Col  5: morphology (POS code, e.g. "G:N-M-P")
  Col  6: brief gloss
  Col  7: long definition (HTML — we strip + truncate)

The script is idempotent and time-boxed to NT-first if the OT push the
combined output past SIZE_BUDGET_MB.

Usage:
  python3 scripts/build_strongs.py [--nt-only]
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import urllib.request
from html import unescape
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = REPO_ROOT / "build" / "strongs_raw"
OUT_DIR = REPO_ROOT / "assets" / "data"
OUT_VERSES = OUT_DIR / "strongs_kjv.json"
OUT_LEXICON = OUT_DIR / "strongs_lexicon.json"

# Hard ceiling for the verse-tags file. Above this, we drop OT and keep NT only.
# Spec says don't bundle data > 60 MB total — 58 leaves room for the lexicon.
SIZE_BUDGET_MB = 58

# OSIS abbreviation → canonical book name (matches kAllBooks in lib/data/books.dart)
OSIS_TO_NAME: dict[str, str] = {
    # OT
    "Gen": "Genesis", "Exo": "Exodus", "Lev": "Leviticus", "Num": "Numbers",
    "Deu": "Deuteronomy", "Jos": "Joshua", "Jdg": "Judges", "Rut": "Ruth",
    "1Sa": "1 Samuel", "2Sa": "2 Samuel", "1Ki": "1 Kings", "2Ki": "2 Kings",
    "1Ch": "1 Chronicles", "2Ch": "2 Chronicles", "Ezr": "Ezra",
    "Neh": "Nehemiah", "Est": "Esther", "Job": "Job", "Psa": "Psalms",
    "Pro": "Proverbs", "Ecc": "Ecclesiastes", "Sng": "Song of Solomon",
    "Son": "Song of Solomon", "SOS": "Song of Solomon",
    "Isa": "Isaiah", "Jer": "Jeremiah", "Lam": "Lamentations", "Ezk": "Ezekiel",
    "Eze": "Ezekiel", "Dan": "Daniel", "Hos": "Hosea", "Jol": "Joel",
    "Joe": "Joel", "Amo": "Amos", "Oba": "Obadiah", "Jon": "Jonah",
    "Mic": "Micah", "Nah": "Nahum", "Hab": "Habakkuk", "Zep": "Zephaniah",
    "Hag": "Haggai", "Zec": "Zechariah", "Mal": "Malachi",
    # NT — STEPBible uses Mat/Mrk/Luk/Jhn (3-letter)
    "Mat": "Matthew", "Mrk": "Mark", "Mar": "Mark", "Luk": "Luke",
    "Jhn": "John", "Joh": "John", "Act": "Acts", "Rom": "Romans",
    "1Co": "1 Corinthians", "2Co": "2 Corinthians", "Gal": "Galatians",
    "Eph": "Ephesians", "Php": "Philippians", "Col": "Colossians",
    "1Th": "1 Thessalonians", "2Th": "2 Thessalonians",
    "1Ti": "1 Timothy", "2Ti": "2 Timothy", "Tit": "Titus",
    "Phm": "Philemon", "Heb": "Hebrews", "Jas": "James", "Jam": "James",
    "1Pe": "1 Peter", "2Pe": "2 Peter",
    "1Jn": "1 John", "1Jo": "1 John", "2Jn": "2 John", "2Jo": "2 John",
    "3Jn": "3 John", "3Jo": "3 John", "Jud": "Jude", "Rev": "Revelation",
}

# Files we expect under build/strongs_raw — populated by the download step.
TAGNT_FILES = [
    "TAGNT_Mat-Jhn.txt",
    "TAGNT_Act-Rev.txt",
]
TAHOT_FILES = [
    "TAHOT_Gen-Deu.txt",
    "TAHOT_Jos-Est.txt",
    "TAHOT_Job-Sng.txt",
    "TAHOT_Isa-Mal.txt",
]

DOWNLOAD_BASE = "https://raw.githubusercontent.com/STEPBible/STEPBible-Data/master/"
DOWNLOADS = {
    "TAGNT_Mat-Jhn.txt":
        "Translators%20Amalgamated%20OT%2BNT/TAGNT%20Mat-Jhn%20-%20Translators%20Amalgamated%20Greek%20NT%20-%20STEPBible.org%20CC-BY.txt",
    "TAGNT_Act-Rev.txt":
        "Translators%20Amalgamated%20OT%2BNT/TAGNT%20Act-Rev%20-%20Translators%20Amalgamated%20Greek%20NT%20-%20STEPBible.org%20CC-BY.txt",
    "TAHOT_Gen-Deu.txt":
        "Translators%20Amalgamated%20OT%2BNT/TAHOT%20Gen-Deu%20-%20Translators%20Amalgamated%20Hebrew%20OT%20-%20STEPBible.org%20CC%20BY.txt",
    "TAHOT_Jos-Est.txt":
        "Translators%20Amalgamated%20OT%2BNT/TAHOT%20Jos-Est%20-%20Translators%20Amalgamated%20Hebrew%20OT%20-%20STEPBible.org%20CC%20BY.txt",
    "TAHOT_Job-Sng.txt":
        "Translators%20Amalgamated%20OT%2BNT/TAHOT%20Job-Sng%20-%20Translators%20Amalgamated%20Hebrew%20OT%20-%20STEPBible.org%20CC%20BY.txt",
    "TAHOT_Isa-Mal.txt":
        "Translators%20Amalgamated%20OT%2BNT/TAHOT%20Isa-Mal%20-%20Translators%20Amalgamated%20Hebrew%20OT%20-%20STEPBible.org%20CC%20BY.txt",
    "TBESG.txt":
        "Lexicons/TBESG%20-%20Translators%20Brief%20lexicon%20of%20Extended%20Strongs%20for%20Greek%20-%20STEPBible.org%20CC%20BY.txt",
    "TBESH.txt":
        "Lexicons/TBESH%20-%20Translators%20Brief%20lexicon%20of%20Extended%20Strongs%20for%20Hebrew%20-%20STEPBible.org%20CC%20BY.txt",
}


# ── Download ──────────────────────────────────────────────────────────────────

def ensure_downloads() -> None:
    """Idempotent fetch of TAGNT/TAHOT/TBESG/TBESH into build/strongs_raw."""
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    for name, url_path in DOWNLOADS.items():
        out = RAW_DIR / name
        if out.exists() and out.stat().st_size > 100_000:
            continue
        full = DOWNLOAD_BASE + url_path
        print(f"  Downloading {name} ...")
        with urllib.request.urlopen(full, timeout=120) as resp:
            data = resp.read()
        out.write_bytes(data)
        print(f"    wrote {len(data) / 1024 / 1024:.1f} MB")


# ── Lexicon ────────────────────────────────────────────────────────────────────

# The TBESG/TBESH long-definition column has HTML tags and <ref='...'>...</ref>
# wrappers. Strip everything down to the first sentence under 100 chars.
_HTML_TAG_RE = re.compile(r"<[^>]+>")
_REF_RE = re.compile(r"<ref[^>]*>([^<]*)</ref>", re.I)


def clean_def(s: str) -> str:
    """Strip HTML and reduce a long definition to a short, useful phrase."""
    if not s:
        return ""
    # First-pass: keep <ref> visible text, drop all other HTML.
    s = _REF_RE.sub(r"\1", s)
    s = _HTML_TAG_RE.sub("", s)
    s = unescape(s).strip()
    # Drop trailing "(AS)" attribution + numbered list noise like "1)" etc
    s = re.sub(r"\s*\(AS\)\s*$", "", s)
    s = s.replace(" ", " ")
    s = re.sub(r"\s+", " ", s)
    # Truncate at first sentence boundary if reasonable; else hard cap.
    # We aim for under 100 chars per spec.
    cut = 95
    if len(s) <= cut:
        return s
    head = s[:cut]
    # Prefer to break at the last space we see.
    sp = head.rfind(" ")
    if sp > cut * 0.6:
        head = head[:sp]
    return head.rstrip(" ,;:") + "…"


def parse_lexicon(path: Path) -> dict[str, dict]:
    """Parse a TBESG/TBESH file into a dict keyed by Strong's number."""
    out: dict[str, dict] = {}
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            if not line or line[0] not in "GH":
                continue
            cols = line.rstrip("\n").split("\t")
            if len(cols) < 7:
                continue
            sid = cols[0].strip()
            # Skip non-Strong rows (some "G0001G =" header style rows).
            if not re.fullmatch(r"[GH]\d{4,5}[A-Z]?", sid):
                continue
            original = cols[3].strip() if len(cols) > 3 else ""
            translit = cols[4].strip() if len(cols) > 4 else ""
            morph = cols[5].strip() if len(cols) > 5 else ""
            gloss = cols[6].strip() if len(cols) > 6 else ""
            longdef = cols[7].strip() if len(cols) > 7 else ""
            # Convert "G:N-M-P" / "H:N-M" into a friendly POS string.
            pos = morph_to_pos(morph)
            definition = clean_def(longdef) or gloss
            # Prefer the brief Tyndale gloss as the front of the definition
            # — it's the most readable hand-edited summary.
            if gloss and gloss not in definition:
                if len(gloss) + 2 + len(definition) <= 95:
                    definition = f"{gloss} — {definition}" if definition else gloss
                else:
                    definition = gloss
            out[sid] = {
                "o": original,
                "t": translit,
                "p": pos,
                "d": definition,
            }
    return out


_POS_MAP = {
    "N": "noun",
    "V": "verb",
    "A": "adjective",
    "Adv": "adverb",
    "Art": "article",
    "Conj": "conjunction",
    "Prep": "preposition",
    "PerP": "pronoun",
    "PosP": "pronoun",
    "RelP": "pronoun",
    "DemP": "pronoun",
    "RefP": "pronoun",
    "Intj": "interjection",
    "Part": "particle",
    "Neg": "negative",
    "Cond": "conditional",
}


def morph_to_pos(m: str) -> str:
    """Convert a STEPBible morph code like 'G:N-M-P' to a friendly POS."""
    if not m:
        return ""
    # Format is "L:Type-Gender-Extra"; only the Type is needed for POS label.
    body = m.split(":", 1)[-1]
    head = body.split("-", 1)[0]
    return _POS_MAP.get(head, head)


# ── Verse parsing ──────────────────────────────────────────────────────────────

# Parses the row prefix "Mat.1.18#01=NKO" into (osis_book, chap, verse, idx).
_ROW_RE = re.compile(r"^([A-Za-z0-9]+)\.(\d+)\.(\d+)#(\d+)=")
# Strip footnote markers we don't want to display (e.g. "<the>" or "[The]").
_BRACKETS_RE = re.compile(r"^[<\[]+|[>\]]+$")
# Pull out parenthesised transliteration like "Τοῦ (Tou)" → ("Τοῦ", "Tou").
_PAREN_RE = re.compile(r"^(.+?)\s*\(([^)]+)\)\s*$")


def parse_strong(col: str) -> str | None:
    """Extract the first dStrong number from a column value like 'G3588=T-GSM'
    or H-prefixed Hebrew tags. STEPBible sometimes wraps with braces or pipes —
    we just take the first G/H + digits we see."""
    if not col:
        return None
    m = re.search(r"[GH]\d{4,5}[A-Z]?", col)
    return m.group(0) if m else None


def parse_word_row(line: str) -> tuple[str, int, int, dict] | None:
    """Parse a TAGNT/TAHOT verse-row. Returns (book, chapter, verse, entry) or
    None if the row is metadata / outside our canonical book set."""
    m = _ROW_RE.match(line)
    if not m:
        return None
    osis_book, chap_s, verse_s, _ = m.groups()
    book = OSIS_TO_NAME.get(osis_book)
    if book is None:
        return None
    cols = line.rstrip("\n").split("\t")
    if len(cols) < 4:
        return None

    # Original word + transliteration
    raw = cols[1].strip() if len(cols) > 1 else ""
    pm = _PAREN_RE.match(raw)
    if pm:
        original = pm.group(1).strip()
        translit = pm.group(2).strip()
    else:
        # TAHOT format puts transliteration in col 2 of an unparenthesised
        # original word.
        original = raw
        translit = (cols[2] if len(cols) > 2 else "").strip()

    # Pick the column that holds English. TAGNT layout is:
    #   col 1: original (Greek), col 2: English, col 3: dStrong=Grammar
    # TAHOT layout is:
    #   col 1: original (Hebrew), col 2: translit, col 3: English, col 4: dStrong
    # We tell them apart by where the dStrong-looking column lives.
    s_at_3 = parse_strong(cols[3]) if len(cols) > 3 else None
    s_at_4 = parse_strong(cols[4]) if len(cols) > 4 else None
    if s_at_3 and "=" in (cols[3] if len(cols) > 3 else ""):
        # TAGNT
        english = (cols[2] if len(cols) > 2 else "").strip()
        strongs = s_at_3
        lemma_col = cols[4] if len(cols) > 4 else ""
    elif s_at_4:
        # TAHOT
        english = (cols[3] if len(cols) > 3 else "").strip()
        strongs = s_at_4
        lemma_col = cols[5] if len(cols) > 5 else ""
    else:
        return None

    # Strip bracket markup like "<the>" or "[The]" — a hint to the reader,
    # not real translation text.
    english = _BRACKETS_RE.sub("", english)

    # Lemma=Gloss column — extract just the lemma (left of first "=").
    lemma = ""
    if "=" in lemma_col:
        lemma = lemma_col.split("=", 1)[0].strip()

    if not english or english in {"-", "—"}:
        return None

    entry: dict = {"w": english}
    if strongs:
        entry["s"] = strongs
    if lemma:
        entry["l"] = lemma
    if original and original != english:
        entry["o"] = original
    if translit:
        entry["t"] = translit
    return book, int(chap_s), int(verse_s), entry


def split_english(english: str) -> list[str]:
    """The TAGNT english column sometimes joins multiple english words for
    a single Greek word — e.g. "[The] book". For tap-mapping we want each
    distinct surface form to be tappable. We keep the column intact, since
    tapping any token in the joined phrase still maps to the same Strong's.
    """
    return [t for t in english.split() if t]


def build_verse_index(files: list[str]) -> dict[str, list[dict]]:
    """Build map "Book Chap:Verse" → list of word entries.

    Entries are kept in source order (== reading order). Each TAGNT/TAHOT row
    maps a single ORIGINAL-language word to one or more english surface
    tokens; we expand on whitespace so each visible english word becomes
    tappable while still carrying the same Strong's metadata.
    """
    index: dict[str, list[dict]] = {}
    for fname in files:
        path = RAW_DIR / fname
        if not path.exists():
            print(f"  WARN: missing {path}", file=sys.stderr)
            continue
        with open(path, "r", encoding="utf-8") as f:
            for line in f:
                parsed = parse_word_row(line)
                if parsed is None:
                    continue
                book, chap, verse, entry = parsed
                key = f"{book} {chap}:{verse}"
                lst = index.setdefault(key, [])
                # Expand multi-word English on whitespace so each surface
                # token is independently tappable but shares the same
                # Strong's payload.
                tokens = split_english(entry["w"]) or [entry["w"]]
                for tok in tokens:
                    e = dict(entry)
                    e["w"] = tok
                    lst.append(e)
    return index


# ── Main ──────────────────────────────────────────────────────────────────────

def write_json(path: Path, payload) -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, separators=(",", ":"))
    return path.stat().st_size


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--nt-only", action="store_true",
                        help="Skip Hebrew OT (smaller output).")
    args = parser.parse_args()

    print("Building Strong's tagging assets ...")
    ensure_downloads()

    # ── Lexicon ──
    print("Parsing lexicons ...")
    lex_g = parse_lexicon(RAW_DIR / "TBESG.txt")
    lex_h: dict[str, dict] = {}
    if not args.nt_only:
        lex_h = parse_lexicon(RAW_DIR / "TBESH.txt")
    lexicon = {**lex_g, **lex_h}
    lex_size = write_json(OUT_LEXICON, lexicon)
    print(f"  Lexicon entries: {len(lexicon)}  ({lex_size / 1024 / 1024:.2f} MB)")

    # ── Verses ──
    files = list(TAGNT_FILES)
    if not args.nt_only:
        files.extend(TAHOT_FILES)
    print(f"Parsing verse tags from {len(files)} TAGNT/TAHOT files ...")
    index = build_verse_index(files)
    verses_size = write_json(OUT_VERSES, index)
    mb = verses_size / 1024 / 1024
    print(f"  Tagged verses: {len(index)}  ({mb:.2f} MB)")

    # ── Size ceiling fallback ──
    if mb > SIZE_BUDGET_MB and not args.nt_only:
        print(f"  Output {mb:.1f} MB exceeds budget {SIZE_BUDGET_MB} MB — "
              f"falling back to NT-only.")
        index = build_verse_index(TAGNT_FILES)
        verses_size = write_json(OUT_VERSES, index)
        mb = verses_size / 1024 / 1024
        # Drop Hebrew lexicon entries since OT verses are gone.
        lexicon = lex_g
        lex_size = write_json(OUT_LEXICON, lexicon)
        print(f"  After fallback: {len(index)} verses, {mb:.2f} MB")
        print(f"  After fallback lexicon: {len(lexicon)} entries, "
              f"{lex_size / 1024 / 1024:.2f} MB")

    # Write a tiny manifest to record what we shipped.
    nt_only_flag = args.nt_only or len(index) < 9000
    manifest = {
        "version": 1,
        "scope": "NT" if nt_only_flag else "NT+OT",
        "verses": len(index),
        "lexiconEntries": len(lexicon),
    }
    (OUT_DIR / "strongs_manifest.json").write_text(
        json.dumps(manifest, indent=2), encoding="utf-8")
    print()
    print("Done.")
    print(f"  {OUT_VERSES.relative_to(REPO_ROOT)}: "
          f"{verses_size / 1024 / 1024:.2f} MB")
    print(f"  {OUT_LEXICON.relative_to(REPO_ROOT)}: "
          f"{lex_size / 1024 / 1024:.2f} MB")
    print(f"  scope: {manifest['scope']}")


if __name__ == "__main__":
    main()
