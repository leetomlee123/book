import 'package:book/common/Screen.dart';
import 'package:book/entity/Book.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/ReadModel.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/book/ChapterView.dart';
import 'package:book/view/system/BatteryView.dart';
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
  ColorModel _colorModel;

  //背景色数据
  // List<List> bgs = [
  //   [250, 245, 235],
  //   [245, 234, 204],
  //   [230, 242, 230],
  //   [228, 241, 245],
  //   [245, 228, 228],
  // ];
  final GlobalKey<ScaffoldState> _globalKey = new GlobalKey();
  List<String> bgimg = [
    "QR_bg_1.jpg",
    "QR_bg_2.jpg",
    "QR_bg_3.jpg",
    "QR_bg_5.jpg",
    "QR_bg_7.png",
    "QR_bg_8.png",
    "QR_bg_4.jpg",
  ];

  @override
  void initState() {
    setUp();
    super.initState();
  }

  setUp() async {
    eventBus.on<ReadRefresh>().listen((event) {
      readModel.reSetPages();
      readModel.intiPageContent(readModel.book.cur, false);
    });
    eventBus.on<OpenChapters>().listen((event) {
      _globalKey.currentState?.openDrawer();
    });
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    readModel = Store.value<ReadModel>(context);
    _colorModel = Store.value<ColorModel>(context);
    readModel.book = this.widget.book;
    readModel.context = context;
    readModel.getBookRecord();

    if (SpUtil.haveKey('bgIdx')) {
      readModel.bgIdx = SpUtil.getInt('bgIdx');
    }

    readModel.contentH = Screen.height - Screen.topSafeHeight - 60;
    readModel.contentW = Screen.width - 30.0;
    setSystemBar();
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await readModel.saveData();
    await readModel.clear();
    // readModel.pageController?.dispose();
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
                              readModel.sSave = false;

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
              return model.loadOk
                  ? Stack(
                      children: <Widget>[
                        Positioned(
                            left: 0,
                            top: 0,
                            right: 0,
                            bottom: 0,
                            child: Image.asset(
                                Store.value<ColorModel>(context).dark
                                    ? 'images/QR_bg_4.jpg'
                                    : "images/${bgimg[readModel?.bgIdx ?? 0]}",
                                fit: BoxFit.cover)),
                        PageView.builder(
                          controller: model.pageController,
                          physics: AlwaysScrollableScrollPhysics(),
                          itemBuilder: (BuildContext context, int position) {
                            return readModel.allContent[position];
                          },
                          //条目个数
                          itemCount: (readModel.prePage?.pageOffsets?.length ??
                                  0) +
                              (readModel.curPage?.pageOffsets?.length ?? 0) +
                              (readModel.nextPage?.pageOffsets?.length ?? 0),
                          onPageChanged: (idx) => readModel.changeChapter(idx),
                        ),

                        model.showMenu ? Menu() : Container(),
                        model.showMenu
                            ? Positioned(
                                child: reloadCurChapterWidget(),
                                bottom: 250,
                                right: 20,
                              )
                            : Container()
                      ],
                    )
                  : Container();
            })));
  }

  Widget _loadingPage() {
    return Center(
      child: Text("正在加载..."),
    );
  }

  Widget reloadCurChapterWidget() {
    return Opacity(
      opacity: 0.9,
      child: GestureDetector(
        child: Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: Colors.grey, borderRadius: BorderRadius.circular(25)),
          child: Icon(
            Icons.refresh,
            color: Colors.white,
          ),
        ),
        onTap: () {
          readModel.reloadCurrentPage();
        },
      ),
    );
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
