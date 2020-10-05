import 'package:book/common/DbHelper.dart';
import 'package:book/common/common.dart';
import 'package:book/common/net.dart';
import 'package:book/entity/Book.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';

class ShelfModel with ChangeNotifier {
  List<Book> shelf = [];

  Future<void> setShelf() async {
    if (_dbHelper == null) {
      _dbHelper = DbHelper();
    }
    shelf = await _dbHelper.getBooks();
    notifyListeners();
  }

  BuildContext context;
  bool model = SpUtil.getBool("shelfModel");
  bool sortShelf = false;
  DbHelper _dbHelper = DbHelper();
  List<bool> _picks = [];
  ShelfModel();
  bool pickAllFlag = false;
  initPicks() {
    pickAllFlag = false;
    _picks = [];
    for (var i = 0; i < shelf.length; i++) {
      _picks.add(false);
    }
  }

  removePicks() {
    List<Book> bks = [];
    List<String> ids = [];
    List<bool> pics = [];

    for (var i = 0; i < _picks.length; i++) {
      if (_picks[i]) {
        delLocalCache([shelf[i].Id]);
        ids.add(shelf[i].Id);
      } else {
        bks.add(shelf[i]);
        pics.add(_picks[i]);
      }
    }
    shelf = bks;
    _picks = pics;
    sortShelf = false;
    deleteCloudIds(ids);
    notifyListeners();
  }

  deleteCloudIds(List<String> ids) async {
    if (SpUtil.haveKey("auth")) {
      for (var id in ids) {
        await Util(null).http().get(Common.bookAction + '/$id/del');
      }
    }
    BotToast.showText(text: "删除书籍成功");
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
    return _picks[i];
  }

  changePick(int i) {
    _picks[i] = !_picks[i];
    notifyListeners();
  }

  bool hasPick() {
    return _picks.contains(true);
  }

  saveShelf() {
    // SpUtil.putString(Common.listbookname, jsonEncode(shelf));
  }

  toggleModel() {
    model = !model;
    SpUtil.putBool("shelfModel", model);
    notifyListeners();
  }

  sortShelfModel() {
    initPicks();
    sortShelf = !sortShelf;
    notifyListeners();
  }

  refreshShelf() async {
    Response response2 = await Util(null).http().get(Common.shelf);
    List decode = response2.data['data'];
    if (decode == null) {
      return;
    }
    List<Book> bs = decode.map((m) => Book.fromJson(m)).toList();
    if (shelf.isNotEmpty) {
      var ids = shelf.map((f) => f.Id).toList();
      bs.forEach((f) {
        if (!ids.contains(f.Id)) {
          _dbHelper.addBooks([f]);
          shelf.add(f);
        }
      });
      for (var i = 0; i < shelf.length; i++) {
        for (var j = 0; j < bs.length; j++) {
          if (shelf[i].Id == bs[j].Id) {
            if (shelf[i].LastChapter != bs[j].LastChapter) {
              shelf[i].UTime = bs[j].UTime;
              shelf[i].LastChapter = bs[j].LastChapter;
              shelf[i].NewChapterCount = 1;
              _dbHelper.updBook(bs[j].LastChapter, 1, bs[j].UTime, shelf[i].Id);
            }
          }
        }
      }
    } else {
      shelf = bs;
      _dbHelper.addBooks(bs);
    }
    notifyListeners();
    saveShelf();
  }

  upTotop(int i) async {
    Book book = shelf[i];
    await _dbHelper.updBookStatus(book.Id, 0);

    shelf.removeAt(i);

    shelf.insert(0, book);
    await _dbHelper.delBook(book.Id);
    await _dbHelper.addBooks([book]);
    notifyListeners();
    // saveShelf();
  }

  dropAccountOut() {
    SpUtil.remove('username');
    SpUtil.remove('login');
    SpUtil.remove('email');
    SpUtil.remove('auth');
    delLocalCache(shelf.map((f) => f.Id.toString()).toList());
    // SpUtil.remove(Common.listbookname);
    shelf = [];
    notifyListeners();
  }

  //删除本地记录
  void delLocalCache(List<String> ids) {
    for (var i = 0; i < ids.length; i++) {
      SpUtil.remove(ids[i]);
      SpUtil.remove('${ids[i]}chapters');

      _dbHelper.delBookAndCps(ids[i]);
    }
  }

  modifyShelf(Book book) {
    var action =
        shelf.map((f) => f.Id).toList().contains(book.Id) ? 'del' : 'add';
    if (action == "add") {
      shelf.insert(0, book);
      _dbHelper.addBooks([book]);
      BotToast.showText(text: "已添加到书架");
    } else if (action == "del") {
      for (var i = 0; i < shelf.length; i++) {
        if (shelf[i].Id == book.Id) {
          shelf.removeAt(i);
        }
      }
      _dbHelper.delBook(book.Id);

      delLocalCache([book.Id]);
      BotToast.showText(text: "已移除出书架");
    }
    if (SpUtil.haveKey("auth")) {
      Util(null).http().get(Common.bookAction + '/${book.Id}/$action');
    }
    saveShelf();
    notifyListeners();
  }

  freshToken() async {
    if (SpUtil.haveKey("username")) {
      Response res = await Util(null).http().get(Common.freshToken);
      var data = res.data;
      if (data['code'] == 200) {
        SpUtil.putString("auth", data['data']['token']);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
