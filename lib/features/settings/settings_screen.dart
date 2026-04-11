import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/translations.dart';
import '../../services/ai_service.dart';
import '../../services/notification_service.dart';
import '../../state/providers.dart';
import '../../theme.dart';
import '../subscription/paywall_screen.dart';

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
    final isPro = ref.watch(isProProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // ── Rhema Pro section ──────────────────────────
          if (isPro)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    BrandColors.gold.withValues(alpha: 0.15),
                    BrandColors.gold.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(color: BrandColors.gold.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.workspace_premium, color: BrandColors.gold, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rhema Pro',
                            style: GoogleFonts.lora(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: BrandColors.gold)),
                        Text('All premium features unlocked',
                            style: GoogleFonts.lora(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Icon(Icons.check_circle, color: BrandColors.gold, size: 24),
                ],
              ),
            )
          else
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [BrandColors.gold, Color(0xFFE6BE5A)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: BrandColors.gold.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PaywallScreen()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.workspace_premium,
                            color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Upgrade to Pro',
                                  style: GoogleFonts.lora(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                              Text('Unlock all premium features',
                                  style: GoogleFonts.lora(
                                      fontSize: 12,
                                      color: Colors.white70)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: Colors.white, size: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
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
              final picked = await showModalBottomSheet<String>(
                context: context,
                builder: (_) => SafeArea(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final t in kTranslations)
                        ListTile(
                          enabled: t.available,
                          leading: Icon(
                            t.id == s.translation ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: t.available ? theme.colorScheme.primary : Colors.grey,
                          ),
                          title: Text(t.name + (t.available ? '' : '  (coming soon)')),
                          subtitle: Text(t.description),
                          onTap: t.available ? () => Navigator.pop(context, t.id) : null,
                        ),
                    ],
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
          const ListTile(
            title: Text('About'),
            subtitle: Text('Rhema Study Bible — The Bible that listens and speaks your language.'),
          ),
        ],
      ),
    );
  }
}
