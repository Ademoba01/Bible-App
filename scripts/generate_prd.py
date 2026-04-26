#!/usr/bin/env python3
"""Generate Rhema Study Bible PRD & Project Documentation PDF."""

from reportlab.lib.pagesizes import letter
from reportlab.lib.units import inch
from reportlab.lib.colors import HexColor
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_JUSTIFY
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, HRFlowable, KeepTogether,
)
from reportlab.lib import colors
import datetime

# ── Colors ──────────────────────────────────────────────────────
GOLD = HexColor('#C6A04A')
BROWN_DARK = HexColor('#3E2723')
BROWN_MID = HexColor('#6D4C41')
CREAM = HexColor('#FAF6F0')
WHITE = HexColor('#FFFFFF')
LIGHT_GOLD = HexColor('#F5ECD7')

# ── Styles ──────────────────────────────────────────────────────
def make_styles():
    s = {}
    s['cover_title'] = ParagraphStyle(
        'CoverTitle', fontName='Helvetica-Bold', fontSize=32,
        textColor=BROWN_DARK, alignment=TA_CENTER, spaceAfter=8,
    )
    s['cover_sub'] = ParagraphStyle(
        'CoverSub', fontName='Helvetica', fontSize=14,
        textColor=BROWN_MID, alignment=TA_CENTER, spaceAfter=4,
    )
    s['cover_date'] = ParagraphStyle(
        'CoverDate', fontName='Helvetica-Oblique', fontSize=11,
        textColor=BROWN_MID, alignment=TA_CENTER, spaceAfter=20,
    )
    s['h1'] = ParagraphStyle(
        'H1', fontName='Helvetica-Bold', fontSize=22,
        textColor=BROWN_DARK, spaceBefore=24, spaceAfter=12,
    )
    s['h2'] = ParagraphStyle(
        'H2', fontName='Helvetica-Bold', fontSize=16,
        textColor=GOLD, spaceBefore=18, spaceAfter=8,
    )
    s['h3'] = ParagraphStyle(
        'H3', fontName='Helvetica-Bold', fontSize=13,
        textColor=BROWN_MID, spaceBefore=12, spaceAfter=6,
    )
    s['body'] = ParagraphStyle(
        'Body', fontName='Helvetica', fontSize=10.5,
        textColor=BROWN_DARK, leading=15, alignment=TA_JUSTIFY,
        spaceAfter=6,
    )
    s['bullet'] = ParagraphStyle(
        'Bullet', fontName='Helvetica', fontSize=10.5,
        textColor=BROWN_DARK, leading=15, leftIndent=20,
        bulletIndent=8, spaceAfter=4,
    )
    s['sub_bullet'] = ParagraphStyle(
        'SubBullet', fontName='Helvetica', fontSize=10,
        textColor=BROWN_MID, leading=14, leftIndent=40,
        bulletIndent=28, spaceAfter=3,
    )
    s['code'] = ParagraphStyle(
        'Code', fontName='Courier', fontSize=9,
        textColor=BROWN_DARK, leading=12, leftIndent=20,
        backColor=CREAM, spaceAfter=6,
    )
    s['label'] = ParagraphStyle(
        'Label', fontName='Helvetica-Bold', fontSize=10,
        textColor=GOLD, spaceAfter=2,
    )
    s['value'] = ParagraphStyle(
        'Value', fontName='Courier', fontSize=10,
        textColor=BROWN_DARK, leftIndent=12, spaceAfter=8,
    )
    s['footer'] = ParagraphStyle(
        'Footer', fontName='Helvetica-Oblique', fontSize=8,
        textColor=BROWN_MID, alignment=TA_CENTER,
    )
    return s

def gold_rule():
    return HRFlowable(width='100%', thickness=2, color=GOLD, spaceAfter=12, spaceBefore=6)

def section_divider():
    return HRFlowable(width='60%', thickness=1, color=HexColor('#E0D5C0'), spaceAfter=8, spaceBefore=8)

# ── Content Builders ────────────────────────────────────────────

