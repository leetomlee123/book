import 'dart:ui' as ui;

import 'package:book/common/ReadSetting.dart';
import 'package:book/common/Screen.dart';
import 'package:book/common/text_composition.dart';
import 'package:book/entity/Book.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/ReadModel.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/book/Menu.dart';
import 'package:book/view/system/BatteryView.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_statusbar_manager/flutter_statusbar_manager.dart';

class ReadBook extends StatefulWidget {
  final Book book;
  final bool reading;

  ReadBook(this.book, {this.reading = false});

  @override
  State<StatefulWidget> createState() {
    return _ReadBookState();
  }
}

class _ReadBookState extends State<ReadBook> with WidgetsBindingObserver {
  Widget body;
  ReadModel readModel;
  ColorModel colorModel;
  TextComposition textComposition;
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
    readModel = Store.value<ReadModel>(context);
    eventBus.on<ReadRefresh>().listen((event) {
      readModel.reSetPages();
      readModel.initPageContent(readModel.book.cur, true);
    });

    WidgetsBinding.instance.addObserver(this);
    eventBus.on<ZEvent>().listen((event) {
      move(event.isPage, event.offset);
    });

    colorModel = Store.value<ColorModel>(context);
    readModel.book = this.widget.book;
    readModel.context = context;
    readModel.getBookRecord();

    if (SpUtil.haveKey('bgIdx')) {
      readModel.bgIdx = SpUtil.getInt('bgIdx');
    }
    readModel.topSafeHeight = Screen.topSafeHeight;


    // readModel.contentH =
    //     Screen.height - Screen.topSafeHeight - 60 - Screen.bottomSafeHeight;
    // ReadSetting.setTempH(Screen.height - Screen.topSafeHeight - 60 - Screen.bottomSafeHeight);
    // ReadSetting.setTempW(Screen.width - 30.0);
    FlutterStatusbarManager.setFullscreen(true);
  }

  @override
  void dispose() async {
    super.dispose();
    readModel?.pageController?.dispose();
    readModel?.listController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    readModel.saveData();
  }

  @override
  Future<void> deactivate() async {
    super.deactivate();
    FlutterStatusbarManager.setFullscreen(false);
    await readModel.saveData();
    readModel.clear();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(onWillPop: () async {
      if (!Store.value<ShelfModel>(context)
          .exitsInBookShelfById(readModel.book.Id)) {
        await confirmAddToShelf(context);
      }
      return true;
    }, child: Scaffold(body:
        Store.connect<ReadModel>(builder: (context, ReadModel model, child) {
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
                            : "images/${bgImg[model?.bgIdx ?? 0]}",
                        fit: BoxFit.cover)),
                //内容
                // PageTurn(key: GlobalKey<PageTurnState>(),children: model.allContent,o),
                GestureDetector(
                  child: model.isPage
                      ? PageView.builder(
                          controller: model.pageController,
                          physics: AlwaysScrollableScrollPhysics(),
                          itemBuilder: (BuildContext context, int position) {
                            return model.allContent[position];
                          },
                          //条目个数
                          itemCount: model?.allContent?.length??0,
                          onPageChanged: (page) => model.changeChapter(page),
                        )
                      : Container(
                          width: Screen.width,
                          height: Screen.height,
                          child: Column(
                            children: [
                              SizedBox(
                                height: model.topSafeHeight,
                              ),
                              Container(
                                height: 30,
                                alignment: Alignment.centerLeft,
                                padding: EdgeInsets.only(left: 20),
                                child: Text(
                                  model.readPages[model.cursor].chapterName,
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
                                  child:
                                      NotificationListener<ScrollNotification>(
                                    onNotification:
                                        (ScrollNotification notification) {
                                      if (notification.depth == 0 &&
                                          notification
                                              is ScrollEndNotification) {
                                        model.notifyOffset();
                                      }
                                      return false;
                                    },
                                    child: SingleChildScrollView(
                                      child: Column(
                                        children: model.allContent,
                                      ),
                                      controller: model.listController,
                                    ),
                                  )
                                  // child: ListView.builder(
                                  //   itemCount: model.readPages.length,
                                  //   itemBuilder: (BuildContext context, int index) {
                                  //     return model.allContent[index];
                                  //   },
                                  //   controller: model.listController,
                                  //   cacheExtent:
                                  //       model.readPages[model.cursor].height,
                                  // ),
                                  ),
                              Store.connect<ReadModel>(builder:
                                  (context, ReadModel _readModel, child) {
                                return Container(
                                  height: 30,
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child: Row(
                                    children: <Widget>[
                                      BatteryView(
                                        electricQuantity:
                                            _readModel.electricQuantity,
                                      ),
                                      SizedBox(
                                        width: 4,
                                      ),
                                      Text(
                                        '${DateUtil.formatDate(DateTime.now(), format: DateFormats.h_m)}',
                                        style: TextStyle(
                                          fontSize: 12 / Screen.textScaleFactor,
                                          color: colorModel.dark
                                              ? Color(0x8FFFFFFF)
                                              : Colors.black54,
                                        ),
                                      ),
                                      Spacer(),
                                      Text(
                                        '${_readModel.percent.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 12 / Screen.textScaleFactor,
                                          color: colorModel.dark
                                              ? Color(0x8FFFFFFF)
                                              : Colors.black54,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      // Expanded(child: Container()),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          )),
                  onTapDown: (TapDownDetails details) =>
                      model.tapPage(context, details),
                ),
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
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Store.value<ShelfModel>(context)
                          .modifyShelf(this.widget.book);
                    },
                    child: Text('确定')),
                TextButton(
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

  void move(bool isPage, double offset) {
    var widgetsBinding = WidgetsBinding.instance;

    widgetsBinding.addPostFrameCallback((callback) {
      if (isPage) {
        int ix = readModel.prePage?.pageOffsets ?? 0;
        readModel.pageController.jumpToPage(ix);
      } else {
        if (offset == 0.0) {
          readModel.listController
              .jumpTo((readModel.ladderH[readModel.cursor - 1]));
        } else {
          readModel.listController.jumpTo(offset);
        }
      }
    });
  }
}
