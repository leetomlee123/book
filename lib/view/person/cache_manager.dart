import 'package:book/common/app_colors.dart';
import 'package:book/common/app_log.dart';
import 'package:book/data/repositories/book_repository.dart';
import 'package:book/data/repositories/chapter_repository.dart';
import 'package:book/entity/book.dart';
import 'package:flutter/material.dart';

/// Cache management against [reader.db] chapter bodies + page layouts.
class CacheManager extends StatefulWidget {
  const CacheManager({super.key});

  @override
  State<CacheManager> createState() => _CacheManagerState();
}

class _CacheManagerState extends State<CacheManager> {
  final BookRepository _books = BookRepository.instance;
  final ChapterRepository _chapters = ChapterRepository.instance;

  bool _loading = true;
  int _pageCacheBytes = 0;
  List<_BookCacheRow> _rows = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final books = await _books.getAll();
      final pageBytes = await _chapters.pageCacheBytes();
      final rows = <_BookCacheRow>[];
      for (final book in books) {
        final stats = await _chapters.bodyStats(book.id);
        rows.add(_BookCacheRow(book: book, stats: stats));
      }
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _pageCacheBytes = pageBytes;
        _loading = false;
      });
    } catch (e, st) {
      AppLog.w('Cache', 'reload failed', error: e);
      AppLog.d('Cache', '$st');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _clearPageLayouts() async {
    await _chapters.clearAllPageLayouts();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已清除分页缓存')),
    );
    await _reload();
  }

  Future<void> _clearBookBodies(String bookId) async {
    await _chapters.clearBook(bookId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已清除本书章节缓存')),
    );
    await _reload();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('缓存管理'),
        centerTitle: true,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _loading ? null : _clearPageLayouts,
            child: const Text('清分页'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Card(
                    child: ListTile(
                      title: const Text('分页缓存占用'),
                      subtitle: Text(_formatBytes(_pageCacheBytes)),
                      trailing: IconButton(
                        tooltip: '清除全部分页缓存',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: _clearPageLayouts,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '书籍章节缓存',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_rows.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: Text('暂无本地书籍')),
                    )
                  else
                    ..._rows.map((row) {
                      final total = row.stats.total;
                      final withBody = row.stats.withBody;
                      final progress = total == 0 ? 0.0 : withBody / total;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row.book.name.isEmpty ? row.book.id : row.book.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 6,
                                        backgroundColor: AppColors.divider,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$withBody / $total',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  IconButton(
                                    tooltip: '清除章节正文与分页',
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _clearBookBodies(row.book.id),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class _BookCacheRow {
  const _BookCacheRow({required this.book, required this.stats});

  final Book book;
  final ({int total, int withBody}) stats;
}
