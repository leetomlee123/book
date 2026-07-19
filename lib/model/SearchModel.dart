import 'package:book/entity/BookInfo.dart';
import 'package:book/entity/GBook.dart';
import 'package:book/entity/SearchItem.dart';
import 'package:book/model/SourceModel.dart';
import 'package:book/source/engine/book_source_engine.dart';
import 'package:book/source/model/book_source.dart';
import 'package:book/source/model/search_book.dart';
import 'package:book/source/util/book_id.dart';
import 'package:book/common/local_store.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class SearchModel with ChangeNotifier {
  List<String> searchHistory = [];
  bool isBookSearch = false;
  BuildContext? context;
  bool showResult = false;
  List<SearchItem> bks = [];
  List<GBook> mks = [];
  List<Widget> hot = [];
  List<Widget> showHot = [];
  int idx = 0;
  bool loading = false;
  GlobalKey? textFieldKey;

  // ignore: non_constant_identifier_names
  String store_word = "";
  int page = 1;
  int size = 10;
  var word = "";
  var temp = "";
  RefreshController refreshController =
      RefreshController(initialRefresh: false);
  TextEditingController? controller;

  List<Color> colors = Colors.accents;

  final BookSourceEngine _engine = BookSourceEngine();
  SourceModel? sourceModel;

  /// Concurrent source search pool size.
  static const int poolSize = 5;

  void clear1() {
    searchHistory = [];
    page = 1;
    size = 10;
    notifyListeners();
  }

  void clear() {
    searchHistory = [];
    isBookSearch = false;
    idx = 0;
    showResult = false;
    bks = [];
    mks = [];
    hot = [];
    showHot = [];
    // ignore: non_constant_identifier_names
    store_word = "";
    page = 1;
    size = 10;
    word = "";
    temp = "";
  }

  Future<List<BookSource>> _enabled() async {
    if (sourceModel != null) {
      return sourceModel!.enabledSources();
    }
    return SourceModel().enabledSources();
  }

  Future<void> getSearchData() async {
    if (!loading) {
      return;
    }
    if (temp == "") {
      temp = word;
    } else {
      if (temp != word && page <= 1) {
        page = 1;
      }
    }
    //收起键盘
    if (context != null) {
      FocusScope.of(context!).requestFocus(FocusNode());
    }

    final sources = await _enabled();
    final searchable =
        sources.where((s) => s.searchUrl.isNotEmpty && s.enabled).toList();
    if (searchable.isEmpty) {
      loading = false;
      refreshController.loadNoData();
      BotToast.showText(text: '请先在「书源管理」导入并启用书源');
      notifyListeners();
      return;
    }

    try {
      final hits = await _searchAll(searchable, word, page);
      if (hits.isEmpty) {
        refreshController.loadNoData();
      } else {
        for (final h in hits) {
          bks.add(_toSearchItem(h));
        }
        refreshController.loadComplete();
      }
    } catch (e) {
      refreshController.loadFailed();
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

  void onRefresh() async {
    bks = [];
    mks = [];
    page = 1;
    loading = true;
    await getSearchData();
    loading = false;
    refreshController.refreshCompleted();
    notifyListeners();
  }

  void onLoading() async {
    page += 1;
    loading = true;
    await getSearchData();
    loading = false;

    notifyListeners();
  }

  void deleteHistoryItem(String source) {
    for (var i = 0; i < searchHistory.length; i++) {
      if (source == searchHistory[i]) {
        searchHistory.removeAt(i);
      }
    }
    SpUtil.putStringList(store_word, searchHistory);
    notifyListeners();
  }

  void toggleShowResult() {
    showResult = !showResult;
    notifyListeners();
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
    if (SpUtil.haveKey(store_word)) {
      SpUtil.remove(store_word);
    }
    SpUtil.putStringList(store_word, searchHistory);
  }

  void initHistory() {
    if (SpUtil.haveKey(store_word)) {
      searchHistory = SpUtil.getStringList(store_word);
    }
    notifyListeners();
  }

  void clearHistory() {
    SpUtil.remove(store_word);
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
    notifyListeners();
  }

  Future search(String w) async {
    word = w;
    if (w.isEmpty) return;
    setHistory(w);
    showResult = true;
    bks = [];
    mks = [];
    page = 1;
    temp = w;
    loading = true;
    // Reset pull-to-refresh footer so a previous "no more" doesn't stick.
    try {
      refreshController.resetNoData();
    } catch (_) {}
    notifyListeners(); // UI shows loading spinner
    try {
      await getSearchData();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future initBookHot() async {
    // Server hot list removed — show source tip instead.
    hot = [];
    final n = await SourceModel().enabledCount();
    hot.add(Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        n == 0 ? '尚未启用书源，请先导入书源' : '已启用 $n 个书源，输入书名或作者搜索',
        style: TextStyle(color: Colors.grey),
      ),
    ));
    notifyListeners();
  }

  void getHot() {
    showHot = hot;
    notifyListeners();
  }
}
