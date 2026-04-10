import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/translations.dart';
import '../../state/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
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
