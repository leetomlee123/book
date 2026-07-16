import 'package:book/common/Screen.dart';
import 'package:book/common/app_colors.dart';
import 'package:book/common/common.dart';
import 'package:book/common/local_store.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:book/widgets/BooksWidget.dart';
import 'package:book/widgets/MyIcon.dart';
import 'package:flutter/material.dart';

class BookShelf extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _BookShelfState();
  }
}

class _BookShelfState extends State<BookShelf> {
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
      final dark = Theme.of(context).brightness == Brightness.dark;
      return Scaffold(
        backgroundColor: dark ? AppColors.scaffoldDark : AppColors.scaffold,
        appBar: AppBar(
          title: const Text('书架'),
          leading: null,
          automaticallyImplyLeading: false,
          actions: <Widget>[
            MyIcon(Icons.search, () {
              // Switch to search tab instead of pushing a second Search.
              eventBus.fire(NavEvent(1));
            }),
            MyIcon(Icons.more_vert, () async {
              String shelfModelName = shelfModel.cover ? "列表模式" : "封面模式";
              final result = await showMenu(
                  context: context,
                  position: RelativeRect.fromLTRB(2000.0, .0, 0.0, 0.0),
                  items: <PopupMenuItem<String>>[
                    PopupMenuItem(
                        value: shelfModelName, child: Text(shelfModelName)),
                    const PopupMenuItem(value: "书架整理", child: Text("书架整理"))
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
        body: BooksWidget(""),
      );
    });
  }
}
