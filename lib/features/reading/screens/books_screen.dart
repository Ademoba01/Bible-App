import 'package:flutter/material.dart';
import '../../../data/books.dart';

class BooksScreen extends StatelessWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ot = kAllBooks.where((b) => b.testament == 'OT').toList();
    final nt = kAllBooks.where((b) => b.testament == 'NT').toList();
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Books'),
          bottom: TabBar(
            indicatorColor: theme.colorScheme.onPrimary,
            labelColor: theme.colorScheme.onPrimary,
            unselectedLabelColor: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
            tabs: const [Tab(text: 'Old Testament'), Tab(text: 'New Testament')],
          ),
        ),
        body: TabBarView(
          children: [_BookList(ot), _BookList(nt)],
        ),
      ),
    );
  }
}

class _BookList extends StatelessWidget {
  const _BookList(this.books);
  final List<dynamic> books;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: books.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final b = books[i];
        return ListTile(
          title: Text(b.name),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pop(context, b.name),
        );
      },
    );
  }
}