def build_cover(story, S):
    story.append(Spacer(1, 2*inch))
    story.append(Paragraph('RHEMA STUDY BIBLE', S['cover_title']))
    story.append(Spacer(1, 8))
    story.append(Paragraph('Product Requirements Document', S['cover_sub']))
    story.append(Paragraph('Technical Architecture & Project Documentation', S['cover_sub']))
    story.append(Spacer(1, 16))
    story.append(gold_rule())
    story.append(Spacer(1, 12))
    story.append(Paragraph(f'Version 1.0  |  {datetime.date.today().strftime("%B %d, %Y")}', S['cover_date']))
    story.append(Paragraph('Prepared by: Development Team', S['cover_date']))
    story.append(Spacer(1, 1.5*inch))
    story.append(Paragraph('The Bible that listens and speaks your language.', S['cover_sub']))
    story.append(PageBreak())

def build_toc(story, S):
    story.append(Paragraph('Table of Contents', S['h1']))
    story.append(gold_rule())
    toc_items = [
        ('1.', 'Product Overview'),
        ('2.', 'Vision & Goals'),
        ('3.', 'Target Audience'),
        ('4.', 'Feature Set'),
        ('5.', 'App Wireframe & Screen Flow'),
        ('6.', 'Technical Architecture'),
        ('7.', 'Tech Stack'),
        ('8.', 'Data Architecture'),
        ('9.', 'API Integrations'),
        ('10.', 'Infrastructure & Links'),
        ('11.', 'Firebase Configuration'),
        ('12.', 'Deployment Pipeline'),
        ('13.', 'File Structure'),
        ('14.', 'Security & Privacy'),
        ('15.', 'Roadmap & Future Work'),
    ]
    for num, title in toc_items:
        story.append(Paragraph(f'<b>{num}</b>  {title}', S['body']))
    story.append(PageBreak())

def build_overview(story, S):
    story.append(Paragraph('1. Product Overview', S['h1']))
    story.append(gold_rule())
    story.append(Paragraph(
        'Rhema Study Bible is a cross-platform Bible study application built with Flutter, '
        'designed to provide a rich, immersive scripture reading experience. The app combines '
        'offline Bible reading with online translation streaming, text-to-speech narration, '
        'AI-powered study tools, interactive maps, and a kid-friendly mode -- all wrapped '
        'in a warm, elegant parchment-inspired design.',
        S['body']
    ))
    story.append(Spacer(1, 8))

    data = [
        ['App Name', 'Rhema Study Bible'],
        ['Tagline', 'The Bible that listens and speaks your language'],
        ['Platform', 'Web (Flutter Web), iOS, Android'],
        ['Current Version', '1.0.0'],
        ['Live URL', 'https://rhemabibles.com'],
        ['Status', 'Production - Live'],
    ]
    t = Table(data, colWidths=[2*inch, 4*inch])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (0, -1), LIGHT_GOLD),
        ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
        ('FONTNAME', (1, 0), (1, -1), 'Helvetica'),
        ('FONTSIZE', (0, 0), (-1, -1), 10),
        ('TEXTCOLOR', (0, 0), (-1, -1), BROWN_DARK),
        ('GRID', (0, 0), (-1, -1), 0.5, HexColor('#D4C5A9')),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('PADDING', (0, 0), (-1, -1), 8),
    ]))
    story.append(t)
    story.append(PageBreak())

def build_vision(story, S):
    story.append(Paragraph('2. Vision & Goals', S['h1']))
    story.append(gold_rule())
    story.append(Paragraph('<b>Mission:</b> Make the Bible accessible, engaging, and deeply personal '
        'for every reader regardless of language, literacy level, or age.', S['body']))
    story.append(Spacer(1, 8))
    story.append(Paragraph('Core Goals', S['h2']))
    goals = [
        '<b>Multilingual Access</b> -- 14+ translations across 10+ languages with offline/online flexibility',
        '<b>Audio Bible</b> -- Premium text-to-speech with natural, human-like narrator voices',
        '<b>Deep Study</b> -- AI quizzes, similar verse discovery, interactive maps with 56+ locations',
        '<b>Family-Friendly</b> -- Dedicated Kids Mode with 20 animated Bible stories',
        '<b>Always Available</b> -- KJV and WEB bundled offline; no internet required for core reading',
        '<b>Beautiful Design</b> -- Warm parchment theme with gold accents, dark mode support',
    ]
    for g in goals:
        story.append(Paragraph(g, S['bullet'], bulletText='\u2022'))

