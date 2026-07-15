import 'package:book/common/Screen.dart';
import 'package:book/common/common.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/person/Me.dart';
import 'package:book/widgets/BooksWidget.dart';
import 'package:book/widgets/MyIcon.dart';
import 'package:book/common/local_store.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BookShelf extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _BookShelfState();
  }
}

class _BookShelfState extends State<BookShelf> {
  static final GlobalKey<ScaffoldState> key = GlobalKey();
  @override
  void initState() {
    super.initState();
    if (!SpUtil.containsKey(Common.top_safe_height)) {
      SpUtil.putDouble(Common.top_safe_height, Screen.topSafeHeight);
    }
    if (!SpUtil.containsKey(Common.shimmer_nums)) {
      SpUtil.putInt(
          Common.shimmer_nums,
          (Screen.height -
                  Screen.topSafeHeight -
                  Screen.bottomSafeHeight -
                  60) ~/
              25);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Store.connect<ShelfModel>(
        builder: (context, ShelfModel shelfModel, child) {
      return Scaffold(
        key: key,
          drawer: Drawer(
            child: Me(),
          ),
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.person),
              onPressed: () => key.currentState?.openDrawer(),
              iconSize: 25,
            ),
            elevation: 0,
            centerTitle: true,
            actions: <Widget>[
              MyIcon(Icons.search, () {
                Routes.navigateTo(context, Routes.search,
                    params: {"type": "book", "name": ""});
              }),
              MyIcon(Icons.more_vert, () async {
                String shelfModelName = shelfModel.cover ? "列表模式" : "封面模式";
                final result = await showMenu(
                    context: context,
                    position: RelativeRect.fromLTRB(2000.0, .0, 0.0, 0.0),
                    items: <PopupMenuItem<String>>[
                      PopupMenuItem(
                          value: shelfModelName, child: Text(shelfModelName)),
                      PopupMenuItem(value: "书架整理", child: Text("书架整理"))
                    ]);
                if (result == "封面模式" || result == "列表模式") {
                  shelfModel.toggleModel();
                } else if (result == "书架整理") {
                  Routes.navigateTo(
                    context,
                    Routes.sortShelf,
                  );
                }
              }),
            ],
          ),
          body: BooksWidget(""));
    });
  }
}
