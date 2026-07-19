import 'package:book/entity/BookInfo.dart';
import 'package:book/entity/SearchItem.dart';
import 'package:book/model/SourceModel.dart';
import 'package:book/source/engine/book_source_engine.dart';
import 'package:book/source/model/book_source.dart';
import 'package:book/source/model/search_book.dart';
import 'package:book/source/util/book_id.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

/// Bottom-tab discovery: book-source exploreUrl kinds + paginated book list.
class ExploreModel with ChangeNotifier {
  final BookSourceEngine _engine = BookSourceEngine();

  List<BookSource> exploreSources = [];
  BookSource? activeSource;
  List<ExploreKind> kinds = [];
  ExploreKind? activeKind;

  List<SearchItem> books = [];
  bool loading = false;
  bool bootstrapped = false;
  int page = 1;
  String? error;

  final RefreshController refreshController =
      RefreshController(initialRefresh: false);

  Future<void> ensureLoaded() async {
    if (bootstrapped && exploreSources.isNotEmpty) return;
    await reloadSources();
  }

  Future<void> reloadSources() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final all = await SourceModel().enabledSources();
      exploreSources = all.where((s) => s.canExplore).toList()
        ..sort((a, b) => a.customOrder.compareTo(b.customOrder));

      if (exploreSources.isEmpty) {
        activeSource = null;
        kinds = [];
        activeKind = null;
        books = [];
        error = '暂无可用发现书源，请在「书源管理」导入并启用带 explore 的书源';
        return;
      }

      // Keep previous selection if still present.
      final prevUrl = activeSource?.bookSourceUrl;
      activeSource = exploreSources.firstWhere(
        (s) => s.bookSourceUrl == prevUrl,
        orElse: () => exploreSources.first,
      );
      _applyKinds();
      bootstrapped = true;
      await loadBooks(refresh: true);
    } catch (e) {
      error = '加载发现失败：$e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void _applyKinds() {
    final src = activeSource;
    if (src == null) {
      kinds = [];
      activeKind = null;
      return;
    }
    kinds = parseExploreKinds(src.exploreUrl);
    if (kinds.isEmpty) {
      kinds = [ExploreKind(title: '全部', url: src.exploreUrl)];
    }
    final prev = activeKind?.title;
    activeKind = kinds.firstWhere(
      (k) => k.title == prev,
      orElse: () => kinds.first,
    );
  }

  Future<void> selectSource(BookSource source) async {
    if (activeSource?.bookSourceUrl == source.bookSourceUrl) return;
    activeSource = source;
    _applyKinds();
    await loadBooks(refresh: true);
  }

  Future<void> selectKind(ExploreKind kind) async {
    if (activeKind?.title == kind.title && activeKind?.url == kind.url) return;
    activeKind = kind;
    await loadBooks(refresh: true);
  }

  Future<void> loadBooks({bool refresh = false}) async {
    final src = activeSource;
    final kind = activeKind;
    if (src == null || kind == null) return;

    if (refresh) {
      page = 1;
      books = [];
      try {
        refreshController.resetNoData();
      } catch (_) {}
    }

    loading = true;
    error = null;
    notifyListeners();
    try {
      final hits = await _engine.explore(src, kind.url, page: page);
      if (hits.isEmpty) {
        if (page == 1) {
          error = '该分类暂无内容';
        }
        refreshController.loadNoData();
      } else {
        for (final h in hits) {
          books.add(_toItem(h));
        }
        refreshController.loadComplete();
      }
      if (refresh) {
        refreshController.refreshCompleted();
      }
    } catch (e) {
      error = '加载失败：$e';
      if (refresh) {
        refreshController.refreshFailed();
      } else {
        refreshController.loadFailed();
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> onRefresh() async {
    await loadBooks(refresh: true);
  }

  Future<void> onLoading() async {
    page += 1;
    await loadBooks(refresh: false);
  }

  SearchItem _toItem(SearchBook h) {
    final id = makeBookKey(h.sourceUrl, h.bookUrl);
    return SearchItem(
      id: id,
      name: h.name,
      author: h.author,
      coverUrl: h.coverUrl,
      description: h.intro,
      latestChapter: h.lastChapter,
      category: h.kind,
      sourceUrl: h.sourceUrl,
      bookUrl: h.bookUrl,
      sourceName: h.sourceName,
    );
  }

  Future<BookInfo?> openDetail(SearchItem item) async {
    if (item.sourceUrl.isEmpty || item.bookUrl.isEmpty) {
      BotToast.showText(text: '该书缺少书源信息');
      return null;
    }
    final src = await SourceModel().findByUrl(item.sourceUrl);
    if (src == null) {
      BotToast.showText(text: '书源不存在：${item.sourceName}');
      return null;
    }
    try {
      final seed = SearchBook(
        name: item.name,
        author: item.author,
        intro: item.description,
        coverUrl: item.coverUrl,
        lastChapter: item.latestChapter,
        kind: item.category,
        bookUrl: item.bookUrl,
        sourceUrl: item.sourceUrl,
        sourceName: item.sourceName,
      );
      return await _engine.bookInfo(src, item.bookUrl, seed: seed);
    } catch (e) {
      BotToast.showText(text: '获取详情失败：$e');
      return null;
    }
  }
}
