import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

// API base URL - change for production
const _apiBase = 'http://localhost:3001/api';

// ---------------------------------------------------------------------------
// Data Models
// ---------------------------------------------------------------------------

class StudyMaterial {
  final int id;
  final String title, author, source, category, content;
  final String? date, bibleReading, memoryVerse;

  StudyMaterial.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? 0,
        title = json['title'] ?? '',
        author = json['author'] ?? '',
        source = json['source'] ?? '',
        category = json['category'] ?? 'General',
        content = json['content'] ?? '',
        date = json['date'],
        bibleReading = json['bible_reading'] ?? json['bibleReading'],
        memoryVerse = json['memory_verse'] ?? json['memoryVerse'];
}

class Hymn {
  final int id;
  final int? number;
  final String title, lyrics;
  final String? author, category;
  final int? year;

  Hymn.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? 0,
        number = json['number'],
        title = json['title'] ?? '',
        lyrics = json['lyrics'] ?? '',
        author = json['author'],
        category = json['category'],
        year = json['year'];
}

class CommunityPost {
  final int id;
  final String title, content, category;
  final String? authorName;
  final int likesCount, viewsCount;
  final String createdAt;

  CommunityPost.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? 0,
        title = json['title'] ?? '',
        content = json['content'] ?? '',
        category = json['category'] ?? 'General',
        authorName = json['author_name'] ?? json['authorName'],
        likesCount = json['likes_count'] ?? json['likesCount'] ?? 0,
        viewsCount = json['views_count'] ?? json['viewsCount'] ?? 0,
        createdAt = json['created_at'] ?? json['createdAt'] ?? '';
}

// ---------------------------------------------------------------------------
// API Service
// ---------------------------------------------------------------------------