def build_audience(story, S):
    story.append(Spacer(1, 16))
    story.append(Paragraph('3. Target Audience', S['h1']))
    story.append(gold_rule())
    segments = [
        ('Daily Devotional Readers', 'Adults who read the Bible daily for spiritual growth. Value reading streaks, verse of the day, and bookmarks.'),
        ('Bible Students & Scholars', 'Users who want deep study tools -- AI quizzes, similar verse discovery, cross-references, study notes, and interactive maps.'),
        ('Multilingual Believers', 'Non-English speakers or bilingual readers who need Hindi, Arabic, Bengali, Amharic, and other translations.'),
        ('Parents & Children', 'Families wanting age-appropriate Bible content. Kids Mode provides animated stories with narration.'),
        ('Listeners & Commuters', 'People who prefer audio Bible. Premium TTS voices with adjustable speed and verse-by-verse tracking.'),
    ]
    for title, desc in segments:
        story.append(Paragraph(title, S['h3']))
        story.append(Paragraph(desc, S['body']))

def build_features(story, S):
    story.append(PageBreak())
    story.append(Paragraph('4. Feature Set', S['h1']))
    story.append(gold_rule())

    categories = [
        ('Reading & Navigation', [
            '66 books, full chapter navigation with swipe gestures',
            'Pinch-to-zoom font scaling (14-28px)',
            'Drop cap first letters, verse numbers, gold accents',
            'Book picker with categorized Old/New Testament sections',
            'Chapter grid picker with current chapter highlighting',
            'Reading location persistence across sessions',
        ]),
        ('Translations (14+)', [
            'KJV (offline, bundled) -- King James Version',
            'WEB (offline, bundled) -- World English Bible',
            'BSB (online) -- Berean Standard Bible',
            'ENGWEBP (online) -- English WEB Protestant',
            'Hindi IRV, Arabic NAV, Arabic VDV (online)',
            'Bengali IRV, Amharic, Tibetan, Belarusian, Assamese (online)',
            'Hebrew Masoretic, Ancient Greek, Azerbaijani (online)',
            'Language-grouped translation picker with offline/cloud indicators',
        ]),
        ('Text-to-Speech / Listen Mode', [
            'Premium voice detection (Neural, Siri, WaveNet)',
            'Voice quality badges: Premium (gold), Enhanced (brown), Standard',
            'Recommended "Most Natural" voices section',
            'Adjustable speed: 0.5x to 2.0x',
            'Verse-by-verse playback with progress tracking',
            'Natural text processing: em-dash pauses, ALL-CAPS normalization',
            'Inter-verse pauses (400ms sentences, 200ms clauses)',
        ]),
        ('Study Tools', [
            'AI-powered chapter quizzes (online: Gemini, offline: keyword)',
            'Similar verse discovery with AI semantic matching',
            'Study notes on any verse (locally stored)',
            'Reading plans: 7-day, 30-day, custom',
            'Reading streaks with daily tracking',
            'Bookmarks and highlights (5 colors)',
        ]),
        ('Interactive Bible Maps', [
            '56+ biblical locations with historical descriptions',
            'Era filters: Patriarchs, Exodus, Conquest, Kingdom, Exile, Prophets, Jesus, Early Church, Revelation',
            '8 biblical journeys with animated playback',
            'Journey routes: Abraham, Exodus, David, Jesus Galilean, Paul 1st/2nd/3rd, Seven Churches',
            'Satellite/standard map toggle',
            'Place info bottom sheets with related scripture references',
        ]),
        ('Kids Mode', [
            '20 animated Bible stories with emoji illustrations',
            '"Read to Me" narration with friendly voice',
            'Bright Fredoka font design',
            'Moral lessons at the end of each story',
            'Page-by-page story navigation',
        ]),
        ('Help & Assistant', [
            'In-app Rhema Assistant chat (inline expandable panel)',
            'Keyword-matched responses with fuzzy fallback',
            '30+ predefined help topics',
            'Quick suggestion chips for common questions',
            'Full Help & FAQ screen with categorized expandable cards',
        ]),
        ('Authentication & Accounts', [
            'Firebase Auth (email/password)',
            'Optional sign-up with gentle nudge prompts',
            'User profiles stored in Firestore',
            'Profile screen with edit name, change password',
            'Admin role support',
            '"Continue without account" option',
        ]),
        ('Settings & Customization', [
            'Dark mode toggle',
            'Font size slider (14-28)',
            'Translation picker with language grouping',
            'Voice selection with quality detection',
            'AI mode: Online/Offline/Auto',
            'Gemini API key configuration',
            'Daily verse notifications',
            'Study reminder notifications',
        ]),
    ]

    for cat_title, items in categories:
        story.append(Paragraph(cat_title, S['h2']))
        for item in items:
            story.append(Paragraph(item, S['bullet'], bulletText='\u2022'))

