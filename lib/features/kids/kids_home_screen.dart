import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../state/providers.dart';
import 'kids_stories.dart';
import 'kids_story_screen.dart';

class KidsHomeScreen extends ConsumerWidget {
  const KidsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bible Stories', style: GoogleFonts.fredoka(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            tooltip: 'Switch to grown-up mode',
            icon: const Icon(Icons.person_outline),
            onPressed: () => ref.read(settingsProvider.notifier).setKidsMode(false),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pick a story!',
                style: GoogleFonts.fredoka(fontSize: 26, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap any picture — I\'ll read it to you.',
                style: GoogleFonts.fredoka(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  itemCount: kKidsStories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (_, i) => _StoryCard(story: kKidsStories[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.story});
  final KidsStory story;

  @override
  Widget build(BuildContext context) {
    final color = Color(story.color);
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(22),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => KidsStoryScreen(story: story)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(story.emoji, style: const TextStyle(fontSize: 52)),
              const Spacer(),
              Text(
                story.title,
                style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                story.blurb,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.fredoka(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
