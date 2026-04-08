# Translations — sourcing & licensing

The app supports multiple translations side-by-side. Each lives under
`assets/bibles/<id>/<book>.json` (one file per book). The book filenames
must match those in `lib/data/books.dart`. The format is the same flat
array used by the WEB assets:

```json
[
  { "type": "paragraph text", "chapterNumber": 1, "verseNumber": 1,
    "value": "In the beginning..." }
]
```

To enable a translation in the UI, flip `available: true` for its entry
in `lib/data/translations.dart`. No other code changes needed.

---

## English

### WEB — World English Bible  ✅ included
- License: **public domain**
- Style: modern English, readable, gender-neutral where appropriate
- Source: https://ebible.org/find/details.php?id=eng-web

### BSB — Berean Standard Bible  ⚙️ scaffolded
- License: **public domain** (Berean Bible Foundation)
- Style: formal-equivalence, the closest open-license analog to NASB/ESV
- Source: https://bereanbible.com/  (single TSV file)
- To populate: from the repo root, run
  ```
  dart run tools/fetch_bsb.dart
  ```
  Then set `available: true` for `bsb` in `lib/data/translations.dart`.

> **Why BSB and not NASB?** NASB is copyrighted by the Lockman Foundation;
> we cannot legally redistribute or build a derivative inside the app. BSB
> is the closest publicly-licensed equivalent of the same translation
> philosophy and is what serious open-Bible projects (BibleHub, OpenBible,
> Berean Study Bible apps) ship.

---

## Nigerian Pidgin

There is **no fully open-licensed Pidgin Bible** that can be redistributed
inside an app today. Options, ranked by realism:

1. **Wycliffe / Bible Society of Nigeria — "Common Language" Pidgin Bible**
   (also called *Nigerian Pidgin Common Language*, BSN, 2020).
   - Status: **copyrighted**, owned by the Bible Society of Nigeria.
   - Path: contact rights@biblesociety-nigeria.org for an API or
     redistribution license. They have licensed digital editions to
     YouVersion / Bible.com — that's the precedent. Expect a per-app
     agreement, possibly royalty-bearing or a flat fee.
   - This is the **only complete, scholarly, simple Pidgin Bible** in
     existence. If we want quality + completeness without doing the
     translation ourselves, this is the path.

2. **Wycliffe Global Alliance / SIL — partial drafts**
   - Some books (NT portions) circulate under
     [open.bible](https://open.bible/) and the Digital Bible Library.
     Coverage is **incomplete** (typically Gospels + a few epistles).
     License is per-text — check each.

3. **Commission a translation**
   - For a "simplest form of Pidgin" that *we own outright*, you would
     hire native-speaker translators (typically a 2-person team + a
     consultant reviewer) working from BSB/WEB as the source text.
   - Realistic budget for the full 66 books at simplest-Pidgin level:
     a small church-supported team can produce a draft NT in months and
     full Bible in 1–2 years. This is what e.g. unfoldingWord does for
     "Gateway Languages" and they release as CC-BY-SA — could be a
     partner.
   - **Do not** generate this with an LLM. Pidgin is a real language with
     real grammar, and LLM Pidgin output is unreliable enough that
     publishing it as scripture would mislead users.

**Recommendation:** start by writing to the Bible Society of Nigeria for
the BSN Pidgin license. If that's too slow/expensive, partner with
unfoldingWord (https://www.unfoldingword.org/) on a CC-BY-SA Simple
Pidgin draft.

---

## Modern Yoruba

The user explicitly asked for **modern Yoruba (not the old Bibeli Mimo)**,
faithful to a formal-equivalence source.

1. **Bibeli Mimọ Bayii (BMB) / Yoruba Contemporary Bible**
   - Bible Society of Nigeria, modern Yoruba revision.
   - **Copyrighted**; license via Bible Society of Nigeria same as Pidgin.
   - This is the canonical "modern Yoruba" choice and is what you should
     pursue first.

2. **Bibeli Mimo (1900 / Crowther revision)**
   - Public domain, but this is **the very edition the user said not to
     use**. Skip.

3. **Yoruba New World Translation**
   - Jehovah's Witnesses; not redistributable, doctrinally distinct — skip.

4. **Commission / partner translation**
   - Same model as Pidgin above. Yoruba has a much larger pool of
     trained translators; an unfoldingWord-style CC-BY-SA modern Yoruba
     project working from BSB is feasible and several diaspora groups
     have shown interest in funding one.

**Recommendation:** Bible Society of Nigeria license for BMB is the
fastest path to a high-quality modern Yoruba in the app. Long-term, an
open-license commissioned translation gives you redistribution freedom.

---

## Why we will not LLM-generate Bible translations

- Theological reliability: small word choices change doctrine
  ("propitiation" vs "atoning sacrifice", "slave" vs "servant"). LLM
  output is not auditable in the way a translation committee is.
- User trust: people open a Bible app expecting scripture, not synthetic
  text. Shipping LLM-generated verses without disclosure would be
  dishonest; with disclosure, no one would use it.
- Legal exposure: if the LLM was trained on copyrighted translations
  (NASB, NIV, NLT), the output may be a derivative work.

What an LLM **can** legitimately help with: alignment review, draft
glossaries, translator-facing tools, and quality checks against a
human-produced draft. None of those are "generate the Bible."

---

## Adding a translation — checklist

1. Acquire JSON files (one per book) in the format above.
2. Drop them into `assets/bibles/<id>/`.
3. Make sure book filenames match `lib/data/books.dart`.
4. Flip `available: true` for that translation in
   `lib/data/translations.dart`.
5. `flutter pub get && flutter run` — the settings switcher will pick it
   up automatically.