def build_wireframe(story, S):
    story.append(PageBreak())
    story.append(Paragraph('5. App Wireframe & Screen Flow', S['h1']))
    story.append(gold_rule())
    story.append(Paragraph(
        'The app follows a tab-based navigation pattern with 4 main sections, '
        'plus overlay components (chat bubble, modals) and auxiliary screens.',
        S['body']
    ))
    story.append(Spacer(1, 12))

    # Main flow
    story.append(Paragraph('Screen Architecture', S['h2']))
    flow = """
    <b>Welcome/Onboarding</b>
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;Custom logo (cross + Bible + "R" monogram)
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;Translation chips (KJV, WEB, BSB, Hindi, 10+ more)
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;"Begin Your Journey" CTA
    <br/><br/>
    <b>Main Shell (4 Tabs)</b>
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;[Home] | [Read] | [Study] | [Saved]
    <br/><br/>
    <b>Tab 1: Home Dashboard</b>
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;Greeting + "Rhema Study Bible" branding (gold, 20px, w900)
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;Reading streak fire badge
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;Smart search bar (text + voice)
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;Quick action tiles (adjustable grid)
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Continue Reading | Study | Listen | All Books | Maps | Kids
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;Verse of the Day card (keyword badge + reference + "Find Similar")
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;Floating chat bubble (bottom-right, 320px expandable panel)
    <br/><br/>
    <b>Tab 2: Read</b>
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;AppBar: Book/chapter dropdown + Quiz button
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;Chapter bar: Prev | "Chapter X / Y" grid | Next | Listen chip (gold)
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;Gold decorative divider
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;Verse list: drop caps, verse numbers, pinch-to-zoom
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;Swipe left/right for chapter navigation
    <br/><br/>
    <b>Tab 3: Study</b>
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;AI Quiz | Similar Verses | Bible Maps | Reading Plans
    <br/><br/>
    <b>Tab 4: Saved</b>
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;Bookmarks list with verse text + highlight colors
    """
    story.append(Paragraph(flow, S['body']))

    story.append(Paragraph('Auxiliary Screens', S['h2']))
    aux = [
        '<b>Auth Screen</b> -- Sign In / Sign Up tabs, forgot password, "Continue without account"',
        '<b>Profile Screen</b> -- Avatar, display name, email, member since, change password, sign out',
        '<b>Settings Screen</b> -- All preferences, account, Help & FAQ link',
        '<b>Listen Screen</b> -- Audio playback with voice selector, speed controls',
        '<b>Voice Settings</b> -- Premium/Enhanced/Standard categories, preview, quality badges',
        '<b>Bible Maps Screen</b> -- Interactive map, era filters, journey playback controls',
        '<b>Help & FAQ Screen</b> -- Full-page chat + FAQ tabs (expandable from inline chat)',
        '<b>Kids Home</b> -- Colorful grid of 20 Bible story cards',
        '<b>Kids Story Screen</b> -- Page-by-page illustrated story with "Read to Me"',
    ]
    for a in aux:
        story.append(Paragraph(a, S['bullet'], bulletText='\u2022'))

    story.append(Spacer(1, 12))
    story.append(Paragraph('Overlay Components', S['h2']))
    overlays = [
        '<b>Inline Chat Panel</b> -- 320px wide, 55% height, anchored bottom-right above bubble',
        '<b>Sign-Up Nudge</b> -- Bottom sheet, appears every 3rd verse-of-day tap for unauthenticated users',
        '<b>Translation Picker</b> -- DraggableScrollableSheet grouped by language with offline badges',
        '<b>Chapter Grid Picker</b> -- Modal bottom sheet with numbered grid',
        '<b>Streak Sheet</b> -- Modal showing current streak and encouragement',
    ]
    for o in overlays:
        story.append(Paragraph(o, S['bullet'], bulletText='\u2022'))

