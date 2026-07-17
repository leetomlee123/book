import 'package:book/common/DbHelper.dart';
import 'package:book/entity/Book.dart';
import 'package:book/event/event.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:book/common/local_store.dart';
import 'package:flutter/cupertino.dart';

class ShelfModel with ChangeNotifier {
  List<Book> shelf = [];

  bool inShelf(var id) {
    return shelf.map((f) => f.Id).toList().contains(id);
  }

  updReadBookProcess(UpdateBookProcess up) {
    // Prefer matching by active book if present in shelf; fallback first.
    Book? b;
    for (final item in shelf) {
      // UpdateBookProcess historically only carried cur/index; update first book
      // that matches progress event target if extended later. For now update head.
      b = item;
      break;
    }
    if (b == null && shelf.isNotEmpty) b = shelf.first;
    if (b == null) return;
    b.cur = up.cur;
    b.index = up.index;
    DbHelper.instance.updBookProcess(b.cur, b.index, 0, b.Id);
  }

  Future<void> initShelf() async {
    shelf = await _dbHelper.getBooks();
    notifyListeners();
  }

  BuildContext? context;
  // WeChat Reading–like: cover grid is the product default.
  bool cover = SpUtil.getBool("cover", defValue: true);
  bool sortShelf = false;
  DbHelper _dbHelper = DbHelper.instance;
  List<bool> _picks = [];

  bool pickAllFlag = false;

  initPicks() {
    pickAllFlag = false;
    _picks = [];
    for (var i = 0; i < shelf.length; i++) {
      _picks.add(false);
    }
  }

  removePicks() async {
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

  pickAll() {
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

  changePick(int i) {
    _picks[i] = !_picks[i];
    notifyListeners();
  }

  bool hasPick() {
    return _picks.contains(true);
  }

  toggleModel() {
    cover = !cover;
    SpUtil.putBool("cover", cover);
    notifyListeners();
  }

  sortShelfModel() {
    initPicks();
    sortShelf = !sortShelf;
    notifyListeners();
  }

  /// Local-only shelf refresh (no cloud).
  refreshShelf() async {
    shelf = await _dbHelper.getBooks();
    notifyListeners();
  }

  /// 书架排序
  Future<void> sort(int i) async {
    var book = shelf[i];
    book.NewChapterCount = 0;
    book.sortTime = DateUtil.getNowDateMs();

    shelf.sort((o1, o2) => o2.sortTime.compareTo(o1.sortTime));
    notifyListeners();
    await _dbHelper.sortBook(book.Id);
  }

  /// 退出登录（本地账号，不清除书架）
  Future<void> dropAccountOut() async {
    final keys = SpUtil.getKeys();
    for (var key in keys) {
      if (key.contains("pages")) {
        // keep reading caches
      }
    }
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
      await SpUtil.remove(ids[i]);
      await _dbHelper.delBookAndCps(ids[i]);
    }
  }

  modifyShelf(Book book) async {
    var action =
        shelf.map((f) => f.Id).toList().contains(book.Id) ? 'del' : 'add';
    if (action == "add") {
      shelf.insert(0, book);
      await _dbHelper.addBooks([book]);
      SpUtil.putString(book.Id, "");
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
      SpUtil.remove(book.Id);
      SpUtil.getKeys().forEach((element) {
        if (element.startsWith(book.Id + "pages")) {
          SpUtil.remove(element);
        }
      });
      BotToast.showText(text: "已移除出书架");
    }
  }

  /// No-op: token refresh removed with book backend.
  freshToken() async {}
}
