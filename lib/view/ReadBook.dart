import 'dart:convert';

import 'package:book/common/common.dart';
import 'package:book/common/util.dart';
import 'package:book/entity/Book.dart';
import 'package:book/entity/BookInfo.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/ReadModel.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/ChapterView.dart';
import 'package:book/view/MyBottomSheet.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_statusbar_manager/flutter_statusbar_manager.dart';

class ReadBook extends StatefulWidget {
  BookInfo _bookInfo;

  ReadBook(this._bookInfo);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _ReadBookState();
  }
}

class _ReadBookState extends State<ReadBook> with WidgetsBindingObserver {
  ReadModel readModel;

  //背景色数据
  List<List> bgs = [
    [250, 245, 235],
    [245, 234, 204],
    [230, 242, 230],
    [228, 241, 245],
    [245, 228, 228],
  ];
  final GlobalKey<ScaffoldState> _globalKey = new GlobalKey();

  @override
  void initState() {
    eventBus.on<ReadRefresh>().listen((event) {
      readModel.intiPageContent(readModel.bookTag.cur, false);
    });
    // TODO: implement initState
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
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    readModel.saveData();
    readModel.clear();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    readModel.saveData();
  }

  Widget readView() {
    return Store.connect<ColorModel>(
        builder: (context, ColorModel model, child) {
      return Container(
          decoration: model.dark
              ? null
              : BoxDecoration(
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(
                        readModel.bgimg[readModel.bgIdx]),
                    fit: BoxFit.cover,
                  ),
                ),
          color: model.dark ? Color.fromRGBO(31, 31, 31, 1) : null,
          child: readModel.isPage
              ? PageView.builder(
                  controller: readModel.pageController,
                  physics: AlwaysScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    return readModel.allContent[index];
                  },
                  //条目个数
                  itemCount: (readModel.prePage?.pageOffsets?.length ?? 0) +
                      (readModel.curPage?.pageOffsets?.length ?? 0) +
                      (readModel.nextPage?.pageOffsets?.length ?? 0),
                  onPageChanged: (idx) => readModel.changeChapter(idx),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  controller: readModel.listController,
                  itemBuilder: (BuildContext context, int index) {
                    return readModel.allContent[index];
                  }));
    });
  }

  Widget _createDialog(
      String _confirmContent, Function sureFunction, Function cancelFunction) {
    return AlertDialog(
      content: Text(_confirmContent),
      actions: <Widget>[
        FlatButton(onPressed: sureFunction, child: Text('确定')),
        FlatButton(onPressed: cancelFunction, child: Text('取消')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build

    return Store.connect<ReadModel>(builder: (context, ReadModel model, child) {
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
            body: Stack(
              children: <Widget>[
                readModel?.loadOk ?? false ? readView() : Container(),
                model.showMenu
                    ? Container(
                        color: Colors.transparent,
                        child: Column(
                          children: <Widget>[
                            Container(
                              child: AppBar(
                                backgroundColor:
                                    Store.value<ColorModel>(context)
                                        .theme
                                        .primaryColor,
                                title: Text('${model.bookTag.bookName ?? ""}'),
                                centerTitle: true,
                                leading: IconButton(
                                  icon: Icon(Icons.arrow_back),
                                  onPressed: () {
                                    model.toggleShowMenu();
                                  },
                                ),
                                elevation: 0,
                                actions: <Widget>[
                                  IconButton(
                                    icon: Icon(Icons.refresh),
                                    onPressed: () {
                                      readModel.reloadCurrentPage();
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.info),
                                    onPressed: () async {
                                      String url = Common.detail +
                                          '/${model.bookInfo.Id}';
                                      Response future =
                                          await Util(context).http().get(url);
                                      var d = future.data['data'];
                                      BookInfo bookInfo = BookInfo.fromJson(d);
                                      Routes.navigateTo(context, Routes.detail,
                                          params: {
                                            "detail": jsonEncode(bookInfo)
                                          });
                                    },
                                  )
                                ],
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                child: Opacity(
                                  opacity: 1,
                                  child: Container(
                                    width: double.infinity,
                                  ),
                                ),
                                onTap: () {
                                  model.toggleShowMenu();
                                  if (model.font) {
                                    model.reCalcPages();
                                  }
                                },
                              ),
                            ),
                            Store.connect<ColorModel>(builder:
                                (context, ColorModel colorModel, child) {
                              return Theme(
                                child: Container(
                                  color: colorModel.theme.primaryColor,
                                  height: 120,
                                  width: double.infinity,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          GestureDetector(
                                            child: Container(
                                              child: Icon(
                                                Icons.arrow_back_ios,
                                                color: Colors.white,
                                              ),
                                              width: 70,
                                            ),
                                            onTap: () {
                                              model.bookTag.cur -= 1;
                                              model.intiPageContent(
                                                  model.bookTag.cur, true);
                                            },
                                          ),
                                          Expanded(
                                            child: Container(
                                              child: Slider(
                                                activeColor: Colors.white,
                                                inactiveColor: Colors.white70,
                                                value: model.value,
                                                max: (model.chapters.length - 1)
                                                    .toDouble(),
                                                min: 0.0,
                                                onChanged: (newValue) {
                                                  int temp = newValue.round();
                                                  model.bookTag.cur = temp;
                                                  model.value = temp.toDouble();
                                                  model.intiPageContent(
                                                      model.bookTag.cur, true);
                                                },
                                                label:
                                                    '${model.chapters[model.bookTag.cur].name} ',
                                                semanticFormatterCallback:
                                                    (newValue) {
                                                  return '${newValue.round()} dollars';
                                                },
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            child: Container(
                                              child: Icon(
                                                Icons.arrow_forward_ios,
                                                color: Colors.white,
                                              ),
                                              width: 70,
                                            ),
                                            onTap: () {
                                              model.bookTag.cur += 1;
                                              model.intiPageContent(
                                                  model.bookTag.cur, true);
                                            },
                                          ),
                                        ],
                                      ),
                                      buildBottomMenus(colorModel, model)
                                    ],
                                  ),
                                ),
                                data: colorModel.theme,
                              );
                            })
                          ],
                        ),
                      )
                    : Container()
              ],
            )),
      );
    });
  }

  buildBottomMenus(ColorModel colorModel, ReadModel readModel) {
    return Theme(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          buildBottomItem('目录', Icons.menu),
          GestureDetector(
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: ScreenUtil.getScreenW(context) / 4,
                padding: EdgeInsets.symmetric(vertical: 7),
                child: Column(
                  children: <Widget>[
                    ImageIcon(
                      colorModel.dark
                          ? AssetImage("images/sun.png")
                          : AssetImage("images/moon.png"),
                      color: Colors.white,
                    ),
                    SizedBox(height: 5),
                    Text(colorModel.dark ? '日间' : '夜间',
                        style: TextStyle(fontSize: 12, color: Colors.white)),
                  ],
                ),
              ),
              onTap: () {
                colorModel.switchModel();

                readModel.toggleShowMenu();
              }),
          buildBottomItem('缓存', Icons.cloud_download),
          buildBottomItem('设置', Icons.settings),
        ],
      ),
      data: colorModel.theme,
    );
  }

  buildBottomItem(String title, IconData iconData) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: ScreenUtil.getScreenW(context) / 4,
        padding: EdgeInsets.symmetric(vertical: 7),
        child: Column(
          children: <Widget>[
            Icon(
              iconData,
              color: Colors.white,
            ),
            SizedBox(height: 5),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.white)),
          ],
        ),
      ),
      onTap: () {
        print(title.toString());
        switch (title) {
          case '目录':
            {
              _globalKey.currentState.openDrawer();
              readModel.toggleShowMenu();
            }
            break;
          case '缓存':
            {
              BotToast.showText(text: '开始下载...');
              readModel.downloadAll();
            }
            break;
          case '设置':
            {
              myshowModalBottomSheet(
                  context: context,
                  builder: (BuildContext bc) {
                    return StatefulBuilder(
                        builder: (context, state) => buildSetting(state));
                  });
            }
            break;
        }
      },
    );
  }

  buildSetting(state) {
    return Store.connect<ColorModel>(
        builder: (context, ColorModel colorModel, child) {
      return Container(
        color: colorModel.theme.primaryColor,
        height: 120,
        child: Padding(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
//              Row(
//                children: <Widget>[
//                  Text(
//                    '亮度',
//                    style: TextStyle(
//                        fontSize: 12,
//                        color: colorModel.dark ? Colors.white70 : Colors.black),
//                  ),
//                  Expanded(
//                    child: Container(
//                      child: Slider(
//                        activeColor: Colors.white,
//                        inactiveColor: Colors.white70,
//                        value: 50,
//                        max: 100,
//                        min: 0.0,
//                        onChanged: (newValue) {},
//                      ),
//                    ),
//                  ),
//                  Container(
//                    width: 130,
//                    child: Row(
//                      children: <Widget>[
//                        Text(
//                          '跟随系统',
//                          style: TextStyle(
//                              fontSize: 12,
//                              color: colorModel.dark
//                                  ? Colors.white70
//                                  : Colors.black),
//                        ),
//                        Checkbox(
//                          value: false,
//                          activeColor: Colors.blue,
//                          onChanged: (bool val) {},
//                        )
//                      ],
//                    ),
//                  ),
//                ],
//              ),
              Row(
                children: <Widget>[
//                  Text(
//                    '字号',
//                    style: TextStyle(
//                        fontSize: 12,
//                        color: colorModel.dark ? Colors.white70 : Colors.black),
//                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Container(
                      child: FlatButton(
                        color: Colors.white,
                        onPressed: () {
                          readModel.fontSize -= 1.0;
                          readModel.modifyFont();
                        },
                        child: ImageIcon(
                          AssetImage("images/fontsmall.png"),
                          color: Colors.black,
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(20.0))),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Container(
                      child: FlatButton(
                        color: Colors.white,
                        onPressed: () {
                          readModel.fontSize += 1.0;
                          readModel.modifyFont();
                        },
                        child: ImageIcon(
                          AssetImage("images/fontbig.png"),
                          color: Colors.black,
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(20.0))),
                      ),
                    ),
                  ),
                  SizedBox(),
//                  GestureDetector(
//                    child: Text('字体'),
//                    onTap: () {
//                      Routes.navigateTo(
//                        context,
//                        Routes.fontSet,
//                      );
//                    },
//                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: readThemes(state),
              ),
            ],
          ),
          padding: EdgeInsets.only(left: 10, right: 10),
        ),
      );
    });
  }

  List<Widget> readThemes(state) {
    List<Widget> wds = [];
    for (var i = 0; i < bgs.length; i++) {
      var f = bgs[i];
      wds.add(RawMaterialButton(
        onPressed: () {
          readModel.switchBgColor(i);
//          readModel.saveData();
          state(() {});
        },
        constraints: BoxConstraints(minWidth: 60.0, minHeight: 50.0),
        child: Container(
          margin: EdgeInsets.only(top: 5.0, bottom: 5.0),
          width: 40.0,
          height: 40.0,
          decoration: BoxDecoration(
              color: Color.fromRGBO(f[0], f[1], f[2], 0.8),
              borderRadius: BorderRadius.all(Radius.circular(25.0)),
              border: readModel.bgIdx == i
                  ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                  : Border.all(color: Colors.white30)),
        ),
      ));
    }
    wds.add(SizedBox(
      height: 8,
    ));
    return wds;
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