def build_tech_stack(story, S):
    story.append(PageBreak())
    story.append(Paragraph('6. Technical Architecture', S['h1']))
    story.append(gold_rule())

    story.append(Paragraph(
        'The application follows a clean layered architecture with Riverpod for state management, '
        'a repository pattern for data access, and feature-based folder organization.',
        S['body']
    ))

    story.append(Spacer(1, 12))
    story.append(Paragraph('7. Tech Stack', S['h1']))
    story.append(gold_rule())

    data = [
        ['Layer', 'Technology', 'Details'],
        ['Framework', 'Flutter 3.41.6', 'Dart 3.11.4, stable channel'],
        ['State Mgmt', 'Riverpod 2.x', 'StateNotifier + FutureProvider patterns'],
        ['UI/Fonts', 'Google Fonts', 'Lora (body), Playfair Display (headings)'],
        ['Local Storage', 'SharedPreferences', 'Settings, bookmarks, reading progress'],
        ['Auth', 'Firebase Auth', 'Email/password, profile management'],
        ['Database', 'Cloud Firestore', 'User profiles, admin roles, future sync'],
        ['TTS', 'flutter_tts 4.x', 'Premium voice detection, multi-platform'],
        ['Speech', 'speech_to_text 7.x', 'Voice search on home screen'],
        ['Maps', 'flutter_map 8.x', 'OpenStreetMap tiles, custom markers'],
        ['AI', 'Google Generative AI', 'Gemini for quizzes & verse discovery'],
        ['HTTP', 'http 1.2.x', 'API calls to HelloAO Bible API'],
        ['Sharing', 'share_plus 10.x', 'Share verses to other apps'],
        ['Hosting', 'Vercel', 'Production deployment, CDN, custom domain'],
        ['Domain', 'rhemabibles.com', 'Custom domain via Vercel'],
        ['Source Control', 'Git / GitHub', 'github.com/Ademoba01/Bible-App'],
    ]
    t = Table(data, colWidths=[1.5*inch, 1.8*inch, 3*inch])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), GOLD),
        ('TEXTCOLOR', (0, 0), (-1, 0), WHITE),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
        ('FONTSIZE', (0, 0), (-1, -1), 9.5),
        ('TEXTCOLOR', (0, 1), (-1, -1), BROWN_DARK),
        ('GRID', (0, 0), (-1, -1), 0.5, HexColor('#D4C5A9')),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [WHITE, LIGHT_GOLD]),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('PADDING', (0, 0), (-1, -1), 7),
    ]))
    story.append(t)

def build_data_arch(story, S):
    story.append(PageBreak())
    story.append(Paragraph('8. Data Architecture', S['h1']))
    story.append(gold_rule())

    story.append(Paragraph('Local Data (SharedPreferences)', S['h2']))
    local = [
        '<b>reading_book</b> / <b>reading_chapter</b> -- Current reading position',
        '<b>settings_*</b> -- Font size, dark mode, kids mode, translation, onboarded flag',
        '<b>bookmarks</b> -- JSON-encoded list of {book, chapter, verse, color, note}',
        '<b>streak_*</b> -- Last read date, current streak count',
        '<b>gemini_api_key</b> -- Encrypted API key for AI features',
    ]
    for l in local:
        story.append(Paragraph(l, S['bullet'], bulletText='\u2022'))

    story.append(Paragraph('Cloud Data (Firestore)', S['h2']))
    story.append(Paragraph('<b>Collection: users/{uid}</b>', S['h3']))
    cloud = [
        'displayName: string',
        'email: string',
        'photoUrl: string (nullable)',
        'createdAt: timestamp',
        'role: string ("user" | "admin")',
        'preferences: map (future: synced settings)',
    ]
    for c in cloud:
        story.append(Paragraph(c, S['sub_bullet'], bulletText='-'))

    story.append(Paragraph('Bible Data', S['h2']))
    bible = [
        '<b>Local assets/</b> -- KJV and WEB as JSON files (book_name.json per book)',
        '<b>HelloAO API</b> -- All other translations fetched on-demand with in-memory caching',
        '<b>Cache key format</b> -- "$translationId|$bookName" for API-fetched content',
        '<b>Fallback</b> -- API failures gracefully fall back to WEB translation',
    ]
    for b in bible:
        story.append(Paragraph(b, S['bullet'], bulletText='\u2022'))

