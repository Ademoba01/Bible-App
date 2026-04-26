import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../state/providers.dart';

class StartHereScreen extends ConsumerWidget {
  const StartHereScreen({super.key});

  // Curated reading paths for different needs
  static const _paths = [
    _GuidedPath(
      emoji: '\u{1F331}',
      title: 'Brand New to the Bible',
      subtitle: 'Start with the basics \u2014 who is God, who is Jesus, what is grace',
      readings: [
        _Reading('John', 1, 'Meet Jesus \u2014 the Word made flesh'),
        _Reading('Genesis', 1, 'How it all began \u2014 Creation'),
        _Reading('Psalms', 23, 'God as your shepherd \u2014 comfort and peace'),
        _Reading('Luke', 15, 'The lost son \u2014 God\'s unconditional love'),
        _Reading('Romans', 8, 'Nothing can separate you from God\'s love'),
        _Reading('Matthew', 5, 'Jesus\' most famous sermon \u2014 the Beatitudes'),
        _Reading('Ephesians', 2, 'Saved by grace \u2014 the heart of the Gospel'),
      ],
    ),
    _GuidedPath(
      emoji: '\u{1F4AA}',
      title: 'Going Through a Hard Time',
      subtitle: 'Verses for when life feels heavy',
      readings: [
        _Reading('Psalms', 46, 'God is our refuge and strength'),
        _Reading('Isaiah', 41, 'Do not fear \u2014 I am with you'),
        _Reading('Matthew', 11, 'Come to me, all who are weary'),
        _Reading('Romans', 8, 'Nothing can separate us from God\'s love'),
        _Reading('Philippians', 4, 'I can do all things through Christ'),
        _Reading('Psalms', 91, 'Dwelling in God\'s shelter'),
      ],
    ),
    _GuidedPath(
      emoji: '\u{1F64F}',
      title: 'Learning to Pray',
      subtitle: 'How Jesus taught us to talk to God',
      readings: [
        _Reading('Matthew', 6, 'The Lord\'s Prayer \u2014 Jesus shows how to pray'),
        _Reading('Psalms', 51, 'David\'s prayer of repentance'),
        _Reading('Luke', 18, 'The persistent widow \u2014 never stop praying'),
        _Reading('Philippians', 4, 'Present your requests to God'),
        _Reading('James', 5, 'The prayer of faith'),
      ],
    ),
    _GuidedPath(
      emoji: '\u{2764}\u{FE0F}',
      title: 'Understanding God\'s Love',
      subtitle: 'The most beautiful love story ever told',
      readings: [
        _Reading('John', 3, 'For God so loved the world'),
        _Reading('1 Corinthians', 13, 'Love is patient, love is kind'),
        _Reading('Romans', 5, 'God proves His love for us'),
        _Reading('1 John', 4, 'God is love'),
        _Reading('Hosea', 11, 'God\'s tender love for His people'),
        _Reading('Song of Solomon', 2, 'The beauty of divine love'),
      ],
    ),
    _GuidedPath(
      emoji: '\u{26A1}',
      title: 'The Greatest Stories',
      subtitle: 'Epic moments that shaped history',
      readings: [
        _Reading('Genesis', 1, 'Creation \u2014 in the beginning'),
        _Reading('Genesis', 6, 'Noah and the flood'),
        _Reading('Exodus', 14, 'Moses parts the Red Sea'),
        _Reading('1 Samuel', 17, 'David vs Goliath'),
        _Reading('Daniel', 6, 'Daniel in the lion\'s den'),
        _Reading('Jonah', 1, 'Jonah and the great fish'),
        _Reading('Matthew', 28, 'The resurrection of Jesus'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Start Here',
            style: GoogleFonts.lora(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: EdgeInsets.all(
            MediaQuery.of(context).size.width < 400 ? 14 : 20),
        children: [
          // Welcome header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                ],
              ),
            ),
            child: Column(
              children: [
                const Text('\u{1F44B}',
                    style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  'Welcome to the Bible',
                  style: GoogleFonts.lora(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Not sure where to start? Pick a path below.\nEach one is a short guided journey through Scripture.',
                  style: GoogleFonts.lora(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Guided paths
          ...List.generate(_paths.length, (i) {
            final path = _paths[i];
            return _PathCard(path: path, ref: ref);
          }),
        ],
      ),
    );
  }
}

class _Reading {
  final String book;
  final int chapter;
  final String description;
  const _Reading(this.book, this.chapter, this.description);
}

class _GuidedPath {
  final String emoji;
  final String title;
  final String subtitle;
  final List<_Reading> readings;
  const _GuidedPath({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.readings,
  });
}

class _PathCard extends StatelessWidget {
  const _PathCard({required this.path, required this.ref});
  final _GuidedPath path;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding:
            const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        leading: Text(path.emoji, style: const TextStyle(fontSize: 28)),
        title: Text(
          path.title,
          style: GoogleFonts.lora(
              fontSize: 16, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          path.subtitle,
          style: GoogleFonts.lora(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4),
        ),
        children: path.readings.map((r) {
          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              ref
                  .read(readingLocationProvider.notifier)
                  .setBook(r.book);
              ref
                  .read(readingLocationProvider.notifier)
                  .setChapter(r.chapter);
              ref.read(tabIndexProvider.notifier).set(1);
              Navigator.of(context).pop(); // close StartHereScreen
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.menu_book_outlined,
                        size: 18, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${r.book} ${r.chapter}',
                          style: GoogleFonts.lora(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          r.description,
                          style: GoogleFonts.lora(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.play_circle_outline,
                      size: 22,
                      color: theme.colorScheme.primary.withValues(alpha: 0.7)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
