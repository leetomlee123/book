import 'package:book/common/Screen.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:book/widgets/BooksWidget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BookShelf extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new _BookShelfState();
  }
}

class _BookShelfState extends State<BookShelf>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Store.connect<ShelfModel>(
        builder: (context, ShelfModel shelfModel, child) {
      return Scaffold(
          appBar: shelfModel.sortShelf
              ? null
              : AppBar(
                  leading: IconButton(
                    icon: Icon(Icons.person),
                    onPressed: () {
                      eventBus.fire(OpenEvent("p"));
                    },
                  ),
                  elevation: 0,
                  title: Text(
                    '书架',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  centerTitle: true,
                  actions: <Widget>[
                    IconButton(
                      icon: Icon(Icons.search),
                      onPressed: () {
                        Routes.navigateTo(context, Routes.search,
                            params: {"type": "book", "name": ""});
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.more_vert),
                      onPressed: () async {
                        String shelfModelName =
                            shelfModel.model ? "列表模式" : "封面模式";
                        final result = await showMenu(
                            context: context,
                            position: RelativeRect.fromLTRB(
                                2000.0, Screen.navigationBarHeight, 0.0, 0.0),
                            items: <PopupMenuItem<String>>[
                              PopupMenuItem(
                                  value: shelfModelName,
                                  child: Text(shelfModelName)),
                              PopupMenuItem(value: "书架整理", child: Text("书架整理"))
                            ]);
                        if (result == "封面模式" || result == "列表模式") {
                          shelfModel.toggleModel();
                        } else if (result == "书架整理") {
                          // shelfModel.sortShelfModel();
                          Routes.navigateTo(
                            context,
                            Routes.sortShelf,
                          );
                        }
                      },
                    )
                  ],
                ),
          body: BooksWidget(""));
    });
  }

  @override
  bool get wantKeepAlive => true;
}