def build_apis(story, S):
    story.append(Spacer(1, 16))
    story.append(Paragraph('9. API Integrations', S['h1']))
    story.append(gold_rule())

    story.append(Paragraph('HelloAO Bible API', S['h2']))
    api_data = [
        ['Endpoint', 'Purpose'],
        ['GET /api/available_translations.json', 'List all available Bible translations'],
        ['GET /api/{translation}/books.json', 'List books for a translation'],
        ['GET /api/{translation}/{book}/{chapter}.json', 'Fetch chapter content (verses)'],
    ]
    t = Table(api_data, colWidths=[3.5*inch, 3*inch])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), GOLD),
        ('TEXTCOLOR', (0, 0), (-1, 0), WHITE),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTNAME', (0, 1), (-1, -1), 'Courier'),
        ('FONTSIZE', (0, 0), (-1, -1), 9),
        ('GRID', (0, 0), (-1, -1), 0.5, HexColor('#D4C5A9')),
        ('PADDING', (0, 0), (-1, -1), 6),
    ]))
    story.append(t)
    story.append(Spacer(1, 8))
    story.append(Paragraph('Base URL: <b>https://bible.helloao.org/api/</b>', S['body']))
    story.append(Paragraph('Auth: None required (public API)', S['body']))
    story.append(Paragraph('Verse format: Array of strings and formatted text objects with poetry/footnote markers', S['body']))

    story.append(Paragraph('Google Gemini AI', S['h2']))
    story.append(Paragraph('Used for AI-powered quizzes and similar verse discovery. '
        'Requires user-provided API key from ai.google.dev. Falls back to offline '
        'keyword matching when no key is configured.', S['body']))

    story.append(Paragraph('API.Bible (Planned)', S['h2']))
    story.append(Paragraph('Planned integration for Yoruba, Hausa, Chinese, Pidgin, and Fulani translations. '
        'Requires API key registration at api.bible/sign-up. Supports 2500+ Bible versions '
        'across 1600+ languages. Requires FUMS (Fair Use Management System) tracking for web apps.', S['body']))

def build_infra(story, S):
    story.append(PageBreak())
    story.append(Paragraph('10. Infrastructure & Links', S['h1']))
    story.append(gold_rule())

    story.append(Paragraph('Production URLs', S['h2']))
    links = [
        ['Service', 'URL / Identifier'],
        ['Live App', 'https://rhemabibles.com'],
        ['Vercel Dashboard', 'https://vercel.com/ademoba01-3674s-projects/web'],
        ['Firebase Console', 'https://console.firebase.google.com/project/rhema-study-bible'],
        ['Firebase Auth', 'https://console.firebase.google.com/project/rhema-study-bible/authentication'],
        ['Firestore DB', 'https://console.firebase.google.com/project/rhema-study-bible/firestore'],
        ['GitHub Repo', 'https://github.com/Ademoba01/Bible-App'],
        ['HelloAO API Docs', 'https://bible.helloao.org/docs/'],
        ['API.Bible Docs', 'https://docs.api.bible/guides/bibles'],
    ]
    t = Table(links, colWidths=[1.8*inch, 4.5*inch])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), GOLD),
        ('TEXTCOLOR', (0, 0), (-1, 0), WHITE),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTNAME', (0, 1), (0, -1), 'Helvetica-Bold'),
        ('FONTNAME', (1, 1), (1, -1), 'Courier'),
        ('FONTSIZE', (0, 0), (-1, -1), 9),
        ('TEXTCOLOR', (0, 1), (-1, -1), BROWN_DARK),
        ('GRID', (0, 0), (-1, -1), 0.5, HexColor('#D4C5A9')),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [WHITE, LIGHT_GOLD]),
        ('PADDING', (0, 0), (-1, -1), 7),
    ]))
    story.append(t)

