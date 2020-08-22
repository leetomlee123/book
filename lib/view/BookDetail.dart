import 'dart:convert';

import 'package:book/common/PicWidget.dart';
import 'package:book/common/RatingBar.dart';
import 'package:book/common/common.dart';
import 'package:book/common/toast.dart';
import 'package:book/common/util.dart';
import 'package:book/entity/Book.dart';
import 'package:book/entity/BookInfo.dart';
import 'package:book/entity/BookTag.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/ReadModel.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';

class BookDetail extends StatefulWidget {
  BookInfo _bookInfo;

  BookDetail(this._bookInfo);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return new _BookDetailState(_bookInfo);
  }
}

class _BookDetailState extends State<BookDetail> {
  BookInfo _bookInfo;
  bool inShelf = false;
  int maxLines = 3;
  GlobalKey _globalKey = new GlobalKey();
  int maxLine = 3;

  _BookDetailState(this._bookInfo);

  @override
  Widget build(BuildContext context) {
    ColorModel value = Store.value<ColorModel>(context);
    // TODO: implement build
    return Theme(
      child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            elevation: 0,
            actions: <Widget>[
              GestureDetector(
                child: Center(
                  child: Text('书架'),
                ),
                onTap: () {
                  Navigator.of(context).popUntil(ModalRoute.withName('/'));
                  eventBus.fire(new NavEvent(0));
                },
              ),
              SizedBox(
                width: 20,
              )
            ],
          ),
          body: Column(
            children: <Widget>[
              Expanded(
                child: ListView(
                  children: <Widget>[
                    Container(
                      child: Row(children: <Widget>[
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.only(
                                  left: 10.0, top: 5.0, bottom: 10.0),
                              child: PicWidget(_bookInfo.Img),
                            )
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              width: ScreenUtil.getScreenW(context) - 120,
                              padding:
                                  const EdgeInsets.only(left: 20.0, top: 5.0),
                              child: Text(
                                _bookInfo.Name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 15),
                              ),
                            ),
                            Container(
                              padding:
                                  const EdgeInsets.only(left: 20.0, top: 2.0),
                              child: Text('作者: ${_bookInfo.Author}',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12)),
                            ),
                            Container(
                              padding:
                                  const EdgeInsets.only(left: 20.0, top: 2.0),
                              child: new Text('类型: ' + _bookInfo.CName,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  style: TextStyle(fontSize: 12)),
                            ),
                            Container(
                              padding:
                                  const EdgeInsets.only(left: 20.0, top: 2.0),
                              child: Text('状态: ${_bookInfo.BookStatus}',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  style: TextStyle(fontSize: 12)),
                              width: 270,
                            ),
                            Container(
                                padding: const EdgeInsets.only(
                                    left: 15.0, top: 2.0, bottom: 10.0),
                                child: Row(
                                  children: <Widget>[
                                    RatingBar(
                                      initialRating: _bookInfo.Rate ?? 0.0,
                                      minRating: 1,
                                      direction: Axis.horizontal,
                                      allowHalfRating: true,
                                      itemCount: 5,
                                      itemSize: 25,
                                      itemPadding:
                                          EdgeInsets.symmetric(horizontal: 1.0),
                                      itemBuilder: (context, _) => Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                      ),
                                      onRatingUpdate: (double value) {},
                                    ),
                                    Text('${_bookInfo.Rate ?? 0.0}分')
                                  ],
                                )),
                          ],
                        ),
                      ]),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      verticalDirection: VerticalDirection.down,
                      // textDirection:,
                      textBaseline: TextBaseline.alphabetic,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(left: 17.0, top: 5.0),
                          child: Text(
                            '简介',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 17.0, top: 5.0),
                          child: Column(
                            children: <Widget>[
                              Text(
                                _bookInfo.Desc ?? "".trim(),
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                                maxLines: maxLine,
                              ),
                              Center(
                                  child: GestureDetector(
                                child: Image.asset(
                                  maxLine <= 3
                                      ? "images/more_info.png"
                                      : "images/add_collapse.png",
                                  width: 30,
                                  height: 30,
                                  color: value.dark?Colors.white:Colors.black,
                                ),
                                onTap: () {
                                  if (mounted) {
                                    setState(() {
                                      maxLine = maxLine > 3 ? 3 : 100;
                                    });
                                  }
                                },
                              )
//                                child: IconButton(
//                                  padding: EdgeInsets.all(0.0),
//                                  icon: Icon(Icons.expand_more),
//                                  onPressed: (){
//                                    if(mounted){
//                                      setState(() {
//                                    maxLine=maxLine>3?3:100;
//                                      });
//                                    }
//                                  },
//                                ),
                                  )
                            ],
                          ),
                        ),
                      ],
                    ),
                    Divider(),
