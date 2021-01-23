import 'package:book/common/Screen.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ColorModel.dart';
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
      return Store.connect<ColorModel>(
          builder: (context, ColorModel _colorModel, child) {
        return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: shelfModel.sortShelf
                ? null
                : AppBar(
                    backgroundColor: Colors.transparent,
                    // leading: ImageIcon(
                    //   AssetImage("images/vip.png"),
                    //   size: 24,
                    // ),
                    // flexibleSpace: _colorModel.dark?Container():Container(
                    //   decoration: BoxDecoration(
                    //     gradient: LinearGradient(
                    //         colors: [
                    //           // Colors.accents[_colorModel.idx].shade100,
                    //           Colors.accents[_colorModel.idx].shade200,
                    //           Colors.accents[_colorModel.idx].shade400,
                    //         ],
                    //         begin: Alignment.centerRight,
                    //         end: Alignment.centerLeft),
                    //   ),
                    // ),
                    leading: IconButton(
                      color: _colorModel.dark ? Colors.white : Colors.black,
                      icon: ImageIcon(
                        AssetImage("images/account.png"),
                        size: 32.0,
                        color: _colorModel.dark ? Colors.white : Colors.black,
                      ),
                      onPressed: () {
                        eventBus.fire(OpenEvent("p"));
                      },
                    ),
                    elevation: 0,
                    title: Text(
                      '书架',
                      style: TextStyle(
                          color: _colorModel.dark ? Colors.white : Colors.black,
                          ),
                    ),
                    centerTitle: true,
                    actions: <Widget>[
                      IconButton(
                        color: _colorModel.dark ? Colors.white : Colors.black,
                        icon: ImageIcon(
                          AssetImage("images/search.png"),
                          size: 20.0,
                          color: _colorModel.dark ? Colors.white : Colors.black,
                        ),
                        onPressed: () {
                          Routes.navigateTo(context, Routes.search,
                              params: {"type": "book", "name": ""});
                        },
                      ),
                      IconButton(
                        color: _colorModel.dark ? Colors.white : Colors.black,
                        icon: ImageIcon(
                          AssetImage("images/more_vert.png"),
                          size: 25.0,
                          color: _colorModel.dark ? Colors.white : Colors.black,
                        ),
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
                                PopupMenuItem(
                                    value: "书架整理", child: Text("书架整理"))
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
    });
  }

  @override
  bool get wantKeepAlive => true;
}
