import 'package:book/common/Http.dart';
import 'package:book/common/common.dart';
import 'package:book/entity/Update.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/system/UpdateDialog.dart';
import 'package:book/widgets/BooksWidget.dart';
import 'package:book/widgets/MyIcon.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';

class BookShelf extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new _BookShelfState();
  }
}

class _BookShelfState extends State<BookShelf> {
  @override
  void initState() {
    super.initState();
    _checkUpdate();
  }

  var key = UniqueKey();
  Future<void> _checkUpdate() async {
    Response response = await HttpUtil().http().get(Common.update);
    var data = response.data['data'];
    Update update = Update.fromJson(data);
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    String version = packageInfo.version;
    if (int.parse(update.version.replaceAll(".", "")) >
        int.parse(version.replaceAll(".", ""))) {
      BotToast.showWidget(
          toastBuilder: (context) {
            return Center(
              child: UpdateDialog(update),
            );
          },
          key: key);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Store.connect<ShelfModel>(
        builder: (context, ShelfModel shelfModel, child) {
      return Scaffold(
          appBar: AppBar(
            leading: MyIcon(Icons.person, () {
              eventBus.fire(OpenEvent("p"));
            }),
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