class CommunityApi {
  static Future<List<StudyMaterial>> getMaterials({String? category}) async {
    try {
      final uri = Uri.parse(
        '$_apiBase/community/materials${category != null && category != 'All' ? '?category=$category' : ''}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final list = (body is List ? body : body['data'] ?? []) as List;
        return list.map((j) => StudyMaterial.fromJson(j as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<Hymn>> getHymns({String? search}) async {
    try {
      final uri = Uri.parse(
        '$_apiBase/community/hymns${search != null && search.isNotEmpty ? '?search=$search' : ''}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final list = (body is List ? body : body['data'] ?? []) as List;
        return list.map((j) => Hymn.fromJson(j as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<CommunityPost>> getPosts({String? category}) async {
    try {
      final uri = Uri.parse(
        '$_apiBase/community/posts${category != null && category != 'All' ? '?category=$category' : ''}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final list = (body is List ? body : body['data'] ?? []) as List;
        return list.map((j) => CommunityPost.fromJson(j as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> createPost({
    required String title,
    required String content,
    required String category,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_apiBase/community/posts'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'title': title, 'content': content, 'category': category}),
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> likePost(int postId) async {
    try {
      final res = await http.post(
        Uri.parse('$_apiBase/community/posts/$postId/like'),
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

// ---------------------------------------------------------------------------
// Community Screen (Tabbed)
// ---------------------------------------------------------------------------

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Community', style: GoogleFonts.lora(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.lora(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Study Materials'),
            Tab(text: 'Hymns'),
            Tab(text: 'Share'),
          ],
          indicatorColor: theme.colorScheme.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _StudyMaterialsTab(),
          _HymnsTab(),
          _ShareTab(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1: Study Materials
// ---------------------------------------------------------------------------

class _StudyMaterialsTab extends StatefulWidget {
  const _StudyMaterialsTab();
  @override
  State<_StudyMaterialsTab> createState() => _StudyMaterialsTabState();
}

class _StudyMaterialsTabState extends State<_StudyMaterialsTab>
    with AutomaticKeepAliveClientMixin {
  static const _categories = ['All', 'Open Heavens', 'Search the Scriptures', 'Daily Manna'];
  String _selectedCategory = 'All';
  List<StudyMaterial> _materials = [];
  bool _loading = true;
  bool _failed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final data = await CommunityApi.getMaterials(
      category: _selectedCategory == 'All' ? null : _selectedCategory,
    );
    if (!mounted) return;
    setState(() {
      _materials = data;
      _loading = false;
      _failed = data.isEmpty && _selectedCategory == 'All';
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Column(
      children: [
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: _categories.map((cat) {
              final selected = cat == _selectedCategory;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat, style: GoogleFonts.lora(fontSize: 12)),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _selectedCategory = cat);
                    _loadData();
                  },
                  selectedColor: theme.colorScheme.primaryContainer,
                ),
              );
            }).toList(),
          ),
        ),

        // Content
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _failed
                  ? _OfflineFallback(onRetry: _loadData)
                  : _materials.isEmpty
                      ? Center(
                          child: Text(
                            'No study materials found.',
                            style: GoogleFonts.lora(color: theme.colorScheme.outline),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _materials.length,
                            itemBuilder: (context, i) =>
                                _StudyMaterialCard(material: _materials[i]),
                          ),
                        ),
        ),
      ],
    );
  }
}

class _StudyMaterialCard extends StatelessWidget {
  const _StudyMaterialCard({required this.material});
  final StudyMaterial material;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _StudyMaterialDetail(material: material)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _sourceBadge(material.category),
                  const Spacer(),
                  if (material.date != null)
                    Text(
                      material.date!,
                      style: GoogleFonts.lora(
                        fontSize: 12,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                material.title,
                style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'By ${material.author}',
                style: GoogleFonts.lora(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (material.memoryVerse != null && material.memoryVerse!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.format_quote, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          material.memoryVerse!,
                          style: GoogleFonts.lora(fontStyle: FontStyle.italic, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StudyMaterialDetail extends StatelessWidget {
  const _StudyMaterialDetail({required this.material});
  final StudyMaterial material;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Study Material', style: GoogleFonts.lora(fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sourceBadge(material.category),
            const SizedBox(height: 12),
            Text(
              material.title,
              style: GoogleFonts.lora(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'By ${material.author}',
              style: GoogleFonts.lora(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
            ),
            if (material.date != null) ...[
              const SizedBox(height: 4),
              Text(
                material.date!,
                style: GoogleFonts.lora(fontSize: 13, color: theme.colorScheme.outline),
              ),
            ],
            if (material.bibleReading != null && material.bibleReading!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.menu_book, size: 18, color: theme.colorScheme.secondary),
                    const SizedBox(width: 8),
                    Text(
                      'Bible Reading: ${material.bibleReading}',
                      style: GoogleFonts.lora(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
            if (material.memoryVerse != null && material.memoryVerse!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.format_quote, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        material.memoryVerse!,
                        style: GoogleFonts.lora(fontStyle: FontStyle.italic, fontSize: 15, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Divider(height: 32),
            Text(
              material.content,
              style: GoogleFonts.lora(fontSize: 16, height: 1.7),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2: Hymns
// ---------------------------------------------------------------------------

class _HymnsTab extends StatefulWidget {
  const _HymnsTab();
  @override
  State<_HymnsTab> createState() => _HymnsTabState();
}

class _HymnsTabState extends State<_HymnsTab> with AutomaticKeepAliveClientMixin {
  final _searchCtrl = TextEditingController();
  List<Hymn> _hymns = [];
  bool _loading = true;
  bool _failed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final data = await CommunityApi.getHymns(
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _hymns = data;
      _loading = false;
      _failed = data.isEmpty && _searchCtrl.text.trim().isEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchCtrl,
            onSubmitted: (_) => _loadData(),
            decoration: InputDecoration(
              hintText: 'Search hymns...',
              hintStyle: GoogleFonts.lora(fontSize: 14),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        _searchCtrl.clear();
                        _loadData();
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),

        // Content
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _failed
                  ? _OfflineFallback(onRetry: _loadData)
                  : _hymns.isEmpty
                      ? Center(
                          child: Text(
                            'No hymns found.',
                            style: GoogleFonts.lora(color: theme.colorScheme.outline),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _hymns.length,
                            itemBuilder: (context, i) => _HymnCard(hymn: _hymns[i]),
                          ),
                        ),
        ),
      ],
    );
  }
}

class _HymnCard extends StatelessWidget {
  const _HymnCard({required this.hymn});
  final Hymn hymn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: hymn.number != null
            ? CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  '${hymn.number}',
                  style: GoogleFonts.lora(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              )
            : CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(Icons.music_note, color: theme.colorScheme.onPrimaryContainer),
              ),
        title: Text(
          hymn.title,
          style: GoogleFonts.lora(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          [if (hymn.author != null) hymn.author!, if (hymn.year != null) '${hymn.year}']
              .join(' \u00b7 '),
          style: GoogleFonts.lora(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: Icon(Icons.chevron_right, color: theme.colorScheme.outline),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _HymnDetail(hymn: hymn)),
        ),
      ),
    );
  }
}

class _HymnDetail extends StatelessWidget {
  const _HymnDetail({required this.hymn});
  final Hymn hymn;

  void _shareHymn(BuildContext context) {
    final text = StringBuffer();
    text.writeln(hymn.title);
    if (hymn.author != null) text.writeln('By ${hymn.author}');
    text.writeln();
    text.write(hymn.lyrics);
    Share.share(text.toString());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verses = hymn.lyrics.split('\n\n');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          hymn.number != null ? 'Hymn ${hymn.number}' : 'Hymn',
          style: GoogleFonts.lora(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareHymn(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hymn.title,
              style: GoogleFonts.lora(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              [if (hymn.author != null) hymn.author!, if (hymn.year != null) '${hymn.year}']
                  .join(' \u00b7 '),
              style: GoogleFonts.lora(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
            ),
            const Divider(height: 32),
            ...verses.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verse ${e.key + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          e.value,
                          style: GoogleFonts.lora(fontSize: 17, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 3: Share (Community Posts)
// ---------------------------------------------------------------------------

class _ShareTab extends StatefulWidget {
  const _ShareTab();
  @override
  State<_ShareTab> createState() => _ShareTabState();
}

class _ShareTabState extends State<_ShareTab> with AutomaticKeepAliveClientMixin {
  static const _categories = ['All', 'Devotionals', 'Testimonies', 'Study Material', 'Discussion'];
  String _selectedCategory = 'All';
  List<CommunityPost> _posts = [];
  bool _loading = true;
  bool _failed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final data = await CommunityApi.getPosts(
      category: _selectedCategory == 'All' ? null : _selectedCategory,
    );
    if (!mounted) return;
    setState(() {
      _posts = data;
      _loading = false;
      _failed = data.isEmpty && _selectedCategory == 'All';
    });
  }

  void _showCreatePostDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String category = 'Devotionals';

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Center(
        child: Container(
          width: 400,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
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
            child: StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Share with the Community',
                style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: GoogleFonts.lora(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: GoogleFonts.lora(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: ['Devotionals', 'Testimonies', 'Study Material', 'Discussion']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setSheetState(() => category = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Content',
                  labelStyle: GoogleFonts.lora(),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.send),
                label: Text('Submit', style: GoogleFonts.lora(fontWeight: FontWeight.w600)),
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill in all fields.')),
                    );
                    return;
                  }
                  final ok = await CommunityApi.createPost(
                    title: titleCtrl.text.trim(),
                    content: contentCtrl.text.trim(),
                    category: category,
                  );
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? 'Post submitted for review!'
                            : 'Could not submit post. Please try again.',
                      ),
                    ),
                  );
                  if (ok) _loadData();
                },
              ),
            ],
          ),
        ),
      ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Stack(
      children: [
        Column(
          children: [
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: _categories.map((cat) {
                  final selected = cat == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat, style: GoogleFonts.lora(fontSize: 12)),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _selectedCategory = cat);
                        _loadData();
                      },
                      selectedColor: theme.colorScheme.primaryContainer,
                    ),
                  );
                }).toList(),
              ),
            ),

            // Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _failed
                      ? _OfflineFallback(onRetry: _loadData)
                      : _posts.isEmpty
                          ? Center(
                              child: Text(
                                'No posts yet. Be the first to share!',
                                style: GoogleFonts.lora(color: theme.colorScheme.outline),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadData,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                                itemCount: _posts.length,
                                itemBuilder: (context, i) =>
                                    _PostCard(post: _posts[i], onLiked: _loadData),
                              ),
                            ),
            ),
          ],
        ),

        // FAB
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'community_fab',
            icon: const Icon(Icons.edit),
            label: Text('Share', style: GoogleFonts.lora(fontWeight: FontWeight.w600)),
            onPressed: _showCreatePostDialog,
          ),
        ),
      ],
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.onLiked});
  final CommunityPost post;
  final VoidCallback onLiked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _PostDetail(post: post)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _postCategoryBadge(post.category),
                  const Spacer(),
                  if (post.createdAt.isNotEmpty)
                    Text(
                      _formatDate(post.createdAt),
                      style: GoogleFonts.lora(fontSize: 11, color: theme.colorScheme.outline),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                post.title,
                style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              if (post.authorName != null && post.authorName!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'By ${post.authorName}',
                  style: GoogleFonts.lora(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                post.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lora(fontSize: 14, height: 1.5, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () async {
                      await CommunityApi.likePost(post.id);
                      onLiked();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite_border, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text('${post.likesCount}', style: GoogleFonts.lora(fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_outlined, size: 18, color: theme.colorScheme.outline),
                      const SizedBox(width: 4),
                      Text('${post.viewsCount}', style: GoogleFonts.lora(fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostDetail extends StatelessWidget {
  const _PostDetail({required this.post});
  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Post', style: GoogleFonts.lora(fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _postCategoryBadge(post.category),
            const SizedBox(height: 12),
            Text(
              post.title,
              style: GoogleFonts.lora(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              [
                if (post.authorName != null) 'By ${post.authorName}',
                if (post.createdAt.isNotEmpty) _formatDate(post.createdAt),
              ].join(' \u00b7 '),
              style: GoogleFonts.lora(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
            ),
            const Divider(height: 32),
            Text(
              post.content,
              style: GoogleFonts.lora(fontSize: 16, height: 1.7),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared Helpers
// ---------------------------------------------------------------------------

Widget _sourceBadge(String category) {
  Color color;
  switch (category) {
    case 'Open Heavens':
      color = Colors.deepPurple;
      break;
    case 'Search the Scriptures':
      color = Colors.indigo;
      break;
    case 'Daily Manna':
      color = const Color(0xFF1B5E20);
      break;
    default:
      color = Colors.brown;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      category,
      style: GoogleFonts.lora(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );
}

Widget _postCategoryBadge(String category) {
  Color color;
  switch (category) {
    case 'Devotionals':
      color = Colors.deepPurple;
      break;
    case 'Testimonies':
      color = Colors.teal;
      break;
    case 'Study Material':
      color = Colors.indigo;
      break;
    case 'Discussion':
      color = Colors.orange.shade800;
      break;
    default:
      color = Colors.brown;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      category,
      style: GoogleFonts.lora(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );
}

String _formatDate(String isoDate) {
  try {
    final dt = DateTime.parse(isoDate);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  } catch (_) {
    return isoDate;
  }
}

class _OfflineFallback extends StatelessWidget {
  const _OfflineFallback({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Connect to explore',
              style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Community features require an internet connection.',
              style: GoogleFonts.lora(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text('Try Again', style: GoogleFonts.lora(fontWeight: FontWeight.w600)),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
