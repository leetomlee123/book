import 'package:book/data/repositories/source_repository.dart';
import 'package:book/entity/book_info.dart';
import 'package:book/entity/search_item.dart';
import 'package:book/source/engine/book_source_engine.dart';
import 'package:book/source/model/book_source.dart';
import 'package:book/source/model/search_book.dart';
import 'package:book/source/util/book_id.dart';
import 'package:book/common/local_store.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

class SearchModel with ChangeNotifier {
  List<String> searchHistory = [];
  BuildContext? context;
  bool showResult = false;
  List<SearchItem> bks = [];
  bool loading = false;

  /// True after a page returns empty results — stops further load-more.
  bool noMore = false;

  /// How many searchable sources were scanned in the current page sweep.
  int searchedSources = 0;

  /// Total searchable sources for the current page sweep.
  int totalSources = 0;

  String historyKey = "";
  int page = 1;
  var word = "";
  TextEditingController? controller;

  final BookSourceEngine _engine = BookSourceEngine();
  final SourceRepository _sources = SourceRepository.instance;

  /// Concurrent source search pool size.
  static const int poolSize = 8;

  /// Bumps on each new search/loadMore so stale chunks are discarded.
  int _searchGen = 0;

  void clear() {
    searchHistory = [];
    showResult = false;
    bks = [];
    historyKey = "";
    page = 1;
    word = "";
    noMore = false;
    loading = false;
    searchedSources = 0;
    totalSources = 0;
    _searchGen++;
  }

  Future<List<BookSource>> _enabled() => _sources.getEnabled();

  Future<void> getSearchData(int gen) async {
    //收起键盘
    if (context != null) {
      FocusScope.of(context!).requestFocus(FocusNode());
    }

    final sources = await _enabled();
    if (gen != _searchGen) return;

    final searchable =
        sources.where((s) => s.searchUrl.isNotEmpty && s.enabled).toList();
    if (searchable.isEmpty) {
      if (gen != _searchGen) return;
      noMore = true;
      BotToast.showText(text: '请先在「书源管理」导入并启用书源');
      notifyListeners();
      return;
    }

    totalSources = searchable.length;
    searchedSources = 0;
    notifyListeners();

    try {
      var pageHits = 0;
      for (var i = 0; i < searchable.length; i += poolSize) {
        if (gen != _searchGen) return;
        final chunk = searchable.skip(i).take(poolSize).toList();
        final futures = chunk.map((s) async {
          try {
            return await _engine
                .search(s, word, page)
                .timeout(BookSourceEngine.sourceTimeout);
          } catch (_) {
            return <SearchBook>[];
          }
        });
        final lists = await Future.wait(futures);
        if (gen != _searchGen) return;

        searchedSources =
            (i + chunk.length).clamp(0, searchable.length);
        for (final list in lists) {
          pageHits += list.length;
          for (final h in list) {
            bks.add(_toSearchItem(h));
          }
        }
        // Progressive UI: leave full-screen spinner as soon as first hits arrive.
        notifyListeners();
      }
      if (gen != _searchGen) return;
      if (pageHits == 0) {
        noMore = true;
      }
    } catch (e) {
      if (gen != _searchGen) return;
      BotToast.showText(text: '搜索失败：$e');
    }
  }

  SearchItem _toSearchItem(SearchBook h) {
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

  /// Open book detail via local source rules.
  Future<BookInfo?> openDetail(SearchItem item) async {
    if (item.sourceUrl.isEmpty || item.bookUrl.isEmpty) {
      BotToast.showText(text: '该书缺少书源信息，请重新搜索');
      return null;
    }
    final src = await _sources.getByUrl(item.sourceUrl);
    if (src == null) {
      BotToast.showText(text: '书源不存在或已删除：${item.sourceName}');
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
      final info = await _engine.bookInfo(src, item.bookUrl, seed: seed);
      return info;
    } catch (e) {
      BotToast.showText(text: '获取详情失败：$e');
      return null;
    }
  }

  Future<void> loadMore() async {
    if (loading || noMore || word.isEmpty) return;
    page += 1;
    final gen = ++_searchGen;
    loading = true;
    notifyListeners();
    try {
      await getSearchData(gen);
    } finally {
      if (gen == _searchGen) {
        loading = false;
        notifyListeners();
      }
    }
  }

  List<Widget> getHistory() {
    List<Widget> wds = [];
    for (var value in searchHistory) {
      wds.add(GestureDetector(
        onTap: () {
          word = value;
          controller?.text = value;
          search(value);
          notifyListeners();
        },
        child: Chip(
          label: Text(value),
          padding: EdgeInsets.all(2),
        ),
      ));
    }

    return wds;
  }

  void setHistory(String value) {
    if (value.isEmpty) {
      return;
    }
    for (var ii = 0; ii < searchHistory.length; ii++) {
      if (searchHistory[ii] == value) {
        searchHistory.removeAt(ii);
      }
    }
    searchHistory.insert(0, value);
    if (SpUtil.haveKey(historyKey)) {
      SpUtil.remove(historyKey);
    }
    SpUtil.putStringList(historyKey, searchHistory);
  }

  void initHistory() {
    if (SpUtil.haveKey(historyKey)) {
      searchHistory = SpUtil.getStringList(historyKey);
    }
    notifyListeners();
  }

  void clearHistory() {
    SpUtil.remove(historyKey);
    searchHistory = [];
    notifyListeners();
  }

  void reset() {
    if (word.isEmpty) {
      return;
    }
    word = "";
    page = 1;
    showResult = false;
    noMore = false;
    loading = false;
    searchedSources = 0;
    totalSources = 0;
    _searchGen++;
    notifyListeners();
  }

  Future search(String w) async {
    word = w;
    if (w.isEmpty) return;
    setHistory(w);
    showResult = true;
    bks = [];
    page = 1;
    noMore = false;
    searchedSources = 0;
    totalSources = 0;
    final gen = ++_searchGen;
    loading = true;
    notifyListeners(); // UI shows loading spinner
    try {
      await getSearchData(gen);
    } finally {
      if (gen == _searchGen) {
        loading = false;
        notifyListeners();
      }
    }
  }
}