def build_firebase(story, S):
    story.append(Spacer(1, 16))
    story.append(Paragraph('11. Firebase Configuration', S['h1']))
    story.append(gold_rule())

    story.append(Paragraph('Project Details', S['h2']))
    fb = [
        ['Parameter', 'Value'],
        ['Project ID', 'rhema-study-bible'],
        ['Project Number', '351142574491'],
        ['App ID (Web)', '1:351142574491:web:d680e02d89756051d6493e'],
        ['Auth Domain', 'rhema-study-bible.firebaseapp.com'],
        ['Storage Bucket', 'rhema-study-bible.firebasestorage.app'],
        ['Messaging Sender ID', '351142574491'],
        ['Firestore Location', 'nam5 (US multi-region)'],
        ['Auth Providers', 'Email/Password'],
    ]
    t = Table(fb, colWidths=[2*inch, 4.3*inch])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), GOLD),
        ('TEXTCOLOR', (0, 0), (-1, 0), WHITE),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTNAME', (0, 1), (0, -1), 'Helvetica-Bold'),
        ('FONTNAME', (1, 1), (1, -1), 'Courier'),
        ('FONTSIZE', (0, 0), (-1, -1), 9.5),
        ('TEXTCOLOR', (0, 1), (-1, -1), BROWN_DARK),
        ('GRID', (0, 0), (-1, -1), 0.5, HexColor('#D4C5A9')),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [WHITE, LIGHT_GOLD]),
        ('PADDING', (0, 0), (-1, -1), 7),
    ]))
    story.append(t)

    story.append(Paragraph('Firestore Security Rules', S['h2']))
    rules_text = (
        'rules_version = "2";<br/>'
        'service cloud.firestore {<br/>'
        '&nbsp;&nbsp;match /databases/{database}/documents {<br/>'
        '&nbsp;&nbsp;&nbsp;&nbsp;match /users/{userId} {<br/>'
        '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;allow read, write: if request.auth != null<br/>'
        '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&amp;&amp; request.auth.uid == userId;<br/>'
        '&nbsp;&nbsp;&nbsp;&nbsp;}<br/>'
        '&nbsp;&nbsp;&nbsp;&nbsp;match /admin/{document=**} {<br/>'
        '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;allow read, write: if request.auth != null<br/>'
        '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&amp;&amp; get(...).data.role == "admin";<br/>'
        '&nbsp;&nbsp;&nbsp;&nbsp;}<br/>'
        '&nbsp;&nbsp;}<br/>'
        '}'
    )
    story.append(Paragraph(rules_text, S['code']))

def build_deployment(story, S):
    story.append(PageBreak())
    story.append(Paragraph('12. Deployment Pipeline', S['h1']))
    story.append(gold_rule())

    story.append(Paragraph('Build & Deploy Process', S['h2']))
    steps = [
        '<b>Step 1: Build</b> -- flutter build web --no-web-resources-cdn',
        '<b>Step 2: Deploy</b> -- cd build/web && vercel --prod --yes',
        '<b>Step 3: Verify</b> -- App live at https://rhemabibles.com',
    ]
    for s_item in steps:
        story.append(Paragraph(s_item, S['bullet'], bulletText='\u2022'))

    story.append(Paragraph('Build Notes', S['h2']))
    notes = [
        'Build output: build/web/ (~110MB with assets)',
        'Deploy only build/web/ to Vercel (not project root -- 895MB exceeds 100MB limit)',
        'WASM dry-run warnings from flutter_tts (non-blocking, cosmetic only)',
        'Font tree-shaking reduces MaterialIcons from 1.6MB to ~20KB',
        'Build time: ~30 seconds on incremental, ~500 seconds on clean',
    ]
    for n in notes:
        story.append(Paragraph(n, S['bullet'], bulletText='\u2022'))

def build_file_structure(story, S):
    story.append(Spacer(1, 16))
    story.append(Paragraph('13. File Structure', S['h1']))
    story.append(gold_rule())

    structure = """
    lib/
    <br/>&nbsp;&nbsp;main.dart -- App entry, Firebase init
    <br/>&nbsp;&nbsp;theme.dart -- BrandColors, buildAdultTheme, buildKidsTheme
    <br/>&nbsp;&nbsp;data/
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;bible_api_service.dart -- HelloAO API client
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;bible_maps_data.dart -- 56+ places, 8 journeys, BiblicalEra enum
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;bible_repository.dart -- Local + API book loading, fallback
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;books.dart -- Book metadata (names, chapter counts)
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;book_descriptions.dart -- Study descriptions per book
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;models.dart -- VerseRef, Bookmark, ReadingPlan
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;translations.dart -- Translation class, 14+ entries, isLocal flag
    <br/>&nbsp;&nbsp;features/
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;auth/ -- auth_screen.dart, profile_screen.dart
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;kids/ -- kids_home_screen.dart, kids_story_screen.dart
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;listen/ -- listen_screen.dart
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;onboarding/ -- welcome_screen.dart
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;reading/screens/ -- home_screen.dart, reading_screen.dart, books_screen.dart
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;search/ -- similar_verses_screen.dart
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;settings/ -- settings_screen.dart, voice_settings.dart, help_screen.dart
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;study/ -- study_screen.dart, bible_maps_screen.dart, chapter_quiz_screen.dart
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;bookmarks/ -- bookmarks_screen.dart
    <br/>&nbsp;&nbsp;services/
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;ai_service.dart -- Gemini + offline quiz/verse engine
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;auth_service.dart -- AuthNotifier, UserProfile, Firebase Auth
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;notification_service.dart -- Local notifications
    <br/>&nbsp;&nbsp;state/
    <br/>&nbsp;&nbsp;&nbsp;&nbsp;providers.dart -- All Riverpod providers
    <br/>&nbsp;&nbsp;utils/ -- page_transitions.dart, kids_portal_transition.dart
    <br/>&nbsp;&nbsp;widgets/ -- shimmer_placeholder.dart
    """
    story.append(Paragraph(structure, S['body']))

