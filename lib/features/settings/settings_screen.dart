import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/translations.dart';
import '../../services/ai_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../state/providers.dart';
import '../../theme.dart';
import '../auth/auth_screen.dart';
import '../auth/profile_screen.dart';
import '../study/my_lexicon_screen.dart';
import '../study/sermon_collections_screen.dart';
import 'help_screen.dart';
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _dailyVerseEnabled = false;
  bool _studyReminderEnabled = false;
  bool _apiKeyVisible = false;
  bool _testingConnection = false;
  String? _connectionResult;
  late TextEditingController _apiKeyController;

  @override
  void initState() {
    super.initState();
    _loadNotificationPrefs();
    _apiKeyController = TextEditingController(
      text: ref.read(settingsProvider).geminiApiKey,
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadNotificationPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _dailyVerseEnabled = prefs.getBool('notif_daily_verse') ?? false;
        _studyReminderEnabled = prefs.getBool('notif_study_reminder') ?? false;
      });
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _testingConnection = true;
      _connectionResult = null;
    });
    final ok = await AiService.testConnection();
    if (!mounted) return;
    setState(() {
      _testingConnection = false;
      _connectionResult = ok ? 'Connected successfully!' : 'Connection failed. Check your API key.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 4),
          SwitchListTile(
            secondary: Icon(Icons.child_care, color: Colors.pink),
            title: Text('Kids Mode', style: GoogleFonts.lora(fontWeight: FontWeight.w600)),
            subtitle: Text('Fun, colorful interface for young readers',
                style: GoogleFonts.lora(fontSize: 12)),
            value: s.kidsMode,
            onChanged: (v) => n.setKidsMode(v),
          ),
          SwitchListTile(
            title: const Text('Dark mode'),
            value: s.darkMode,
            onChanged: n.setDarkMode,
          ),
          // ── Theme style picker ─────────────────────────────────
          // Two side-by-side cards. Tap to switch between the classic
          // parchment/gold devotional aesthetic and the modern clean
          // sans/blue alternative. Persists via setThemeStyle.
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
            child: Text(
              'Theme style',
              style: GoogleFonts.lora(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: _ThemeStyleCard(
                    label: 'Classic',
                    blurb: 'Parchment & gold',
                    selected: s.themeStyle == ThemeStyle.classic,
                    backgroundColor: BrandColors.parchment,
                    foregroundColor: BrandColors.dark,
                    ringColor: BrandColors.goldDeep,
                    previewText: 'In the beginning',
                    previewStyle: GoogleFonts.cormorantGaramond(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: BrandColors.dark,
                      fontStyle: FontStyle.italic,
                    ),
                    onTap: () => n.setThemeStyle(ThemeStyle.classic),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ThemeStyleCard(
                    label: 'Modern',
                    blurb: 'Clean & dark',
                    selected: s.themeStyle == ThemeStyle.modern,
                    backgroundColor: BrandColors.modernScaffoldDark,
                    foregroundColor: Colors.white,
                    ringColor: BrandColors.modernBlue,
                    previewText: 'In the beginning',
                    previewStyle: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                    onTap: () => n.setThemeStyle(ThemeStyle.modern),
                  ),
                ),
              ],
            ),
          ),
          SwitchListTile(
            secondary: Icon(Icons.translate, color: BrandColors.gold),
            // Renamed from "Scholar Mode (Strong's)" — user-research showed
            // "Strong's" is jargon that gates discovery to seminary-trained
            // users only. The new label leads with the noun every reader
            // recognises (Greek/Hebrew) and uses "word study" instead of
            // "scholar" to broaden appeal.
            title: Text('Greek & Hebrew (word study)',
                style: GoogleFonts.lora(fontWeight: FontWeight.w600)),
            subtitle: Text(
                'Tap any English word in a verse to see the original Hebrew or Greek and its lexicon entry',
                style: GoogleFonts.lora(fontSize: 12)),
            value: s.scholarMode,
            onChanged: (v) => n.setScholarMode(v),
          ),
          ListTile(
            leading: Icon(Icons.menu_book_rounded, color: BrandColors.gold),
            title: Text('My Lexicon',
                style: GoogleFonts.lora(fontWeight: FontWeight.w600)),
            subtitle: Text(
                'Wall of every word you’ve explored, with your word streak',
                style: GoogleFonts.lora(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const MyLexiconScreen(),
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.note_alt_outlined, color: BrandColors.gold),
            title: Text('Sermon Notes',
                style: GoogleFonts.lora(fontWeight: FontWeight.w600)),
            subtitle: Text(
                'Collect Strong’s insights into named sermon series',
                style: GoogleFonts.lora(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SermonCollectionsScreen(),
              ),
            ),
          ),
          ListTile(
            title: const Text('Font size'),
            subtitle: Slider(
              min: 14,
              max: 28,
              divisions: 14,
              value: s.fontSize,
              label: s.fontSize.toStringAsFixed(0),
              onChanged: n.setFontSize,
            ),
          ),
          ListTile(
            title: const Text('Translation'),
            subtitle: Text(translationById(s.translation).name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final grouped = translationsByLanguage();
              final langOrder = grouped.keys.toList();
              langOrder.remove('English');
              langOrder.insert(0, 'English');
              final picked = await showDialog<String>(
                context: context,
                barrierColor: Colors.black54,
                builder: (ctx) => Center(
                  child: Container(
                    width: 400,
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.65,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFD4A843).withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Text('Switch Translation',
                              style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              children: [
                                for (final lang in langOrder) ...[
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                                    child: Text(lang,
                                        style: GoogleFonts.lora(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: theme.colorScheme.primary,
                                        )),
                                  ),
                                  ...grouped[lang]!.map((t) => ListTile(
                                        enabled: t.available,
                                        leading: Icon(
                                          t.id == s.translation
                                              ? Icons.radio_button_checked
                                              : Icons.radio_button_off,
                                          color: t.available
                                              ? theme.colorScheme.primary
                                              : Colors.grey,
                                        ),
                                        title: Row(
                                          children: [
                                            Text(t.name +
                                                (t.available ? '' : '  (coming soon)')),
                                            if (t.isLocal) ...[
                                              const SizedBox(width: 6),
                                              Icon(Icons.offline_pin,
                                                  size: 14,
                                                  color: theme.colorScheme.outline),
                                            ],
                                            if (!t.isLocal && t.available) ...[
                                              const SizedBox(width: 6),
                                              Icon(Icons.cloud_outlined,
                                                  size: 14,
                                                  color: theme.colorScheme.outline),
                                            ],
                                          ],
                                        ),
                                        subtitle: Text(t.description),
                                        onTap: t.available
                                            ? () => Navigator.pop(ctx, t.id)
                                            : null,
                                      )),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
              if (picked != null) n.setTranslation(picked);
            },
          ),

          // ── AI Features section ──────────────────────────
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
            child: Text('AI Features',
                style: GoogleFonts.lora(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Online mode uses Google Gemini for smarter quizzes and verse discovery. '
              'Offline mode uses built-in keyword matching \u2014 no internet needed.',
              style: GoogleFonts.lora(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.auto_awesome, color: BrandColors.gold),
            title: Text('AI Mode',
                style: GoogleFonts.lora(fontWeight: FontWeight.w600)),
            subtitle: Text(
              s.aiMode == AiMode.online
                  ? 'Always use online AI'
                  : s.aiMode == AiMode.offline
                      ? 'Always use offline mode'
                      : 'Auto (online when available)',
              style: GoogleFonts.lora(fontSize: 12),
            ),
            trailing: DropdownButton<AiMode>(
              value: s.aiMode,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: AiMode.auto, child: Text('Auto')),
                DropdownMenuItem(value: AiMode.online, child: Text('Online')),
                DropdownMenuItem(value: AiMode.offline, child: Text('Offline')),
              ],
              onChanged: (v) {
                if (v != null) n.setAiMode(v);
              },
            ),
          ),
          // Advanced AI settings — hidden behind expander
          ExpansionTile(
            leading: Icon(Icons.tune, size: 20, color: theme.colorScheme.onSurfaceVariant),
            title: Text('Advanced',
                style: GoogleFonts.lora(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
            subtitle: Text(
              s.geminiApiKey.isNotEmpty ? 'API key configured' : 'Set up API key',
              style: GoogleFonts.lora(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _apiKeyController,
                  obscureText: !_apiKeyVisible,
                  style: GoogleFonts.lora(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Gemini API Key',
                    labelStyle: GoogleFonts.lora(),
                    hintText: 'Paste your API key here',
                    hintStyle: GoogleFonts.lora(fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            _apiKeyVisible ? Icons.visibility_off : Icons.visibility,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _apiKeyVisible = !_apiKeyVisible),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check, size: 20),
                          onPressed: () {
                            n.setGeminiApiKey(_apiKeyController.text.trim());
                            FocusScope.of(context).unfocus();
                            setState(() => _connectionResult = null);
                          },
                        ),
                      ],
                    ),
                  ),
                  onSubmitted: (v) {
                    n.setGeminiApiKey(v.trim());
                    setState(() => _connectionResult = null);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: BrandColors.brown,
                        side: BorderSide(color: BrandColors.brown.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: _testingConnection
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: BrandColors.brown,
                              ),
                            )
                          : const Icon(Icons.wifi_tethering, size: 18),
                      label: Text(
                        'Test connection',
                        style: GoogleFonts.lora(fontSize: 13),
                      ),
                      onPressed: _testingConnection || s.geminiApiKey.isEmpty
                          ? null
                          : _testConnection,
                    ),
                    const SizedBox(width: 12),
                    if (_connectionResult != null)
                      Expanded(
                        child: Text(
                          _connectionResult!,
                          style: GoogleFonts.lora(
                            fontSize: 12,
                            color: _connectionResult!.contains('successfully')
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  'Get a free API key at ai.google.dev',
                  style: GoogleFonts.lora(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),

          // ── Notifications section ──────────────────────────
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
            child: Text('Notifications',
                style: GoogleFonts.lora(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant)),
          ),
          ListTile(
            leading: Icon(Icons.notifications_outlined, color: theme.colorScheme.primary),
            title: Text('Daily Verse Reminder',
                style: GoogleFonts.lora(fontWeight: FontWeight.w600)),
            subtitle: Text('Get your verse of the day each morning',
                style: GoogleFonts.lora(fontSize: 12)),
            trailing: Switch(
              value: _dailyVerseEnabled,
              onChanged: (v) async {
                setState(() => _dailyVerseEnabled = v);
                if (v) {
                  await NotificationService.requestPermissions();
                  await NotificationService.scheduleDailyVerse();
                } else {
                  await NotificationService.cancel(0);
                }
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('notif_daily_verse', v);
              },
            ),
          ),
          ListTile(
            leading: Icon(Icons.school_outlined, color: theme.colorScheme.primary),
            title: Text('Study Plan Reminder',
                style: GoogleFonts.lora(fontWeight: FontWeight.w600)),
            subtitle: Text('Don\'t break your reading streak',
                style: GoogleFonts.lora(fontSize: 12)),
            trailing: Switch(
              value: _studyReminderEnabled,
              onChanged: (v) async {
                setState(() => _studyReminderEnabled = v);
                if (v) {
                  await NotificationService.requestPermissions();
                  await NotificationService.scheduleStudyReminder();
                } else {
                  await NotificationService.cancel(1);
                }
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('notif_study_reminder', v);
              },
            ),
          ),

          const Divider(),

          // ── Account ──
          Consumer(builder: (context, ref, _) {
            final auth = ref.watch(authProvider);
            if (auth.isAuthenticated) {
              return ListTile(
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: BrandColors.gold,
                  child: Text(
                    (auth.profile?.displayName ?? auth.user?.displayName ?? '?')[0].toUpperCase(),
                    style: GoogleFonts.playfairDisplay(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF3E2723),
                    ),
                  ),
                ),
                title: Text(auth.profile?.displayName ?? auth.user?.displayName ?? 'User',
                    style: GoogleFonts.lora(fontWeight: FontWeight.w600)),
                subtitle: Text(auth.user?.email ?? '',
                    style: GoogleFonts.lora(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
              );
            }
            return ListTile(
              leading: Icon(Icons.person_outline, color: theme.colorScheme.primary),
              title: Text('Sign In / Sign Up',
                  style: GoogleFonts.lora(fontWeight: FontWeight.w600)),
              subtitle: Text('Save your progress and sync across devices',
                  style: GoogleFonts.lora(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              ),
            );
          }),

          const Divider(),

          // ── Developer / API section ──────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
            child: Text('Developer',
                style: GoogleFonts.lora(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant)),
          ),
          ListTile(
            leading: Icon(Icons.api, color: BrandColors.gold),
            title: Text('API Documentation',
                style: GoogleFonts.lora(fontWeight: FontWeight.w600)),
            subtitle: Text(
              'Integrate daily verse, search & more into your website or app',
              style: GoogleFonts.lora(fontSize: 12),
            ),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => launchUrl(
              Uri.parse('https://rhemabibles.com/api-docs.html'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          ListTile(
            leading: Icon(Icons.code, color: theme.colorScheme.primary),
            title: Text('API Base URL',
                style: GoogleFonts.lora(fontWeight: FontWeight.w600)),
            subtitle: SelectableText(
              'https://rhemabibles.com/api',
              style: GoogleFonts.sourceCodePro(fontSize: 13),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.copy, size: 18),
              tooltip: 'Copy API URL',
              onPressed: () {
                Clipboard.setData(
                    const ClipboardData(text: 'https://rhemabibles.com/api'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('API URL copied'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Free, no API key required. Endpoints: /api/daily-verse, '
              '/api/random-verse, /api/verse, /api/search, /api/topics, /api/books',
              style: GoogleFonts.lora(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          const Divider(),
          ListTile(
            leading: Icon(Icons.help_outline, color: theme.colorScheme.primary),
            title: Text('Help & FAQ',
                style: GoogleFonts.lora(fontWeight: FontWeight.w600)),
            subtitle: Text('Learn how to use the app, ask questions',
                style: GoogleFonts.lora(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpScreen()),
            ),
          ),
          const ListTile(
            title: Text('About'),
            subtitle: Text('Rhema Study Bible — The Bible that listens and speaks your language.'),
          ),
        ],
      ),
    );
  }
}

/// Visual swatch card for picking a theme style. Shows the theme's bg
/// colour, a font preview in that theme's display face, and a coloured
/// ring when selected (gold for classic, blue for modern).
class _ThemeStyleCard extends StatelessWidget {
  const _ThemeStyleCard({
    required this.label,
    required this.blurb,
    required this.selected,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.ringColor,
    required this.previewText,
    required this.previewStyle,
    required this.onTap,
  });

  final String label;
  final String blurb;
  final bool selected;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color ringColor;
  final String previewText;
  final TextStyle previewStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? ringColor
                  : Colors.black.withValues(alpha: 0.08),
              width: selected ? 2.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: ringColor.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.lora(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: foregroundColor,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle, size: 18, color: ringColor),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                previewText,
                style: previewStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                blurb,
                style: GoogleFonts.lora(
                  fontSize: 11,
                  color: foregroundColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
