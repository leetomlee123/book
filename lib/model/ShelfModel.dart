import 'package:book/data/repositories/book_repository.dart';
import 'package:book/entity/Book.dart';
import 'package:book/event/event.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:book/common/local_store.dart';
import 'package:flutter/cupertino.dart';

class ShelfModel with ChangeNotifier {
  List<Book> shelf = [];

  bool inShelf(Object? id) {
    return shelf.map((f) => f.Id).toList().contains(id);
  }

  /// Sync in-memory shelf entry only. DB progress is written by ReadModel.saveData.
  void updReadBookProcess(UpdateBookProcess up) {
    Book? b;
    for (final item in shelf) {
      if (item.Id == up.bookId) {
        b = item;
        break;
      }
    }
    if (b == null) return;
    b.cur = up.cur;
    b.index = up.index;
    if (up.chapterName.isNotEmpty) {
      b.ChapterName = up.chapterName;
    }
    notifyListeners();
  }

  Future<void> initShelf() async {
    shelf = await _books.getAll();
    notifyListeners();
  }

  BuildContext? context;
  // WeChat Reading–like: cover grid is the product default.
  bool cover = SpUtil.getBool("cover", defValue: true);
  bool sortShelf = false;
  final BookRepository _books = BookRepository.instance;
  List<bool> _picks = [];

  bool pickAllFlag = false;

  void initPicks() {
    pickAllFlag = false;
    _picks = [];
    for (var i = 0; i < shelf.length; i++) {
      _picks.add(false);
    }
  }

  Future<void> removePicks() async {
    List<Book> bks = [];
    List<String> ids = [];
    List<bool> pics = [];

    for (var i = 0; i < _picks.length; i++) {
      if (_picks[i]) {
        await delLocalCache([shelf[i].Id]);
        ids.add(shelf[i].Id);
      } else {
        bks.add(shelf[i]);
        pics.add(_picks[i]);
      }
    }
    shelf = bks;
    _picks = pics;
    sortShelf = false;
    BotToast.showText(text: "删除书籍成功");
    notifyListeners();
  }

  void pickAll() {
    _picks = [];
    for (var i = 0; i < shelf.length; i++) {
      _picks.add(!pickAllFlag);
    }
    pickAllFlag = !pickAllFlag;

    notifyListeners();
  }

  bool picks(int i) {
    if (_picks.isEmpty) {
      for (var i = 0; i < shelf.length; i++) {
        _picks.add(false);
      }
    }
    if (_picks.length < shelf.length) {
      for (var i = 0; i < shelf.length - _picks.length; i++) {
        _picks.add(false);
      }
    }
    return _picks[i];
  }

  void changePick(int i) {
    _picks[i] = !_picks[i];
    notifyListeners();
  }

  bool hasPick() {
    return _picks.contains(true);
  }

  void toggleModel() {
    cover = !cover;
    SpUtil.putBool("cover", cover);
    notifyListeners();
  }

  void sortShelfModel() {
    initPicks();
    sortShelf = !sortShelf;
    notifyListeners();
  }

  /// Local-only shelf refresh (no cloud).
  Future<void> refreshShelf() async {
    shelf = await _books.getAll();
    notifyListeners();
  }

  /// 书架排序
  Future<void> sort(int i) async {
    var book = shelf[i];
    book.NewChapterCount = 0;
    book.sortTime = DateUtil.getNowDateMs();

    shelf.sort((o1, o2) => o2.sortTime.compareTo(o1.sortTime));
    notifyListeners();
    await _books.touchSortTime(book.Id);
  }

  /// 退出登录（本地账号，不清除书架）
  Future<void> dropAccountOut() async {
    SpUtil.remove("username");
    SpUtil.remove("auth");
    SpUtil.remove("email");
    BotToast.showText(text: "已退出登录");
    notifyListeners();
  }

//根据id判断书架是否存在本书
  bool exitsInBookShelfById(String id) {
    return shelf.map((f) => f.Id).toList().contains(id);
  }

  //删除本地记录
  Future<void> delLocalCache(List<String> ids) async {
    for (var i = 0; i < ids.length; i++) {
      await _books.delete(ids[i]);
    }
  }

  Future<void> modifyShelf(Book book) async {
    var action =
        shelf.map((f) => f.Id).toList().contains(book.Id) ? 'del' : 'add';
    if (action == "add") {
      shelf.insert(0, book);
      await _books.upsertAll([book]);
      notifyListeners();

      BotToast.showText(text: "已添加到书架");
    } else if (action == "del") {
      for (var i = 0; i < shelf.length; i++) {
        if (shelf[i].Id == book.Id) {
          shelf.removeAt(i);
          notifyListeners();
        }
      }
      delLocalCache([book.Id]);
      BotToast.showText(text: "已移除出书架");
    }
  }

  /// No-op: token refresh removed with book backend.
  Future<void> freshToken() async {}
}
