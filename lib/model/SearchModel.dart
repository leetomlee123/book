import 'dart:convert';

import 'package:book/common/common.dart';
import 'package:book/common/Http.dart';
import 'package:book/entity/BookInfo.dart';
import 'package:book/entity/GBook.dart';
import 'package:book/entity/HotBook.dart';
import 'package:book/entity/SearchItem.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class SearchModel with ChangeNotifier {
  List<String> searchHistory = new List();
  bool isBookSearch = false;
  BuildContext context;
  bool showResult = false;
  List<SearchItem> bks = [];
  List<GBook> mks = [];
  List<Widget> hot = [];
  List<Widget> showHot = [];
  int idx = 0;
  bool loading = false;

  // ignore: non_constant_identifier_names
  String store_word = "";
  int page = 1;
  int size = 10;
  var word = "";
  var temp = "";
  RefreshController refreshController =
      RefreshController(initialRefresh: false);
  TextEditingController controller;

  List<Color> colors = Colors.accents;
  clear1() {
    searchHistory = [];
    page = 1;
    size = 10;
    notifyListeners();
  }

  clear() {
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

  getSearchData() async {
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
    FocusScope.of(context).requestFocus(FocusNode());
    var ctx;
    if (bks.length == 0) {
      ctx = context;
    }
    if (isBookSearch) {
//      var url = '${Common.search}/$word/$page';
      var url = '${Common.search}?key=$word&page=$page&size=$size';
      Response res = await HttpUtil(showLoading: bks.isEmpty).http().get(url);
      var d = res.data;
      List data = d['data'];
      // ignore: null_aware_in_condition
      if (data?.isEmpty ?? true) {
        refreshController.loadNoData();
      } else {
        for (var d in data) {
          bks.add(SearchItem.fromJson(d));
        }
        refreshController.loadComplete();
      }
      print(bks.length);
    } else {
//    /movies
//       var url = '${Common.movie_search}/$word/search/$page/tv';
//
//       Response res = await HttpUtil(showLoading: true).http().get(url);
//       List data = res.data;
//       if (data?.isEmpty ?? true) {
//         refreshController.loadNoData();
//       } else {
//         for (var d in data) {
//           mks.add(GBook.fromJson(d));
//         }
//         refreshController.loadComplete();
//       }
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

  deleteHistoryItem(String source) {
    for (var i = 0; i < searchHistory.length; i++) {
      if (source == searchHistory[i]) {
        searchHistory.removeAt(i);
      }
    }
    SpUtil.putStringList(store_word, searchHistory);
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
        child: Chip(label: Text(value)),
        // child: ListTile(
        //   leading: Icon(Icons.update),
        //   title: Text(value),
        //   trailing: IconButton(
        //     icon: Icon(Icons.clear),
        //     onPressed: () {
        //       deleteHistoryItem(value);
        //     },
        //   ),
        // ),
//        child: Container(
//          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
//          decoration: BoxDecoration(
//              color: colors[Random().nextInt(colors.length)],
//              borderRadius: BorderRadius.all(Radius.circular(5))),
//          child: Container(
//            margin: EdgeInsets.all(8),
//            child: Text(value),
//          ),
//        ),
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
    if (SpUtil.haveKey(store_word)) {
      SpUtil.remove(store_word);
    }
    SpUtil.putStringList(store_word, searchHistory);
  }

  initHistory() {
    if (SpUtil.haveKey(store_word)) {
      searchHistory = SpUtil.getStringList(store_word);
    }
    notifyListeners();
  }

  clearHistory() {
    SpUtil.remove(store_word);
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
    mks = [];
    showResult = true;
    word = w;
    loading = true;
    await getSearchData();
    loading = false;
    setHistory(w);
    notifyListeners();
  }

  Future<void> initBookHot() async {
    hot = [];
    Response res = await HttpUtil().http().get(Common.hot);
    List data = res.data['data'];
    List<HotBook> hbs = data.map((f) => HotBook.fromJson(f)).toList();
    for (var i = 0; i < hbs.length; i++) {
      hot.add(GestureDetector(
        child: Chip(
          label: Text(hbs[i].Name),
        ),
        onTap: () async {
          String url = Common.detail + '/${hbs[i].Id}';
          Response future = await HttpUtil(showLoading: true).http().get(url);
          var d = future.data['data'];
          BookInfo b = BookInfo.fromJson(d);
          Routes.navigateTo(
            context,
            Routes.detail,
            params: {
              'detail': jsonEncode(b),
            },
          );
        },
      ));
    }
    notifyListeners();
  }

  List<Widget> showFire(int hot) {
    var value = Store.value<ColorModel>(context);
    List<Widget> wds = [];
    int i = 1;
    if (hot > 500) {
      i = 3;
    } else if (hot > 100 && hot < 500) {
      i = 2;
    }
    for (int i1 = 0; i1 < i; i1++) {
      wds.add(ImageIcon(
        AssetImage(
          "images/hot.png",
        ),
        size: 20.0,
        color: value.dark ? Colors.white : value.theme.primaryColor,
      ));
    }
    return wds;
  }

  getHot() {
    if (hot.isNotEmpty) {
      showHot = [];
      var j = 0;
      if (((idx * 10) + 9) >= hot.length - 1) {
        j = hot.length - 1;
        idx = 0;
      } else {
        j = (idx * 10 + 9);
        idx += 1;
      }
      for (var i = j - 9; i <= j; i++) {
        showHot.add(hot[i]);
      }
    }
    notifyListeners();
  }

  Future<void> initMovieHot() async {
    hot = [];
    // Response res = await HttpUtil().http().get(Common.movie_hot);
    // List data = res.data;
    // List<GBook> hbs = data.map((f) => GBook.fromJson(f)).toList();
    // for (var i = 0; i < hbs.length; i++) {
    //   hot.add(GestureDetector(
    //     child: Chip(
    //       label: Text(hbs[i].name),
    //     ),
    //     onTap: () async {
    //       Routes.navigateTo(context, Routes.vDetail,
    //           params: {"gbook": jsonEncode(hbs[i])});
    //     },
    //   ));
    // }
    notifyListeners();
  }

  Widget item(String name) {
    return Store.connect<ColorModel>(
        builder: (context, ColorModel data, child) {
      return Container(
        alignment: Alignment(0, 0),
        height: 38,
        width: (ScreenUtil.getScreenW(context) - 40) / 2,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
          border: Border.all(
              width: 1,
              color: data.dark ? Colors.white : Theme.of(context).primaryColor),
        ),
        child: Text(
          name,
          overflow: TextOverflow.ellipsis,
        ),
      );
    });
  }
}
