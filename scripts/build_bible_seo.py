"""Generate static HTML per Bible chapter for public search indexing.

Problem: rhemabibles.com is a Flutter web app that renders the whole UI
into a <canvas>. Google, Bing, and LLM crawlers cannot index the verse
text inside a canvas, so searches like "Joel 2:25" don't surface the
site. Fix: emit one static, semantic-HTML page per chapter that Google
CAN index, keyed at web/bible/{book-slug}/{chapter}/index.html. Each
page carries the full chapter text, per-verse <span id="vN"> anchors
(so /bible/joel/2/#v25 deep-links to Joel 2:25), meta tags, and JSON-LD
structured data. The page also links to the Flutter reader via
`?book=X&chapter=Y&verse=Z` so a user clicking a Google result can jump
straight into the app.

Regenerate on demand:
    python3 scripts/build_bible_seo.py

Output:
    web/bible/index.html                       — book index
    web/bible/{slug}/index.html                — chapter index per book
    web/bible/{slug}/{ch}/index.html           — chapter page × 1189
    web/sitemap.xml                            — regenerated with all URLs

Data source: assets/bibles/kjv/*.json — flat list of
    {type, chapterNumber, verseNumber, value}
"""

from __future__ import annotations

import html
import json
import re
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
KJV_DIR = ROOT / "assets" / "bibles" / "kjv"
OUT_ROOT = ROOT / "web" / "bible"
SITEMAP = ROOT / "web" / "sitemap.xml"

SITE = "https://rhemabibles.com"

# ── Book display + slug + testament + Old-Testament ordering ──────────
BOOKS = [
    # (filename stem, display name, slug, testament, canonical position)
    ("genesis", "Genesis", "genesis", "OT"),
    ("exodus", "Exodus", "exodus", "OT"),
    ("leviticus", "Leviticus", "leviticus", "OT"),
    ("numbers", "Numbers", "numbers", "OT"),
    ("deuteronomy", "Deuteronomy", "deuteronomy", "OT"),
    ("joshua", "Joshua", "joshua", "OT"),
    ("judges", "Judges", "judges", "OT"),
    ("ruth", "Ruth", "ruth", "OT"),
    ("1samuel", "1 Samuel", "1-samuel", "OT"),
    ("2samuel", "2 Samuel", "2-samuel", "OT"),
    ("1kings", "1 Kings", "1-kings", "OT"),
    ("2kings", "2 Kings", "2-kings", "OT"),
    ("1chronicles", "1 Chronicles", "1-chronicles", "OT"),
    ("2chronicles", "2 Chronicles", "2-chronicles", "OT"),
    ("ezra", "Ezra", "ezra", "OT"),
    ("nehemiah", "Nehemiah", "nehemiah", "OT"),
    ("esther", "Esther", "esther", "OT"),
    ("job", "Job", "job", "OT"),
    ("psalms", "Psalms", "psalms", "OT"),
    ("proverbs", "Proverbs", "proverbs", "OT"),
    ("ecclesiastes", "Ecclesiastes", "ecclesiastes", "OT"),
    ("songofsolomon", "Song of Solomon", "song-of-solomon", "OT"),
    ("isaiah", "Isaiah", "isaiah", "OT"),
    ("jeremiah", "Jeremiah", "jeremiah", "OT"),
    ("lamentations", "Lamentations", "lamentations", "OT"),
    ("ezekiel", "Ezekiel", "ezekiel", "OT"),
    ("daniel", "Daniel", "daniel", "OT"),
    ("hosea", "Hosea", "hosea", "OT"),
    ("joel", "Joel", "joel", "OT"),
    ("amos", "Amos", "amos", "OT"),
    ("obadiah", "Obadiah", "obadiah", "OT"),
    ("jonah", "Jonah", "jonah", "OT"),
    ("micah", "Micah", "micah", "OT"),
    ("nahum", "Nahum", "nahum", "OT"),
    ("habakkuk", "Habakkuk", "habakkuk", "OT"),
    ("zephaniah", "Zephaniah", "zephaniah", "OT"),
    ("haggai", "Haggai", "haggai", "OT"),
    ("zechariah", "Zechariah", "zechariah", "OT"),
    ("malachi", "Malachi", "malachi", "OT"),
    ("matthew", "Matthew", "matthew", "NT"),
    ("mark", "Mark", "mark", "NT"),
    ("luke", "Luke", "luke", "NT"),
    ("john", "John", "john", "NT"),
    ("acts", "Acts", "acts", "NT"),
    ("romans", "Romans", "romans", "NT"),
    ("1corinthians", "1 Corinthians", "1-corinthians", "NT"),
    ("2corinthians", "2 Corinthians", "2-corinthians", "NT"),
    ("galatians", "Galatians", "galatians", "NT"),
    ("ephesians", "Ephesians", "ephesians", "NT"),
    ("philippians", "Philippians", "philippians", "NT"),
    ("colossians", "Colossians", "colossians", "NT"),
    ("1thessalonians", "1 Thessalonians", "1-thessalonians", "NT"),
    ("2thessalonians", "2 Thessalonians", "2-thessalonians", "NT"),
    ("1timothy", "1 Timothy", "1-timothy", "NT"),
    ("2timothy", "2 Timothy", "2-timothy", "NT"),
    ("titus", "Titus", "titus", "NT"),
    ("philemon", "Philemon", "philemon", "NT"),
    ("hebrews", "Hebrews", "hebrews", "NT"),
    ("james", "James", "james", "NT"),
    ("1peter", "1 Peter", "1-peter", "NT"),
    ("2peter", "2 Peter", "2-peter", "NT"),
    ("1john", "1 John", "1-john", "NT"),
    ("2john", "2 John", "2-john", "NT"),
    ("3john", "3 John", "3-john", "NT"),
    ("jude", "Jude", "jude", "NT"),
    ("revelation", "Revelation", "revelation", "NT"),
]


