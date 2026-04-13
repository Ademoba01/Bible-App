import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../state/providers.dart';
import 'similar_verses_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  List<({VerseRef ref, String text})> _results = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

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

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _run);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _run(),
              onChanged: _onSearchChanged,
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
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Icon(Icons.bookmark_outline, color: theme.colorScheme.primary),
                          title: Text(r.ref.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(r.text, maxLines: 4, overflow: TextOverflow.ellipsis),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.auto_awesome, size: 18, color: theme.colorScheme.secondary),
                                tooltip: 'Find similar verses',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SimilarVersesScreen(
                                        sourceRef: r.ref,
                                        sourceText: r.text,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Icon(Icons.arrow_forward_ios, size: 14, color: theme.colorScheme.outline),
                            ],
                          ),
                          onTap: () {
                            ref.read(readingLocationProvider.notifier).setBook(r.ref.book);
                            ref.read(readingLocationProvider.notifier).setChapter(r.ref.chapter);
                            ref.read(highlightVerseProvider.notifier).state = r.ref.verse;
                            ref.read(tabIndexProvider.notifier).state = 1;
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
