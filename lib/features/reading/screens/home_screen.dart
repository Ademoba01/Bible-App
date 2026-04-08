import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../state/providers.dart';
import '../../../theme.dart';
import '../../bookmarks/bookmarks_screen.dart';
import '../../listen/listen_screen.dart';
import '../../search/search_screen.dart';
import '../../settings/settings_screen.dart';
import 'reading_screen.dart';

/// Adult-mode shell: bottom nav + "Home" tab with a warm greeting card.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(tabIndexProvider);
    final tabs = const <Widget>[
      _DashboardTab(),
      ReadingScreen(),
      ListenScreen(),
      BookmarksScreen(),
      SettingsScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => ref.read(tabIndexProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Read'),
          NavigationDestination(icon: Icon(Icons.headphones_outlined), selectedIcon: Icon(Icons.headphones), label: 'Listen'),
          NavigationDestination(icon: Icon(Icons.bookmark_outline), selectedIcon: Icon(Icons.bookmark), label: 'Saved'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class _DashboardTab extends ConsumerWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(readingLocationProvider);
    final bookmarks = ref.watch(bookmarksProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero greeting card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [BrandColors.brown, BrandColors.brownMid],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(),
                          style: GoogleFonts.lora(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Welcome back',
                          style: GoogleFonts.lora(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Continue: ${loc.book} ${loc.chapter}',
                          style: GoogleFonts.lora(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: BrandColors.gold,
                            foregroundColor: BrandColors.dark,
                          ),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Keep reading'),
                          onPressed: () => ref.read(tabIndexProvider.notifier).state = 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Image.asset('assets/brand/hero.png', width: 90, height: 90),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick actions
            Row(
              children: [
                _QuickTile(
                  icon: Icons.headphones,
                  label: 'Listen',
                  color: Colors.teal,
                  onTap: () => ref.read(tabIndexProvider.notifier).state = 2,
                ),
                const SizedBox(width: 12),
                _QuickTile(
                  icon: Icons.search,
                  label: 'Search',
                  color: Colors.indigo,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                _QuickTile(
                  icon: Icons.child_care,
                  label: 'Kids',
                  color: Colors.pink,
                  onTap: () => ref.read(settingsProvider.notifier).setKidsMode(true),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              'Recent bookmarks',
              style: GoogleFonts.lora(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            if (bookmarks.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.bookmark_border, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tap any verse while reading to save it here.',
                          style: GoogleFonts.lora(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...bookmarks.take(5).map(
                    (id) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(Icons.bookmark, color: theme.colorScheme.primary),
                        title: Text(id, style: GoogleFonts.lora(fontWeight: FontWeight.w600)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => ref.read(tabIndexProvider.notifier).state = 3,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: GoogleFonts.lora(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
