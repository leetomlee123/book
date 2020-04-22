import 'dart:math';

import 'package:book/common/common.dart';
import 'package:book/common/util.dart';
import 'package:book/entity/BookInfo.dart';
import 'package:book/entity/HotBook.dart';
import 'package:book/entity/SearchItem.dart';
import 'package:book/view/BookDetail.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class SearchModel with ChangeNotifier {
  List<String> searchHistory = new List();
  BuildContext context;
  bool showResult = false;
  List<SearchItem> bks = [];
  List<Widget> hot = [];
  int page = 1;
  int size = 10;
  var word = "";
  var temp = "";
  RefreshController refreshController =
      RefreshController(initialRefresh: false);
  TextEditingController controller;

  List<Color> colors = Colors.accents;

  getSearchData() async {
    if (temp == "") {
      temp = word;
    } else {
      if (temp != word) {
        page = 1;
      }
    }
    //收起键盘
    FocusScope.of(context).requestFocus(FocusNode());
    var ctx;
    if (bks.length == 0) {
      ctx = context;
    }
    var url = '${Common.search}?key=$word&page=$page&size=$size';

    Response res = await Util(ctx).http().get(url);
    List data = res.data['data'];
    if (data == null) {
      refreshController.loadNoData();
    } else {
      data.forEach((f) {
        bks.add(SearchItem.fromJson(f));
      });
    }
  }

  void onRefresh() async {
    bks = [];
    page = 1;
    getSearchData();
    refreshController.refreshCompleted();
    notifyListeners();
  }

  void onLoading() async {
    page += 1;
    getSearchData();
    refreshController.loadComplete();
    notifyListeners();
  }

  toggleShowResult() {
    showResult = !showResult;
    notifyListeners();
  }

  List<Widget> getHistory() {
    List<Widget> wds = [];
    for (var value in searchHistory) {
      wds.add(GestureDetector(
        onTap: () {
          word = value;
          controller.text = value;
          search(value);
          notifyListeners();
        },
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
          decoration: BoxDecoration(
              color: colors[Random().nextInt(colors.length)],
              borderRadius: BorderRadius.all(Radius.circular(5))),
          child: Container(
            margin: EdgeInsets.all(8),
            child: Text(value),
          ),
        ),
      ));
//      wds.add(GestureDetector(
//        onTap: () {
//          word = value;
//          controller.text = value;
//          search(value);
//          notifyListeners();
//        },
////        child: Card(
////          shape: const RoundedRectangleBorder(
////              borderRadius: BorderRadius.all(Radius.circular(14.0))),
////          color: colors[Random().nextInt(colors.length)],
////          child: ListTile(
////            leading: Icon(Icons.history),
////            title: Text(value),
////            trailing: IconButton(
////              icon: Icon(Icons.close),
////              onPressed: () {
////                searchHistory.remove(value);
////                notifyListeners();
////              },
////            ),
////          ),
////        ),
//        child: Container(
//          decoration: BoxDecoration(
//            border: Border.all(color: Colors.white, width: 1.0), //灰色的一层边框
//            color: colors[Random().nextInt(colors.length)],
//            borderRadius: BorderRadius.all(Radius.circular(25.0)),
//          ),
//          alignment: Alignment.center,
//          width: 100,
////          constraints: BoxConstraints(
////            minWidth: 180,
////          ),
//          child: Center(
//            child: Text(
//              value,
//              maxLines: 1,
//              overflow: TextOverflow.ellipsis,
//            ),
//          ),
//        ),
//      ));
    }

    return wds;
  }

  setHistory(String value) {
    if (value.isEmpty) {
      return;
    }
    for (var ii = 0; ii < searchHistory.length; ii++) {
      if (searchHistory[ii] == value) {
        searchHistory.removeAt(ii);
      }
    }
    searchHistory.insert(0, value);
    if (SpUtil.haveKey('history')) {
      SpUtil.remove('history');
    }
    SpUtil.putStringList('history', searchHistory);
  }

  initHistory() {
    if (SpUtil.haveKey('history')) {
      searchHistory = SpUtil.getStringList('history');
    }
    notifyListeners();
  }

  clearHistory() {
    SpUtil.remove('history');
    searchHistory = [];
    notifyListeners();
  }

  reset() {
    if (word.isEmpty) {
      return;
    }
    word = "";
    page = 1;
    showResult = false;
    notifyListeners();
  }

  Future<void> search(String w) async {
    if (w.isEmpty) {
      return;
    }
    bks = [];
    showResult = true;
    word = w;
    await getSearchData();
    setHistory(w);
    notifyListeners();
  }

  Future<void> initHot() async {
    hot = [];
    Response res = await Util(null).http().get(Common.hot);
    List data = res.data['data'];
    List<HotBook> hbs = data.map((f) => HotBook.fromJson(f)).toList();
    for (var i = 0; i < hbs.length; i++) {
      hot.add(GestureDetector(
        child: ListTile(
          leading: Text((i + 1).toString()),
          title: Text(hbs[i].Name,overflow: TextOverflow.ellipsis,),
          trailing: Text(hbs[i].Hot.toString(),overflow: TextOverflow.ellipsis,),
        ),
        onTap: () async {
          String url = Common.detail + '/${hbs[i].Id}';
          Response future = await Util(context).http().get(url);
          var d = future.data['data'];
          BookInfo b = BookInfo.fromJson(d);
          Navigator.of(context).push(MaterialPageRoute(
              builder: (BuildContext context) => BookDetail(b)));
        },
      ));
    }
    notifyListeners();
  }
}
