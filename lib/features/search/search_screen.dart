import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../state/providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  List<({VerseRef ref, String text})> _results = const [];

  Future<void> _run() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    setState(() => _loading = true);
    final repo = ref.read(bibleRepositoryProvider);
    final tid = ref.read(settingsProvider).translation;
    final res = await repo.search(q, translationId: tid);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _results = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _run(),
              decoration: InputDecoration(
                hintText: 'Search the whole Bible...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _run),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: _results.isEmpty
                ? const Center(child: Text('Type a word or phrase and press search.'))
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final r = _results[i];
                      return ListTile(
                        title: Text(r.ref.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(r.text, maxLines: 3, overflow: TextOverflow.ellipsis),
                        onTap: () {
                          ref.read(readingLocationProvider.notifier).setBook(r.ref.book);
                          ref.read(readingLocationProvider.notifier).setChapter(r.ref.chapter);
                          ref.read(tabIndexProvider.notifier).state = 0;
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
