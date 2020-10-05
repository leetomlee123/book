import 'package:book/entity/Book.dart';
import 'package:book/entity/BookInfo.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/ReadModel.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/book/ChapterView.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_statusbar_manager/flutter_statusbar_manager.dart';

import 'Menu.dart';

class ReadBook extends StatefulWidget {
  final Book book;

  ReadBook(this.book);

  @override
  State<StatefulWidget> createState() {
    return _ReadBookState();
  }
}

class _ReadBookState extends State<ReadBook> with WidgetsBindingObserver {
  ReadModel readModel;

  //背景色数据
  // List<List> bgs = [
  //   [250, 245, 235],
  //   [245, 234, 204],
  //   [230, 242, 230],
  //   [228, 241, 245],
  //   [245, 228, 228],
  // ];
  final GlobalKey<ScaffoldState> _globalKey = new GlobalKey();

  @override
  void initState() {
    eventBus.on<ReadRefresh>().listen((event) {
      readModel.reSetPages();
      readModel.intiPageContent(readModel.bookTag.cur, false);
    });
    eventBus.on<OpenChapters>().listen((event) {
      _globalKey.currentState?.openDrawer();
    });
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    var widgetsBinding = WidgetsBinding.instance;
    widgetsBinding.addPostFrameCallback((callback) async {
      readModel = Store.value<ReadModel>(context);
      readModel.book = this.widget.book;
      readModel.context = context;
      readModel.getBookRecord();
      if (SpUtil.haveKey('fontSize')) {
        readModel.fontSize = SpUtil.getDouble('fontSize');
      }
      if (SpUtil.haveKey('bgIdx')) {
        readModel.bgIdx = SpUtil.getInt('bgIdx');
      }
      readModel.contentH = ScreenUtil.getScreenH(context) -
          ScreenUtil.getStatusBarH(context) -
          60;
      readModel.contentW =
          (ScreenUtil.getScreenW(context) - 20).floorToDouble();
    });
    setSystemBar();
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await readModel.saveData();
    await readModel.clear();
    WidgetsBinding.instance.removeObserver(this);
    print('dispose');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    readModel.saveData();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          if (!Store.value<ShelfModel>(context)
              .shelf
              .map((f) => f.Id)
              .toList()
              .contains(readModel.book.Id)) {
            var showDialog2 = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                      content: Text('是否加入本书'),
                      actions: <Widget>[
                        FlatButton(
                            onPressed: () {
                              Navigator.pop(context);
               
                              Store.value<ShelfModel>(context)
                                  .modifyShelf(this.widget.book);
                            },
                            child: Text('确定')),
                        FlatButton(
                            onPressed: () {
                              Store.value<ShelfModel>(context)
                                  .delLocalCache([this.widget.book.Id]);
                              Navigator.pop(context);
                            },
                            child: Text('取消')),
                      ],
                    ));
          }
          return true;
        },
        child: Scaffold(
            key: _globalKey,
            drawer: Drawer(
              child: ChapterView(),
            ),
            body: Store.connect<ReadModel>(
                builder: (context, ReadModel model, child) {
              return (model?.loadOk ?? false)
                  ? Stack(
                      children: <Widget>[
                        model.readView(),
                        model.showMenu ? Menu() : Container()
                      ],
                    )
                  : Container();
            })));
  }

  void setSystemBar() {
    var dark = Store.value<ColorModel>(context).dark;
    if (dark) {
      FlutterStatusbarManager.setStyle(StatusBarStyle.DARK_CONTENT);
    } else {
      FlutterStatusbarManager.setStyle(StatusBarStyle.LIGHT_CONTENT);
    }
  }
}