//                    Center(
//                      child: GestureDetector(
//                        child: Text("更多"),
//                        onTap: () {
//                          if (maxLines == 3) {
//                            maxLines = 100;
//                          } else {
//                            maxLines = 3;
//                          }
//                          setState(() {});
//                        },
//                      ),
//                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      verticalDirection: VerticalDirection.down,
                      // textDirection:,
                      textBaseline: TextBaseline.alphabetic,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(left: 17.0, top: 15.0),
                          child: new Text(
                            '目录',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ListTile(
                          trailing: Icon(Icons.keyboard_arrow_right),
                          leading: Container(
                            width: 70,
                            child: Row(
                              children: <Widget>[
                                Icon(Icons.access_time),
                                SizedBox(
                                  width: 5,
                                ),
                                Text('最新')
                              ],
                            ),
                          ),
                          title: Text(
                            _bookInfo.LastChapter,
                            style: TextStyle(fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            //标志是从书的最后一章开始看
                            _bookInfo.CId = "-1";

                            Routes.navigateTo(
                              context,
                              Routes.read,
                              params: {
                                'read': jsonEncode(_bookInfo),
                              },
                            );
                          },
                        ),
                        ListTile(
                          trailing: Icon(Icons.keyboard_arrow_right),
                          leading: Container(
                            width: 70,
                            child: Row(
                              children: <Widget>[
                                Icon(Icons.menu),
                                SizedBox(
                                  width: 5,
                                ),
                                Text('目录')
                              ],
                            ),
                          ),
                          title: Text(
                            '共${_bookInfo.Count?.toString() ?? 0}章',
                            style: TextStyle(fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            //标志是从书的最后一章开始看
                            _bookInfo.CId = "-1";
                            Routes.navigateTo(
                              context,
                              Routes.read,
                              params: {
                                'read': jsonEncode(_bookInfo),
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    Divider(),
                    _bookInfo.SameAuthorBooks != null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 17.0, top: 5.0),
                                child: new Text(
                                  '${_bookInfo.Author}  还写过',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          )
                        : Container(),
                    _bookInfo.SameAuthorBooks != null
                        ? ListView.builder(
                            shrinkWrap: true, //解决无限高度问题
                            physics: NeverScrollableScrollPhysics(), //禁用滑动事件
                            itemBuilder: (context, i) {
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  child: Row(
                                    children: <Widget>[
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: <Widget>[
                                          Container(
                                            padding: const EdgeInsets.only(
                                                left: 10.0, top: 10.0),
                                            child: PicWidget(
                                              _bookInfo.SameAuthorBooks[i].Img,
                                            ),
                                          )
                                        ],
                                      ),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        verticalDirection:
                                            VerticalDirection.down,
                                        // textDirection:,
                                        textBaseline: TextBaseline.alphabetic,

                                        children: <Widget>[
                                          Container(
                                              width: ScreenUtil.getScreenW(
                                                      context) -
                                                  120,
                                              padding: const EdgeInsets.only(
                                                  left: 10.0, top: 10.0),
                                              child: Text(
                                                _bookInfo
                                                    .SameAuthorBooks[i].Name,
                                                overflow: TextOverflow.ellipsis,
                                                style:
                                                    TextStyle(fontSize: 18.0),
                                              )),
                                          Container(
                                            padding: const EdgeInsets.only(
                                                left: 10.0, top: 10.0),
                                            child: Text(
                                              _bookInfo
                                                  .SameAuthorBooks[i].Author,
                                              style: TextStyle(fontSize: 12),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            width:
                                                ScreenUtil.getScreenW(context) -
                                                    120,
                                            padding: const EdgeInsets.only(
                                                left: 10.0, top: 10.0),
                                            child: Text(
                                                _bookInfo.SameAuthorBooks[i]
                                                    .LastChapter,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 11)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                onTap: () async {
                                  String url = Common.detail +
                                      '/${_bookInfo.SameAuthorBooks[i].Id}';
                                  Response future =
                                      await Util(context).http().get(url);
                                  var d = future.data['data'];
                                  BookInfo bookInfo = BookInfo.fromJson(d);
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              BookDetail(bookInfo)));
                                },
                              );
                            },
                            itemCount: _bookInfo.SameAuthorBooks.length,
                          )
                        : Container(),
                  ],
                ),
              )
            ],
          ),
          bottomNavigationBar: Store.connect<ShelfModel>(
              builder: (context, ShelfModel d, child) {
            return BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              unselectedItemColor: value.dark ? Colors.white : null,
              //底部导航栏的创建需要对应的功能标签作为子项，这里我就写了3个，每个子项包含一个图标和一个title。
              items: [
                d.shelf.map((f) => f.Id).toList().contains(_bookInfo.Id)
                    ? BottomNavigationBarItem(
                        icon: Icon(
                          Icons.clear,
                        ),
                        title: new Text(
                          '移除书架',
                        ))
                    : BottomNavigationBarItem(
                        icon: Icon(
                          Icons.playlist_add,
                        ),
                        title: Text(
                          '加入书架',
                        )),
                BottomNavigationBarItem(
                    icon: ImageIcon(
                      AssetImage("images/read.png"),
                    ),
                    title: Text(
                      '立即阅读',
                    )),
                BottomNavigationBarItem(
                    icon: Icon(
                      Icons.cloud_download,
                    ),
                    title: new Text(
                      '全本缓存',
                    )),
              ],

              onTap: (int i) {
                switch (i) {
                  case 0:
                    {
                      Book book = new Book(
                          "",
                          "",
                          0,
                          _bookInfo.Id,
                          _bookInfo.Name,
                          "",
                          _bookInfo.Author,
                          _bookInfo.Img,
                          _bookInfo.LastChapterId,
                          _bookInfo.LastChapter,
                          _bookInfo.LastTime);
                      Store.value<ShelfModel>(context).modifyShelf(book);
                    }
                    break;
                  case 1:
                    {
                      Routes.navigateTo(
                        context,
                        Routes.read,
                        params: {
                          'read': jsonEncode(_bookInfo),
                        },
                      );
                    }
                    break;
                  case 2:
                    {
                      Toast.show('开始下载...');

                      var value = Store.value<ReadModel>(context);
                      value.bookInfo = _bookInfo;
                      value.bookTag = BookTag(0, 0, _bookInfo.Name);
                      value.downloadAll();
                    }
                    break;
                }
              },
            );
          })),
      data: Store.value<ColorModel>(context).theme,
    );
  }
}
