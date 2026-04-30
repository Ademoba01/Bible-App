"""Build red-letter (Christ's words) and blue-letter (God's direct speech)
span data for the Rhema Bible app.

Source:
  KJV OSIS XML from eBible.org via seven1m/open-bibles
  (public domain, contains 2,021 ``<q who="Jesus">`` milestone markers).

Output:
  assets/data/redletter_kjv.json   — keyed by verse, word-index ranges per
  span. Format:

    {
      "Matt 5:3": {"red": [[0, 24]], "blue": []},
      "Gen 1:3":  {"red": [],         "blue": [[3, 7]]}
    }

  Indices are 0-based and inclusive. Tokenization splits on whitespace so
  the runtime renderer (which walks the same way) can match by index
  without character-offset alignment headaches.

Strategy:
  • Red letters come from the OSIS markup itself — exact and authoritative.
  • Blue letters (Old Testament + Acts where God speaks directly) use a
    regex pass over each verse, matching the standard speech-frame patterns
    KJV uses ("Thus saith the LORD", "the LORD said unto X", "And God
    said", etc.) and colors from the speech opener to verse end (or to a
    detected closer like "saith the LORD").

Run:
  python3 scripts/build_redletter.py
"""

from __future__ import annotations

import json
import re
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

OSIS_URL = "https://raw.githubusercontent.com/seven1m/open-bibles/master/eng-kjv.osis.xml"
OSIS_LOCAL = Path("/tmp/kjv.osis.xml")
OUT = Path("assets/data/redletter_kjv.json")

# OSIS book id → our book name (used in strongs/kjv json).
OSIS_TO_NAME = {
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
    "Matt": "Matthew", "Mark": "Mark", "Luke": "Luke", "John": "John",
    "Acts": "Acts", "Rom": "Romans", "1Cor": "1 Corinthians",
    "2Cor": "2 Corinthians", "Gal": "Galatians", "Eph": "Ephesians",
    "Phil": "Philippians", "Col": "Colossians", "1Thess": "1 Thessalonians",
    "2Thess": "2 Thessalonians", "1Tim": "1 Timothy", "2Tim": "2 Timothy",
    "Titus": "Titus", "Phlm": "Philemon", "Heb": "Hebrews", "Jas": "James",
    "1Pet": "1 Peter", "2Pet": "2 Peter", "1John": "1 John", "2John": "2 John",
    "3John": "3 John", "Jude": "Jude", "Rev": "Revelation",
}

OT_BOOKS = {
    "Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy", "Joshua",
    "Judges", "Ruth", "1 Samuel", "2 Samuel", "1 Kings", "2 Kings",
    "1 Chronicles", "2 Chronicles", "Ezra", "Nehemiah", "Esther", "Job",
    "Psalms", "Proverbs", "Ecclesiastes", "Song of Solomon", "Isaiah",
    "Jeremiah", "Lamentations", "Ezekiel", "Daniel", "Hosea", "Joel",
    "Amos", "Obadiah", "Jonah", "Micah", "Nahum", "Habakkuk", "Zephaniah",
    "Haggai", "Zechariah", "Malachi",
}

# Blue-letter (God's direct speech) speech-opener patterns. Match the
# phrase + everything after it on the same verse. Conservative: we only
# fire on these very-stable KJV templates — false positives would be
# embarrassing and confusing.
BLUE_OPENERS = [
    r"\bthus saith the LORD\b[^.;]*[,:]\s*",
    r"\bthe LORD said\b[^.;]*[,:]\s*",
    r"\bthe LORD spake\b[^.;]*[,:]\s*",
    r"\bthe LORD answered\b[^.;]*[,:]\s*",
    r"\band God said\b[^.;]*[,:]\s*",
    r"\bGod said unto\b[^.;]*[,:]\s*",
    r"\bGod spake\b[^.;]*[,:]\s*",
    r"\bword of the LORD came\b[^.;]*[,:]\s*",
]
BLUE_RE = re.compile("|".join(BLUE_OPENERS), re.IGNORECASE)


def fetch_osis() -> bytes:
    if OSIS_LOCAL.exists() and OSIS_LOCAL.stat().st_size > 1_000_000:
        print(f"Using cached {OSIS_LOCAL}")
        return OSIS_LOCAL.read_bytes()
    print(f"Downloading {OSIS_URL}")
    data = urllib.request.urlopen(OSIS_URL).read()
    OSIS_LOCAL.write_bytes(data)
    return data


