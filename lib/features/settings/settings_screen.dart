import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/translations.dart';
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

  @override
  void initState() {
    super.initState();
    _loadNotificationPrefs();
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
          // ── Our Bible Pro section ──────────────────────────
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
                        Text('Our Bible Pro',
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
            subtitle: Text('Our Bible — The Bible that listens and speaks your language.'),
          ),
        ],
      ),
    );
  }
}