BASE_CSS = """
:root {
  --gold: #D4A843;
  --gold-deep: #A07B28;
  --parchment: #FDF6EC;
  --cream: #FFF8E1;
  --brown: #5D4037;
  --brown-deep: #4A2C1F;
  --brown-mid: #8D6E63;
}
* { box-sizing: border-box; }
html, body { margin: 0; padding: 0; background: var(--parchment); color: var(--brown-deep); font-family: 'Lora', Georgia, 'Times New Roman', serif; line-height: 1.6; }
header { background: var(--brown-deep); color: white; padding: 14px 20px; border-bottom: 3px solid var(--gold); }
header a { color: var(--gold); text-decoration: none; font-weight: 700; font-family: 'Cormorant Garamond', Georgia, serif; font-size: 20px; letter-spacing: 0.3px; }
header .home { color: rgba(255,255,255,0.85); font-size: 13px; margin-left: 12px; font-weight: 400; font-family: 'Lora', Georgia, serif; }
main { max-width: 720px; margin: 0 auto; padding: 24px 20px 60px; }
h1 { font-family: 'Cormorant Garamond', Georgia, serif; font-size: 36px; margin: 8px 0 4px; color: var(--brown-deep); font-weight: 700; letter-spacing: -0.5px; }
h2 { font-family: 'Cormorant Garamond', Georgia, serif; font-size: 22px; margin: 24px 0 8px; color: var(--brown); font-weight: 600; }
.breadcrumb { font-size: 13px; color: var(--brown-mid); margin-bottom: 4px; }
.breadcrumb a { color: var(--brown); text-decoration: none; }
.breadcrumb a:hover { color: var(--gold-deep); text-decoration: underline; }
.chapter-nav { display: flex; justify-content: space-between; align-items: center; padding: 12px 0; margin: 20px 0; border-top: 1px solid rgba(160,123,40,0.2); border-bottom: 1px solid rgba(160,123,40,0.2); font-size: 14px; }
.chapter-nav a { color: var(--brown-deep); text-decoration: none; font-weight: 600; padding: 6px 12px; border-radius: 8px; background: rgba(212,168,67,0.1); }
.chapter-nav a:hover { background: rgba(212,168,67,0.25); }
.chapter-nav .center { color: var(--brown-mid); font-family: 'Cormorant Garamond', Georgia, serif; font-size: 15px; }
.open-app { display: inline-block; margin: 16px 0 8px; padding: 10px 18px; background: linear-gradient(135deg, #FFC107 0%, #D4A843 100%); color: #3E2723; text-decoration: none; font-weight: 700; border-radius: 22px; font-size: 14px; box-shadow: 0 2px 6px rgba(160,123,40,0.2); }
.open-app:hover { transform: translateY(-1px); box-shadow: 0 3px 10px rgba(160,123,40,0.3); }
.verse { padding: 4px 0; scroll-margin-top: 80px; }
.verse-num { color: var(--gold-deep); font-weight: 700; font-size: 0.85em; vertical-align: super; margin-right: 6px; font-family: 'Lora', Georgia, serif; }
.verse-num a { color: inherit; text-decoration: none; }
.verse-num a:hover { color: var(--brown-deep); }
.chapter-text { font-size: 17px; line-height: 1.75; letter-spacing: -0.1px; }
.chapter-text .verse:target { background: rgba(212,168,67,0.25); border-radius: 4px; padding-left: 6px; padding-right: 6px; margin-left: -6px; }
.book-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(160px, 1fr)); gap: 8px; margin: 12px 0 32px; }
.book-grid a { display: block; padding: 10px 12px; background: var(--cream); color: var(--brown-deep); text-decoration: none; border: 1px solid rgba(160,123,40,0.25); border-radius: 8px; font-family: 'Cormorant Garamond', Georgia, serif; font-size: 16px; font-weight: 600; text-align: center; transition: all 0.15s; }
.book-grid a:hover { background: var(--gold); color: var(--brown-deep); border-color: var(--gold-deep); }
.chapter-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(52px, 1fr)); gap: 6px; margin: 12px 0 32px; }
.chapter-grid a { display: block; padding: 10px 0; background: var(--cream); color: var(--brown-deep); text-decoration: none; border: 1px solid rgba(160,123,40,0.25); border-radius: 6px; font-size: 15px; font-weight: 600; text-align: center; transition: all 0.15s; }
.chapter-grid a:hover { background: var(--gold); color: var(--brown-deep); border-color: var(--gold-deep); }
footer { text-align: center; padding: 24px 20px 40px; color: var(--brown-mid); font-size: 12px; }
footer a { color: var(--brown-mid); }
@media (prefers-color-scheme: dark) {
  html, body { background: #2C1A12; color: #E8D9C4; }
  main { color: #E8D9C4; }
  h1, h2 { color: #F5E6C8; }
  .breadcrumb, .breadcrumb a { color: #C8A97E; }
  .chapter-nav a { background: rgba(212,168,67,0.15); color: #F5E6C8; }
  .book-grid a, .chapter-grid a { background: #3E2A1F; color: #E8D9C4; border-color: rgba(212,168,67,0.3); }
  footer { color: #A8926E; }
}
"""