def tokenize(text: str) -> list[str]:
    """Same word-tokenization the runtime uses: whitespace split."""
    return text.split()


def parse(xml_bytes: bytes) -> dict:
    """Stream-parse the OSIS file, accumulating verse text and tracking
    which characters fall inside a `<q who="Jesus">` span. Returns a dict
    keyed by verse-id with red and blue word-index ranges.
    """
    NS = "{http://www.bibletechnologies.net/2003/OSIS/namespace}"
    out: dict[str, dict] = {}
    cur_verse: str | None = None
    buf: list[str] = []     # plain text accumulated for the current verse
    red_chars: list[bool] = []  # parallel to character stream — is this char Jesus?
    in_jesus = 0            # nesting depth (>0 means inside <q who="Jesus">)

    def flush():
        nonlocal cur_verse, buf, red_chars, in_jesus
        if cur_verse is None:
            return
        text = "".join(buf)
        # Tokenize the verse + decide for each token whether it's red.
        # A token is red if ANY of its characters were inside a Jesus span.
        # The character stream and red_chars are parallel by construction.
        words = []           # list of (word, is_red)
        i = 0
        while i < len(text):
            # Skip whitespace
            while i < len(text) and text[i].isspace():
                i += 1
            if i >= len(text):
                break
            j = i
            word_red = False
            while j < len(text) and not text[j].isspace():
                if j < len(red_chars) and red_chars[j]:
                    word_red = True
                j += 1
            words.append(text[i:j])
            # Mark this word as red if any of its chars were red
            i = j
        # Recompute is_red per word using the original index spans.
        red_idx_set = set()
        word_idx = -1
        i = 0
        while i < len(text):
            while i < len(text) and text[i].isspace():
                i += 1
            if i >= len(text):
                break
            word_idx += 1
            j = i
            any_red = False
            while j < len(text) and not text[j].isspace():
                if j < len(red_chars) and red_chars[j]:
                    any_red = True
                j += 1
            if any_red:
                red_idx_set.add(word_idx)
            i = j

        red_ranges = compress_indices(sorted(red_idx_set))

        # Blue ranges — regex scan over the joined verse text
        blue_ranges = detect_blue_ranges(text, words)

        if red_ranges or blue_ranges:
            out[cur_verse] = {
                "red": red_ranges,
                "blue": blue_ranges,
            }

        cur_verse = None
        buf = []
        red_chars = []

    for event, elem in ET.iterparse(
        iter([xml_bytes]) if False else xml_to_iter(xml_bytes),
        events=("start", "end")
    ):
        tag = elem.tag.replace(NS, "")

        if event == "start":
            if tag == "verse":
                sid = elem.attrib.get("sID")
                eid = elem.attrib.get("eID")
                if sid:
                    flush()
                    cur_verse = osis_id_to_key(sid.split(".seID")[0])
                    buf = []
                    red_chars = []
                    in_jesus = 0
                elif eid:
                    flush()

            elif tag == "q":
                sid = elem.attrib.get("sID")
                eid = elem.attrib.get("eID")
                who = elem.attrib.get("who", "")
                if sid and who == "Jesus":
                    in_jesus += 1
                elif eid and in_jesus > 0:
                    in_jesus -= 1
            # Capture text of milestone elements via tail / text below

            # Append element's leading text + tail text to buffer if inside a
            # verse. (iterparse yields elem.text on start, elem.tail on end.)
            t = elem.text
            if t and cur_verse is not None:
                buf.append(t)
                red_chars.extend([in_jesus > 0] * len(t))

        elif event == "end":
            t = elem.tail
            if t and cur_verse is not None:
                buf.append(t)
                red_chars.extend([in_jesus > 0] * len(t))
            elem.clear()

    flush()
    return out


def xml_to_iter(blob: bytes):
    """Tiny shim: ET.iterparse needs a file-like, not bytes."""
    import io
    return io.BytesIO(blob)


def compress_indices(idxs: list[int]) -> list[list[int]]:
    """[1,2,3,5,6] → [[1,3],[5,6]]"""
    if not idxs:
        return []
    out = []
    s = e = idxs[0]
    for i in idxs[1:]:
        if i == e + 1:
            e = i
        else:
            out.append([s, e])
            s = e = i
    out.append([s, e])
    return out


