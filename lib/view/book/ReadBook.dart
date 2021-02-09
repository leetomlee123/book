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
  Widget body;
  ReadModel readModel;
  ColorModel colorModel;
  final GlobalKey<ScaffoldState> _globalKey = new GlobalKey();
  List<String> bgImg = [
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
      readModel.intiPageContent(readModel.book.cur, true);
    });
    eventBus.on<OpenChapters>().listen((event) {
      _globalKey.currentState?.openDrawer();
    });
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    readModel = Store.value<ReadModel>(context);
    colorModel = Store.value<ColorModel>(context);
    readModel.book = this.widget.book;
    readModel.context = context;
    readModel.getBookRecord();

    if (SpUtil.haveKey('bgIdx')) {
      readModel.bgIdx = SpUtil.getInt('bgIdx');
    }

    readModel.contentH =
        Screen.height - Screen.topSafeHeight - 60 - Screen.bottomSafeHeight;
    readModel.contentW = Screen.width - 30.0;
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
              .exitsInBookShelfById(readModel.book.Id)) {
            await confirmAddToShelf(context);
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
                        //背景
                        Positioned(
                            left: 0,
                            top: 0,
                            right: 0,
                            bottom: 0,
                            child: Image.asset(
                                Store.value<ColorModel>(context).dark
                                    ? 'images/QR_bg_4.jpg'
                                    : "images/${bgImg[readModel?.bgIdx ?? 0]}",
                                fit: BoxFit.cover)),
                        //内容
                        model.isPage
                            ? PageView.builder(
                                controller: model.pageController,
                                physics: AlwaysScrollableScrollPhysics(),
                                itemBuilder:
                                    (BuildContext context, int position) {
                                  return readModel.allContent[position];
                                },
                                //条目个数
                                itemCount: (readModel
                                            .prePage?.pageOffsets?.length ??
                                        0) +
                                    (readModel.curPage?.pageOffsets?.length ??
                                        0) +
                                    (readModel.nextPage?.pageOffsets?.length ??
                                        0),
                                onPageChanged: (idx) =>
                                    readModel.changeChapter(idx),
                              )
                            : Container(
                                width: Screen.width,
                                height: Screen.height,
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: Screen.topSafeHeight,
                                    ),
                                    Container(
                                      height: 30,
                                      alignment: Alignment.centerLeft,
                                      padding: EdgeInsets.only(left: 20),
                                      child: Text(
                                        model.curPage.chapterName,
                                        style: TextStyle(
                                          fontSize: 12 / Screen.textScaleFactor,
                                          color: colorModel.dark
                                              ? Color(0x8FFFFFFF)
                                              : Colors.black54,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      width: Screen.width,
                                      height: model.contentH,
                                      child: ListView(
                                        children: model.allContent,
                                        controller: model.listController,
                                      ),
                                    ),
                                    Container(
                                      height: 30,
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 20),
                                      child: Row(
                                        children: <Widget>[
                                          BatteryView(
                                            electricQuantity:
                                                model.electricQuantity,
                                          ),
                                          SizedBox(
                                            width: 4,
                                          ),
                                          Text(
                                            '${DateUtil.formatDate(DateTime.now(), format: DateFormats.h_m)}',
                                            style: TextStyle(
                                              fontSize:
                                                  12 / Screen.textScaleFactor,
                                              color: colorModel.dark
                                                  ? Color(0x8FFFFFFF)
                                                  : Colors.black54,
                                            ),
                                          ),
                                          Spacer(),

                                          // Expanded(child: Container()),
                                          Text(
                                            '50%',
                                            style: TextStyle(
                                              fontSize:
                                                  12 / Screen.textScaleFactor,
                                              color: colorModel.dark
                                                  ? Color(0x8FFFFFFF)
                                                  : Colors.black54,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                )),
                        //菜单
                        Offstage(offstage: !model.showMenu, child: Menu()),
                      ],
                    )
                  : Container();
            })));
  }

  Future confirmAddToShelf(BuildContext context) async {
    await showDialog(
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

  void setSystemBar() {
    var dark = Store.value<ColorModel>(context).dark;
    if (dark) {
      FlutterStatusbarManager.setStyle(StatusBarStyle.DARK_CONTENT);
    } else {
      FlutterStatusbarManager.setStyle(StatusBarStyle.LIGHT_CONTENT);
    }
  }
}