def slugify(name: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")


def esc(s: str) -> str:
    return html.escape(s, quote=True)


def load_book(stem: str) -> dict:
    """Return {chapter_num: [(verse_num, text), ...]} sorted by verse."""
    path = KJV_DIR / f"{stem}.json"
    if not path.exists():
        return {}
    data = json.loads(path.read_text())
    chapters: dict = {}
    for e in data:
        ch = int(e["chapterNumber"])
        vn = int(e["verseNumber"])
        chapters.setdefault(ch, []).append((vn, e["value"]))
    for ch in chapters:
        chapters[ch].sort()
    return chapters


def render_chapter_page(
    book_name: str,
    book_slug: str,
    chapter_num: int,
    verses: list,
    total_chapters: int,
    testament: str,
) -> str:
    ref = f"{book_name} {chapter_num}"
    canonical = f"{SITE}/bible/{book_slug}/{chapter_num}/"
    prev_ch = chapter_num - 1 if chapter_num > 1 else None
    next_ch = chapter_num + 1 if chapter_num < total_chapters else None

    first_verse_text = verses[0][1] if verses else ""
    description = (
        f"{ref} (King James Version). "
        + (first_verse_text[:140] + "…" if len(first_verse_text) > 140 else first_verse_text)
    )

    open_app_url = f"{SITE}/?book={book_name.replace(' ', '%20')}&chapter={chapter_num}"

    # JSON-LD BibleTranslation / CreativeWork
    ldjson = json.dumps(
        {
            "@context": "https://schema.org",
            "@type": "Chapter",
            "position": chapter_num,
            "name": ref,
            "url": canonical,
            "inLanguage": "en",
            "isPartOf": {
                "@type": "Book",
                "name": book_name,
                "bookEdition": "King James Version",
                "url": f"{SITE}/bible/{book_slug}/",
            },
            "publisher": {"@type": "Organization", "name": "Rhema Study Bible"},
        },
        separators=(",", ":"),
    )

    verse_lines = []
    for vn, text in verses:
        verse_lines.append(
            f'<span class="verse" id="v{vn}"><span class="verse-num"><a href="#v{vn}" aria-label="Verse {vn}">{vn}</a></span>{esc(text)}</span>'
        )
    verse_html = "\n      ".join(verse_lines)

    nav_prev = (
        f'<a href="/bible/{book_slug}/{prev_ch}/" rel="prev">‹ Chapter {prev_ch}</a>'
        if prev_ch else '<span></span>'
    )
    nav_next = (
        f'<a href="/bible/{book_slug}/{next_ch}/" rel="next">Chapter {next_ch} ›</a>'
        if next_ch else '<span></span>'
    )

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
<title>{esc(ref)} (KJV) | Rhema Study Bible</title>
<meta name="description" content="{esc(description)}">
<link rel="canonical" href="{canonical}">
<meta property="og:type" content="article">
<meta property="og:title" content="{esc(ref)} (KJV)">
<meta property="og:description" content="{esc(description)}">
<meta property="og:url" content="{canonical}">
<meta property="og:site_name" content="Rhema Study Bible">
<meta name="twitter:card" content="summary">
<meta name="twitter:title" content="{esc(ref)} (KJV)">
<meta name="twitter:description" content="{esc(description)}">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:wght@500;600;700;800&family=Lora:wght@400;500;600;700&display=swap" rel="stylesheet">
<script type="application/ld+json">{ldjson}</script>
<style>{BASE_CSS}</style>
</head>
<body>
<header><a href="/bible/">📖 Rhema Study Bible</a><span class="home"><a href="/" style="color:inherit">Open the app</a></span></header>
<main>
  <div class="breadcrumb"><a href="/bible/">Bible</a> · <a href="/bible/{book_slug}/">{esc(book_name)}</a> · Chapter {chapter_num}</div>
  <h1>{esc(ref)}</h1>
  <p style="color:var(--brown-mid); font-size:13px; margin:0 0 4px;">King James Version · {testament}</p>
  <a class="open-app" href="{open_app_url}" rel="noopener">Open in the Rhema app →</a>

  <div class="chapter-nav">
    {nav_prev}
    <span class="center">Chapter {chapter_num} of {total_chapters}</span>
    {nav_next}
  </div>

  <article class="chapter-text">
      {verse_html}
  </article>

  <div class="chapter-nav">
    {nav_prev}
    <span class="center">Chapter {chapter_num} of {total_chapters}</span>
    {nav_next}
  </div>

  <a class="open-app" href="{open_app_url}" rel="noopener">Open {esc(ref)} in the app →</a>
</main>
<footer>
  <p>The Holy Bible, King James Version — Public Domain.<br>
  Curated by <a href="{SITE}">Rhema Study Bible</a>. <a href="/privacy.html">Privacy</a>.</p>
</footer>
</body>
</html>
"""


def render_book_page(book_name: str, book_slug: str, chapters: dict, testament: str) -> str:
    canonical = f"{SITE}/bible/{book_slug}/"
    description = f"{book_name} in the King James Version. {len(chapters)} chapters. Full text with verse-level anchors and a companion app for deep study."
    total = len(chapters)
    chapter_links = "\n    ".join(
        f'<a href="/bible/{book_slug}/{ch}/">{ch}</a>' for ch in sorted(chapters.keys())
    )
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
<title>{esc(book_name)} (KJV) — All Chapters | Rhema Study Bible</title>
<meta name="description" content="{esc(description)}">
<link rel="canonical" href="{canonical}">
<meta property="og:type" content="article">
<meta property="og:title" content="{esc(book_name)} (KJV) — All Chapters">
<meta property="og:description" content="{esc(description)}">
<meta property="og:url" content="{canonical}">
<meta property="og:site_name" content="Rhema Study Bible">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:wght@500;600;700;800&family=Lora:wght@400;500;600;700&display=swap" rel="stylesheet">
<style>{BASE_CSS}</style>
</head>
<body>
<header><a href="/bible/">📖 Rhema Study Bible</a><span class="home"><a href="/" style="color:inherit">Open the app</a></span></header>
<main>
  <div class="breadcrumb"><a href="/bible/">Bible</a> · {esc(book_name)}</div>
  <h1>{esc(book_name)}</h1>
  <p style="color:var(--brown-mid); font-size:13px; margin:0 0 12px;">King James Version · {testament} · {total} chapters</p>
  <h2>Chapters</h2>
  <div class="chapter-grid">
    {chapter_links}
  </div>
  <a class="open-app" href="{SITE}/?book={book_name.replace(' ', '%20')}&chapter=1" rel="noopener">Open {esc(book_name)} in the Rhema app →</a>
</main>
<footer>
  <p>The Holy Bible, King James Version — Public Domain.<br>
  Curated by <a href="{SITE}">Rhema Study Bible</a>.</p>
</footer>
</body>
</html>
"""


def render_index(books: list) -> str:
    canonical = f"{SITE}/bible/"
    description = "The complete King James Bible online — all 66 books, 1,189 chapters, 31,102 verses. Fully searchable, indexed by chapter and verse, with a companion study app."

    ot_links = "\n    ".join(
        f'<a href="/bible/{slug}/">{esc(name)}</a>'
        for (_, name, slug, testament) in BOOKS if testament == "OT"
    )
    nt_links = "\n    ".join(
        f'<a href="/bible/{slug}/">{esc(name)}</a>'
        for (_, name, slug, testament) in BOOKS if testament == "NT"
    )

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
<title>The King James Bible Online (KJV) | Rhema Study Bible</title>
<meta name="description" content="{esc(description)}">
<link rel="canonical" href="{canonical}">
<meta property="og:type" content="website">
<meta property="og:title" content="The King James Bible Online (KJV)">
<meta property="og:description" content="{esc(description)}">
<meta property="og:url" content="{canonical}">
<meta property="og:site_name" content="Rhema Study Bible">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:wght@500;600;700;800&family=Lora:wght@400;500;600;700&display=swap" rel="stylesheet">
<style>{BASE_CSS}</style>
</head>
<body>
<header><a href="/bible/">📖 Rhema Study Bible</a><span class="home"><a href="/" style="color:inherit">Open the app</a></span></header>
<main>
  <h1>The King James Bible</h1>
  <p style="color:var(--brown-mid); font-size:14px; margin:0 0 16px;">66 books · 1,189 chapters · 31,102 verses · Public Domain</p>
  <a class="open-app" href="{SITE}/" rel="noopener">Open the study app →</a>

  <h2>Old Testament</h2>
  <div class="book-grid">
    {ot_links}
  </div>

  <h2>New Testament</h2>
  <div class="book-grid">
    {nt_links}
  </div>
</main>
<footer>
  <p>The Holy Bible, King James Version — Public Domain.<br>
  Curated by <a href="{SITE}">Rhema Study Bible</a>. <a href="/privacy.html">Privacy</a>.</p>
</footer>
</body>
</html>
"""


def render_sitemap(book_chapters: dict) -> str:
    today = date.today().isoformat()
    urls = [
        f"{SITE}/",
        f"{SITE}/welcome.html",
        f"{SITE}/bible/",
    ]
    for (_, _, slug, _) in BOOKS:
        urls.append(f"{SITE}/bible/{slug}/")
        for ch in book_chapters.get(slug, []):
            urls.append(f"{SITE}/bible/{slug}/{ch}/")

    entries = "\n".join(
        f"  <url><loc>{u}</loc><lastmod>{today}</lastmod></url>" for u in urls
    )
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
{entries}
</urlset>
"""


def main() -> None:
    OUT_ROOT.mkdir(parents=True, exist_ok=True)
    # Global index
    (OUT_ROOT / "index.html").write_text(render_index(BOOKS))

    total_chapters = 0
    total_verses = 0
    book_chapters_index: dict = {}

    for (stem, name, slug, testament) in BOOKS:
        chapters = load_book(stem)
        if not chapters:
            print(f"  ⚠️  skipped {name} (no data)")
            continue
        book_dir = OUT_ROOT / slug
        book_dir.mkdir(parents=True, exist_ok=True)
        # Book landing page
        (book_dir / "index.html").write_text(
            render_book_page(name, slug, chapters, testament)
        )
        book_chapters_index[slug] = sorted(chapters.keys())
        for ch, verses in chapters.items():
            ch_dir = book_dir / str(ch)
            ch_dir.mkdir(exist_ok=True)
            (ch_dir / "index.html").write_text(
                render_chapter_page(
                    name, slug, ch, verses, len(chapters), testament
                )
            )
            total_chapters += 1
            total_verses += len(verses)
        print(f"  ✓ {name}: {len(chapters)} chapters")

    # Sitemap
    SITEMAP.write_text(render_sitemap(book_chapters_index))

    print()
    print(f"Wrote {total_chapters} chapter pages, {total_verses} verses, plus 66 book indexes and 1 global index.")
    print(f"Sitemap: {SITEMAP} ({len(book_chapters_index) + total_chapters + 3} URLs)")


if __name__ == "__main__":
    main()
