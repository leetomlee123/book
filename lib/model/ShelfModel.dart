import 'dart:convert';

import 'package:book/common/common.dart';

import 'package:book/common/util.dart';
import 'package:book/entity/Book.dart';
import 'package:book/entity/Chapter.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';

class ShelfModel with ChangeNotifier {
  List<Book> shelf = [];
  BuildContext context;
  bool model = false;

  ShelfModel();

  saveShelf() {
    SpUtil.putString(Common.listbookname, jsonEncode(shelf));
  }

  toggleModel() {
    model = !model;
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
            }
          }
        }
      }
    } else {
      shelf = bs;
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
    notifyListeners();
    saveShelf();
  }

  dropAccountOut() {
    SpUtil.remove('username');
    SpUtil.remove('login');
    SpUtil.remove('email');
    SpUtil.remove('auth');
    delLocalCache(shelf.map((f) => f.Id.toString()).toList());
    SpUtil.remove(Common.listbookname);
    shelf = [];
    notifyListeners();
  }

  //删除本地记录
  void delLocalCache(List<String> ids) {
    for (var i = 0; i < ids.length; i++) {
      if (SpUtil.haveKey(ids[i])) {
        List list = jsonDecode(SpUtil.getString('${ids[i]}chapters'));
        List cps = list.map((e) => Chapter.fromJson(e)).toList();
        for (var value in cps) {
          SpUtil.remove(value.id.toString());
          SpUtil.remove('pages${value.id.toString()}');
        }
        SpUtil.remove(ids[i]);
      }
    }
  }

  modifyShelf(Book book) {
    var action =
        shelf.map((f) => f.Id).toList().contains(book.Id) ? 'del' : 'add';
    if (action == "add") {
      BotToast.showText(text:"已添加到书架");
      shelf.insert(0, book);
    } else if (action == "del") {
      for (var i = 0; i < shelf.length; i++) {
        if (shelf[i].Id == book.Id) {
          shelf.removeAt(i);
        }
      }
      BotToast.showText(text:"已移除出书架");

      delLocalCache([book.Id]);
    }
    if (SpUtil.haveKey("auth")) {
      Util(null).http().get(Common.bookAction + '/${book.Id}/$action');
    }
    saveShelf();
    notifyListeners();
  }
}