def osis_id_to_key(osis: str) -> str | None:
    """Gen.1.1 → 'Genesis 1:1'"""
    parts = osis.split(".")
    if len(parts) < 3:
        return None
    book, ch, vs = parts[0], parts[1], parts[2]
    name = OSIS_TO_NAME.get(book)
    if name is None:
        return None
    return f"{name} {ch}:{vs}"


def detect_blue_ranges(text: str, words: list[str]) -> list[list[int]]:
    """Run the blue-letter regex against the verse and return word-index
    ranges. Conservative: we only color from the matched opener forward
    to the END of the verse (no attempt to detect mid-verse closers — the
    regex would mis-fire too often to be safe).
    """
    if not words:
        return []
    matches = list(BLUE_RE.finditer(text))
    if not matches:
        return []

    # Convert character match-end position to word index.
    # Build a parallel array: char_idx → word_idx.
    word_idx_at_char: list[int] = [0] * (len(text) + 1)
    char = 0
    word_idx = -1
    i = 0
    while i < len(text):
        if text[i].isspace():
            word_idx_at_char[i] = max(word_idx, 0)
            i += 1
            continue
        word_idx += 1
        while i < len(text) and not text[i].isspace():
            word_idx_at_char[i] = word_idx
            i += 1
    word_idx_at_char[len(text)] = max(word_idx, 0)

    ranges: list[list[int]] = []
    for m in matches:
        # Start the range at the word AFTER the speech-opener match
        start_char = m.end()
        if start_char >= len(text):
            continue
        start_word = word_idx_at_char[min(start_char, len(text) - 1)]
        end_word = max(word_idx, 0)
        if end_word >= start_word:
            ranges.append([start_word, end_word])

    # Merge overlapping ranges
    ranges.sort()
    merged: list[list[int]] = []
    for r in ranges:
        if merged and r[0] <= merged[-1][1] + 1:
            merged[-1][1] = max(merged[-1][1], r[1])
        else:
            merged.append(r)
    return merged


def propagate_blue_across_verses(data: dict, kjv_verses: dict) -> dict:
    """Multi-verse propagation for God's speech. KJV introduces long
    speeches (Decalogue, Job, prophets) with phrases like "And God spake
    all these words, saying," — the speech opener ends with ", saying,"
    and the actual speech is in subsequent verses, NOT the opener verse.

    This pass walks the canonical verse order and, when it sees a verse
    that ends in ", saying" (or close variants), propagates blue spans
    forward verse-by-verse until it hits a narrative re-entry marker.
    """
    # Build a sorted list of (book, chapter, verse, key) tuples grouped
    # by chapter. We process per-chapter so propagation never crosses
    # chapter boundaries.
    by_chapter: dict[tuple[str, int], list[tuple[int, str]]] = {}
    for key in kjv_verses.keys():
        # key looks like "Exodus 20:5" — split off the verse number
        # (handles 1-3 digit book numbers like "1 Samuel" too)
        m = re.match(r"^(.+?)\s+(\d+):(\d+)$", key)
        if not m:
            continue
        book = m.group(1)
        ch = int(m.group(2))
        vs = int(m.group(3))
        by_chapter.setdefault((book, ch), []).append((vs, key))

    SAYING_RE = re.compile(r",\s*saying\s*[,.:]?\s*$", re.IGNORECASE)
    # Narrative re-entry detection — stops blue speech propagation. Matches
    # "And <up to 4 words of subject> <past-tense action verb>" near the
    # start of a verse. Captures "And all the people saw", "And he said",
    # "And Moses spake", "And it came to pass", etc. Inside actual divine
    # speech (Decalogue, prophetic oracles) the language is direct address
    # ("Thou shalt", "I am") so this regex never matches there — propagation
    # stays clean.
    NARRATIVE_RESUMPTION = re.compile(
        r"^\s*And\s+(?:"
            r"it\s+came\s+to\s+pass\b|"
            r"when\b|after\b|now\b|so\b|behold\b|"
            r"\S+(?:\s+\S+){0,3}\s+"
            r"(?:said|spake|saw|did|cried|wept|went|came|arose|heard|"
            r"answered|asked|fled|brought|gathered|stood|fell|died|"
            r"departed|gave|set|put|laid|took|made|told|sent|removed|"
            r"knew|builded|ate|drank|ascended|descended|reigned|"
            r"called|hearkened|served|forsook|destroyed|smote|"
            r"returned|carried|wrought|judged|delivered|prepared)"
        r")",
        re.IGNORECASE,
    )

    for chapter_verses in by_chapter.values():
        chapter_verses.sort()
        in_blue = False
        for vs_num, key in chapter_verses:
            text = kjv_verses[key]
            entry = data.setdefault(key, {"red": [], "blue": []})

            if in_blue:
                # Check if this verse re-enters narrative — if so, stop blue.
                if NARRATIVE_RESUMPTION.match(text):
                    in_blue = False
                else:
                    # Whole verse is continuation of God's speech — blue
                    # the entire token range. Skip if already has blue
                    # (e.g. nested re-opener) so we don't duplicate.
                    word_count = len(tokenize(text))
                    if word_count > 0 and not entry["blue"]:
                        entry["blue"] = [[0, word_count - 1]]

            # After processing this verse, see if it OPENS a multi-verse
            # speech ending in ", saying," — the actual speech is in the
            # next verse onward.
            if SAYING_RE.search(text):
                # Was this saying-opener for God / the LORD specifically?
                # Heuristic: opener line contains "LORD", "God", or "he"
                # in a context where the prior subject was God. We
                # approximate by searching for "LORD" or "God" in the
                # verse text — narrow enough to avoid coloring random
                # human speakers' "saying," continuations.
                if re.search(r"\b(LORD|God|Yahweh|Jehovah)\b", text):
                    in_blue = True

    return data


