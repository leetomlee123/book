import 'package:book/common/app_colors.dart';
import 'package:book/common/local_store.dart';
import 'package:book/entity/book.dart';
import 'package:book/model/read_model.dart';
import 'package:book/source/engine/book_source_engine.dart';
import 'package:book/source/model/book_source.dart';
import 'package:book/source/model/search_book.dart';
import 'package:book/source/util/text_clean.dart';
import 'package:book/store/providers.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:book/common/common.dart';

/// Bottom sheet: search enabled sources for the current book and switch.
///
/// Works both from the reader (active session) and the book detail page
/// (metadata only — no chapter window to open yet).
class SourceSwitchSheet extends ConsumerStatefulWidget {
  final ReadModel readModel;

  /// Called after a successful source switch so the host page can refresh UI.
  final void Function(Book book)? onSwitched;

  const SourceSwitchSheet({
    super.key,
    required this.readModel,
    this.onSwitched,
  });

  @override
  ConsumerState<SourceSwitchSheet> createState() => _SourceSwitchSheetState();
}

class _SourceSwitchSheetState extends ConsumerState<SourceSwitchSheet> {
  final BookSourceEngine _engine = BookSourceEngine();
  bool loading = true;
  String? error;
  final List<_Candidate> candidates = [];

  Book? get _book => widget.readModel.book;

  bool get _dark => SpUtil.getBool(PrefsKeys.dark);

  Color get _surface => _dark ? AppColors.surfaceDark : AppColors.surface;
  Color get _primary =>
      _dark ? AppColors.textOnDark : AppColors.textPrimary;
  Color get _secondary => AppColors.textSecondary;
  Color get _divider => _dark ? AppColors.dividerDark : AppColors.divider;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final book = _book;
    if (book == null) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = '当前没有可换源的书籍';
      });
      return;
    }
    final key = book.name.trim().isNotEmpty
        ? book.name.trim()
        : book.author.trim();
    if (key.isEmpty) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = '书名未知，无法搜索其它书源';
      });
      return;
    }

    final sources = await ref.read(sourceModelProvider).enabledSources();
    if (sources.isEmpty) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = '请先在「书源管理」导入并启用书源';
      });
      return;
    }

    final list = <_Candidate>[];
    const pool = 5;
    final author = cleanAuthor(book.author);
    for (var i = 0; i < sources.length; i += pool) {
      if (!mounted) return;
      final chunk = sources.skip(i).take(pool);
      final futures = chunk.map((s) async {
        try {
          final hits = await _engine
              .search(s, key, 1)
              .timeout(BookSourceEngine.sourceTimeout);
          return hits
              .where((h) => _isLikelyMatch(book, h, author))
              .map((h) => _Candidate(s, h))
              .toList();
        } catch (_) {
          return <_Candidate>[];
        }
      });
      final parts = await Future.wait(futures);
      for (final p in parts) {
        list.addAll(p);
      }
    }

    // Prefer exact name, then same source last, then source name.
    list.sort((a, b) {
      final an = _nameScore(a.hit.name, book.name);
      final bn = _nameScore(b.hit.name, book.name);
      if (an != bn) return an - bn;
      final aa = _authorScore(a.hit.author, author);
      final ba = _authorScore(b.hit.author, author);
      if (aa != ba) return aa - ba;
      return a.source.bookSourceName.compareTo(b.source.bookSourceName);
    });

    if (!mounted) return;
    setState(() {
      candidates
        ..clear()
        ..addAll(list);
      loading = false;
      error = list.isEmpty ? '未找到其它可用书源' : null;
    });
  }

  /// Strict-ish match: same/similar title; author only when both sides have one.
  bool _isLikelyMatch(Book book, SearchBook hit, String bookAuthor) {
    final bn = book.name.trim();
    final hn = hit.name.trim();
    if (bn.isEmpty || hn.isEmpty) return false;
    // Name must overlap (exact, contains, or strip spaces).
    final bnN = bn.replaceAll(RegExp(r'\s+'), '');
    final hnN = hn.replaceAll(RegExp(r'\s+'), '');
    final nameOk = bn == hn ||
        bnN == hnN ||
        bnN.contains(hnN) ||
        hnN.contains(bnN);
    if (!nameOk) return false;

    final ha = cleanAuthor(hit.author);
    if (bookAuthor.isEmpty || ha.isEmpty) return true;
    return ha.contains(bookAuthor) ||
        bookAuthor.contains(ha) ||
        ha == bookAuthor;
  }

  int _nameScore(String hit, String book) {
    if (hit == book) return 0;
    final a = hit.replaceAll(RegExp(r'\s+'), '');
    final b = book.replaceAll(RegExp(r'\s+'), '');
    if (a == b) return 1;
    if (a.contains(b) || b.contains(a)) return 2;
    return 3;
  }

  int _authorScore(String hit, String book) {
    if (book.isEmpty) return 1;
    final h = cleanAuthor(hit);
    if (h.isEmpty) return 2;
    if (h == book) return 0;
    if (h.contains(book) || book.contains(h)) return 1;
    return 3;
  }

  Future<void> _onPick(_Candidate c) async {
    final book = _book;
    if (book == null) return;
    final current = c.source.bookSourceUrl == book.sourceUrl &&
        (c.hit.bookUrl.isEmpty || c.hit.bookUrl == book.bookUrl);
    if (current) return;

    final ok = await widget.readModel.switchSource(c.source, c.hit);
    if (!mounted) return;
    if (ok) {
      widget.onSwitched?.call(widget.readModel.book ?? book);
      Navigator.pop(context, true);
    } else {
      BotToast.showText(text: '换源失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = _book;
    return Material(
      color: _surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '换源 · ${book?.name ?? ''}',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: _primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: _secondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              if ((book?.originName ?? '').trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '当前：${book!.originName}',
                      style: TextStyle(fontSize: 13, color: _secondary),
                    ),
                  ),
                ),
              Divider(height: 1, color: _divider),
              Expanded(
                child: loading
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(strokeWidth: 2.5),
                            SizedBox(height: 12),
                            Text(
                              '正在搜索可用书源…',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : candidates.isEmpty
                        ? Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                error ?? '未找到其它可用书源',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _secondary,
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: candidates.length,
                            separatorBuilder: (_, _) =>
                                Divider(height: 1, color: _divider),
                            itemBuilder: (ctx, i) {
                              final c = candidates[i];
                              final isCurrent = book != null &&
                                  c.source.bookSourceUrl == book.sourceUrl;
                              final author = cleanAuthor(c.hit.author);
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                title: Text(
                                  c.source.bookSourceName.isNotEmpty
                                      ? c.source.bookSourceName
                                      : c.source.bookSourceUrl,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: _primary,
                                  ),
                                ),
                                subtitle: Text(
                                  [
                                    c.hit.name,
                                    if (author.isNotEmpty) author,
                                    if (c.hit.lastChapter.isNotEmpty)
                                      c.hit.lastChapter,
                                  ].join(' · '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _secondary,
                                    height: 1.35,
                                  ),
                                ),
                                trailing: isCurrent
                                    ? Text(
                                        '当前',
                                        style: TextStyle(
                                          color: AppColors.brand,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    : Icon(
                                        Icons.chevron_right,
                                        color: _secondary,
                                      ),
                                onTap: isCurrent ? null : () => _onPick(c),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Candidate {
  final BookSource source;
  final SearchBook hit;
  _Candidate(this.source, this.hit);
}