def build_security(story, S):
    story.append(PageBreak())
    story.append(Paragraph('14. Security & Privacy', S['h1']))
    story.append(gold_rule())
    items = [
        '<b>No data collection</b> -- All reading data stored locally on device',
        '<b>Firebase Auth</b> -- Industry-standard authentication, passwords hashed by Google',
        '<b>Firestore rules</b> -- Users can only read/write their own documents',
        '<b>Admin isolation</b> -- Admin collection requires role == "admin" verification',
        '<b>API keys</b> -- Gemini key stored locally, never transmitted except to Google',
        '<b>No tracking</b> -- No analytics, no ads, no third-party trackers',
        '<b>HTTPS only</b> -- All API calls and hosting over TLS',
        '<b>Optional auth</b> -- App fully functional without creating an account',
    ]
    for i in items:
        story.append(Paragraph(i, S['bullet'], bulletText='\u2022'))

def build_roadmap(story, S):
    story.append(Spacer(1, 16))
    story.append(Paragraph('15. Roadmap & Future Work', S['h1']))
    story.append(gold_rule())

    phases = [
        ('Phase 2: More Languages', [
            'Integrate API.Bible for Yoruba, Hausa, Chinese, Pidgin, Fulani',
            'Register at api.bible/sign-up, get API key',
            'Implement FUMS tracking for web compliance',
            'Add language auto-detection based on device locale',
        ]),
        ('Phase 3: Cloud Sync', [
            'Sync bookmarks, highlights, and notes to Firestore',
            'Cross-device reading progress synchronization',
            'Offline queue with conflict resolution',
        ]),
        ('Phase 4: Social Features', [
            'Share devotionals and reading plans with friends',
            'Community reading groups',
            'Prayer request board',
        ]),
        ('Phase 5: Native Apps', [
            'iOS App Store submission',
            'Google Play Store submission',
            'Push notifications for daily verses and streaks',
        ]),
        ('Phase 6: Admin Dashboard', [
            'Web-based admin panel (beyond Firebase Console)',
            'User analytics and engagement metrics',
            'Content management for daily verses',
            'Translation quality review tools',
        ]),
    ]
    for title, items in phases:
        story.append(Paragraph(title, S['h2']))
        for item in items:
            story.append(Paragraph(item, S['bullet'], bulletText='\u2022'))

    story.append(Spacer(1, 24))
    story.append(gold_rule())
    story.append(Spacer(1, 12))
    story.append(Paragraph(
        '<i>This document is a living artifact and will be updated as the product evolves.</i>',
        S['body']
    ))
    story.append(Spacer(1, 8))
    story.append(Paragraph(
        f'Generated: {datetime.datetime.now().strftime("%B %d, %Y at %I:%M %p")}',
        S['footer']
    ))

# ── Main ────────────────────────────────────────────────────────

def main():
    output_path = '/Users/ademoba/Desktop/Rhema_Study_Bible_PRD.pdf'
    doc = SimpleDocTemplate(
        output_path,
        pagesize=letter,
        topMargin=0.75*inch,
        bottomMargin=0.75*inch,
        leftMargin=0.75*inch,
        rightMargin=0.75*inch,
        title='Rhema Study Bible - PRD',
        author='Development Team',
    )

    S = make_styles()
    story = []

    build_cover(story, S)
    build_toc(story, S)
    build_overview(story, S)
    build_vision(story, S)
    build_audience(story, S)
    build_features(story, S)
    build_wireframe(story, S)
    build_tech_stack(story, S)
    build_data_arch(story, S)
    build_apis(story, S)
    build_infra(story, S)
    build_firebase(story, S)
    build_deployment(story, S)
    build_file_structure(story, S)
    build_security(story, S)
    build_roadmap(story, S)

    doc.build(story)
    print(f'PDF generated: {output_path}')

if __name__ == '__main__':
    main()
