import 'package:book/entity/book_info.dart';
import 'package:book/entity/search_item.dart';
import 'package:book/model/source_model.dart';
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

  String historyKey = "";
  int page = 1;
  var word = "";
  TextEditingController? controller;

  final BookSourceEngine _engine = BookSourceEngine();

  /// Concurrent source search pool size.
  static const int poolSize = 5;

  void clear() {
    searchHistory = [];
    showResult = false;
    bks = [];
    historyKey = "";
    page = 1;
    word = "";
    noMore = false;
  }

  Future<List<BookSource>> _enabled() => SourceModel().enabledSources();

  Future<void> getSearchData() async {
    if (!loading) return;

    //收起键盘
    if (context != null) {
      FocusScope.of(context!).requestFocus(FocusNode());
    }

    final sources = await _enabled();
    final searchable =
        sources.where((s) => s.searchUrl.isNotEmpty && s.enabled).toList();
    if (searchable.isEmpty) {
      loading = false;
      noMore = true;
      BotToast.showText(text: '请先在「书源管理」导入并启用书源');
      notifyListeners();
      return;
    }

    try {
      final hits = await _searchAll(searchable, word, page);
      if (hits.isEmpty) {
        noMore = true;
      } else {
        for (final h in hits) {
          bks.add(_toSearchItem(h));
        }
      }
    } catch (e) {
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

  Future<List<SearchBook>> _searchAll(
      List<BookSource> sources, String key, int page) async {
    final results = <SearchBook>[];
    for (var i = 0; i < sources.length; i += poolSize) {
      final chunk = sources.skip(i).take(poolSize);
      final futures = chunk.map((s) async {
        try {
          return await _engine
              .search(s, key, page)
              .timeout(BookSourceEngine.sourceTimeout);
        } catch (_) {
          return <SearchBook>[];
        }
      });
      final lists = await Future.wait(futures);
      for (final list in lists) {
        results.addAll(list);
      }
    }
    return results;
  }

  /// Open book detail via local source rules.
  Future<BookInfo?> openDetail(SearchItem item) async {
    if (item.sourceUrl.isEmpty || item.bookUrl.isEmpty) {
      BotToast.showText(text: '该书缺少书源信息，请重新搜索');
      return null;
    }
    final src = await SourceModel().findByUrl(item.sourceUrl);
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
    loading = true;
    notifyListeners();
    try {
      await getSearchData();
    } finally {
      loading = false;
      notifyListeners();
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
    loading = true;
    notifyListeners(); // UI shows loading spinner
    try {
      await getSearchData();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
