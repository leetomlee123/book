import 'package:book/common/DbHelper.dart';
import 'package:book/common/common.dart';
import 'package:book/common/util.dart';
import 'package:book/entity/Book.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';

class ShelfModel with ChangeNotifier {
  List<Book> shelf = [];

  Future<void> setShelf() async {
    shelf = await _dbHelper.getBooks();
  }

  BuildContext context;
  bool model = false;
  DbHelper _dbHelper = DbHelper();

  ShelfModel();

  saveShelf() {
    // SpUtil.putString(Common.listbookname, jsonEncode(shelf));
  }

  toggleModel() {
    model = !model;
    notifyListeners();
  }

  updBookStatus(String bookId) {
    _dbHelper.updBookStatus(bookId,0);
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



  upTotop(Book book) {
    for (var i = 0; i < shelf.length; i++) {
      if (shelf[i].Id == book.Id) {
        shelf.removeAt(i);
        break;
      }
    }
    shelf.insert(0, book);
    _dbHelper.delBook(book.Id);
    _dbHelper.addBooks([book]);
    notifyListeners();
    saveShelf();
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
      _dbHelper.delBook(ids[i]);
      for (var value in SpUtil.getKeys()) {
        if (value.contains("pages")) {
          SpUtil.remove(value);
        }
      }
    }
  }

  modifyShelf(Book book) {
    var action =
        shelf.map((f) => f.Id).toList().contains(book.Id) ? 'del' : 'add';
    if (action == "add") {
      BotToast.showText(text: "已添加到书架");
      shelf.insert(0, book);
      _dbHelper.addBooks([book]);
    } else if (action == "del") {
      for (var i = 0; i < shelf.length; i++) {
        if (shelf[i].Id == book.Id) {
          shelf.removeAt(i);
        }
      }
      _dbHelper.delBook(book.Id);
      BotToast.showText(text: "已移除出书架");

      delLocalCache([book.Id]);
    }
    if (SpUtil.haveKey("auth")) {
      Util(null).http().get(Common.bookAction + '/${book.Id}/$action');
    }
    saveShelf();
    notifyListeners();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _dbHelper.close();
  }
}