FILENAME_TO_BOOK = {
    "1chronicles": "1 Chronicles", "2chronicles": "2 Chronicles",
    "1corinthians": "1 Corinthians", "2corinthians": "2 Corinthians",
    "1john": "1 John", "2john": "2 John", "3john": "3 John",
    "1kings": "1 Kings", "2kings": "2 Kings",
    "1peter": "1 Peter", "2peter": "2 Peter",
    "1samuel": "1 Samuel", "2samuel": "2 Samuel",
    "1thessalonians": "1 Thessalonians", "2thessalonians": "2 Thessalonians",
    "1timothy": "1 Timothy", "2timothy": "2 Timothy",
    "songofsolomon": "Song of Solomon",
}


def load_kjv_verses() -> dict[str, str]:
    """Load our local KJV bible JSON files into a flat verse map.

    Each book file is a flat list of:
      [{type: "paragraph text", chapterNumber: N, verseNumber: M, value: "..."}, ...]
    """
    out: dict[str, str] = {}
    bible_dir = Path("assets/bibles/kjv")
    if not bible_dir.exists():
        print(f"  (skipped multi-verse propagation: {bible_dir} not found)")
        return out
    for book_file in bible_dir.glob("*.json"):
        try:
            entries = json.loads(book_file.read_text())
        except Exception:
            continue
        if not isinstance(entries, list):
            continue
        stem = book_file.stem.lower()
        book_name = FILENAME_TO_BOOK.get(stem, stem.capitalize())
        for e in entries:
            ch = e.get("chapterNumber")
            vs = e.get("verseNumber")
            text = e.get("value", "")
            if ch and vs and text:
                out[f"{book_name} {ch}:{vs}"] = text
    return out


def main():
    xml_bytes = fetch_osis()
    data = parse(xml_bytes)

    # Multi-verse blue propagation requires our local KJV text (to detect
    # narrative re-entry markers from the actual translation we ship).
    kjv = load_kjv_verses()
    if kjv:
        data = propagate_blue_across_verses(data, kjv)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    # Strip empty entries to keep file size small.
    pruned = {k: v for k, v in data.items() if v.get("red") or v.get("blue")}
    OUT.write_text(json.dumps(pruned, ensure_ascii=False, separators=(",", ":")))
    n_red = sum(1 for v in pruned.values() if v.get("red"))
    n_blue = sum(1 for v in pruned.values() if v.get("blue"))
    print(f"Wrote {OUT}: {len(pruned)} verses with annotations")
    print(f"  Red-letter verses (Christ's words):  {n_red}")
    print(f"  Blue-letter verses (God's speech):   {n_blue}")
    print(f"  File size:                          {OUT.stat().st_size / 1024:.1f} KB")


if __name__ == "__main__":
    main()
