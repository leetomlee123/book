import 'package:book/common/DbHelper.dart';
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
  BookInfo _bookInfo;

  ReadBook(this._bookInfo);

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
      readModel.bookInfo = this.widget._bookInfo;
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
              .contains(readModel.bookInfo.Id)) {
            var showDialog2 = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                      content: Text('是否加入本书'),
                      actions: <Widget>[
                        FlatButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Book book = new Book(
                                  "",
                                  "",
                                  0,
                                  readModel.bookInfo.Id,
                                  readModel.bookInfo.Name,
                                  "",
                                  readModel.bookInfo.Author,
                                  readModel.bookInfo.Img,
                                  readModel.bookInfo.LastChapterId,
                                  readModel.bookInfo.LastChapter,
                                  readModel.bookInfo.LastTime);
                              Store.value<ShelfModel>(context)
                                  .modifyShelf(book);
                            },
                            child: Text('确定')),
                        FlatButton(
                            onPressed: () {
                              Store.value<ShelfModel>(context)
                                  .delLocalCache([this.widget._bookInfo.Id]);
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
