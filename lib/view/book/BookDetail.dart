import 'dart:convert';
import 'dart:ui';

import 'package:book/common/DbHelper.dart';
import 'package:book/common/Http.dart';
import 'package:book/common/PicWidget.dart';
import 'package:book/common/RatingBar.dart';
import 'package:book/common/common.dart';
import 'package:book/entity/Book.dart';
import 'package:book/entity/BookInfo.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/ReadModel.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/book/BookHeadBgColor.dart';
import 'package:book/widgets/text_ellipsis.dart';
import 'package:book/widgets/text_two.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';

class BookDetail extends StatefulWidget {
  final BookInfo _bookInfo;

  BookDetail(this._bookInfo);

  @override
  State<StatefulWidget> createState() {
    return new _BookDetailState();
  }
}

class _BookDetailState extends State<BookDetail> {
  Book book;
  ColorModel _colorModel;
  int maxLines = 3;
  bool ellipsis = true;

  @override
  void initState() {
    book = Book(
        0,
        0,
        0,
        0.0,
        "",
        "",
        0,
        this.widget._bookInfo.Id,
        '',
        this.widget._bookInfo.Name,
        "",
        this.widget._bookInfo.Author,
        this.widget._bookInfo.Img,
        this.widget._bookInfo.Desc,
        this.widget._bookInfo.LastChapterId,
        this.widget._bookInfo.LastChapter,
        this.widget._bookInfo.LastTime);
    super.initState();
    _colorModel = Store.value<ColorModel>(context);
  }

  Widget _bookHead() {
    return Column(
      children: [
        Row(children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Container(
                padding:
                    const EdgeInsets.only(left: 15.0, top: 5.0, bottom: 10.0),
                child: PicWidget(
                  book.Img,
                  height: 130,
                  width: 95,
                ),
              )
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: ScreenUtil.getScreenW(context) - 120,
                padding: const EdgeInsets.only(left: 20.0, top: 5.0),
                child: Text(
                  book.Name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, color: Colors.white),
                ),
              ),
              Container(
                padding: const EdgeInsets.only(left: 20.0, top: 2.0),
                child: Text('作者: ${book.Author}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.white)),
              ),
              Container(
                padding: const EdgeInsets.only(left: 20.0, top: 2.0),
                child: new Text('类型: ' + book.CName,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(fontSize: 12, color: Colors.white)),
              ),
              Container(
                padding: const EdgeInsets.only(left: 20.0, top: 2.0),
                child: Text('状态: ${this.widget._bookInfo.BookStatus}',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(fontSize: 12, color: Colors.white)),
                width: 270,
              ),
              Container(
                  padding:
                      const EdgeInsets.only(left: 15.0, top: 2.0, bottom: 10.0),
                  child: Row(
                    children: <Widget>[
                      RatingBar(
                        itemSize: 30,
                        initialRating: this.widget._bookInfo.Rate ?? 1,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        itemCount: 5,
                        itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                        itemBuilder: (context, _) => Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        onRatingUpdate: (rating) {},
                      ),
                      Text(
                        '${this.widget._bookInfo.Rate ?? 0.0}分',
                        style: TextStyle(color: Colors.white),
                      )
                    ],
                  )),
            ],
          ),
        ]),
        SizedBox(
          height: 20,
        )
      ],
    );
  }

  Widget _bookDesc() {
    return TextEllipsis(this.widget._bookInfo.Desc ?? "".trim());
  }

  Widget _bookMenu() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      verticalDirection: VerticalDirection.down,
      // textDirection:,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 17.0, top: 15.0),
          child: Text(
            '目录',
          ),
        ),
        ListTile(
          // trailing: Icon(Icons.keyboard_arrow_right),
          leading: Container(
            width: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.access_time),
                SizedBox(
                  width: 5,
                ),
                TextTwo(
                  '最新',
                )
              ],
            ),
          ),
          title: TextTwo(
            this.widget._bookInfo.LastChapter,
            fontSize: 14,
            maxLines: 1,
          ),
          // onTap: () {
          //   //标志是从书的最后一章开始看
          //   this.widget._bookInfo.CId = "-1";
          //
          //   Routes.navigateTo(
          //     context,
          //     Routes.read,
          //     params: {
          //       'read': jsonEncode(book),
          //     },
          //   );
          // },
        ),
      ],
    );
  }

  Widget _sameAuthorBooks() {
    return Offstage(
      offstage: this.widget._bookInfo.SameAuthorBooks?.isEmpty ?? true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 17.0, top: 15.0, bottom: 10),
            child: Text(
              '作者还写过:',
              style: TextStyle(fontSize: 15),
            ),
          ),
          ListView.builder(
            padding: EdgeInsets.all(0),
            shrinkWrap: true,

            //解决无限高度问题
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, i) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                child: Container(
                  child: Row(
                    children: <Widget>[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.only(left: 15.0, top: 10),
                            child: PicWidget(
                              this.widget._bookInfo.SameAuthorBooks[i].Img,
                            ),
                          )
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        verticalDirection: VerticalDirection.down,
                        // textDirection:,
                        textBaseline: TextBaseline.alphabetic,

                        children: <Widget>[
                          Container(
                              width: ScreenUtil.getScreenW(context) - 120,
                              padding:
                                  const EdgeInsets.only(left: 10.0, top: 10),
                              child: Text(
                                this.widget._bookInfo.SameAuthorBooks[i].Name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 18.0),
                              )),
                          Container(
                            padding:
                                const EdgeInsets.only(left: 10.0, top: 10.0),
                            child: Text(
                              this.widget._bookInfo.SameAuthorBooks[i].Author,
                              style: TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            width: ScreenUtil.getScreenW(context) - 120,
                            padding:
                                const EdgeInsets.only(left: 10.0, top: 10.0),
                            child: Text(
                                this
                                    .widget
                                    ._bookInfo
                                    .SameAuthorBooks[i]
                                    .LastChapter,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 11)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                onTap: () async {
                  String url = Common.detail +
                      '/${this.widget._bookInfo.SameAuthorBooks[i].Id}';
                  Response future = await HttpUtil().http().get(url);
                  var d = future.data['data'];
                  BookInfo bookInfo = BookInfo.fromJson(d);
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => BookDetail(bookInfo)));
                },
              );
            },
            itemCount: this.widget._bookInfo.SameAuthorBooks?.length ?? 0,
            cacheExtent: 200,
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                elevation: 0,
                actions: <Widget>[
                  GestureDetector(
                    child: Center(
                      child: Text(
                        '书架',
                        style: TextStyle(
                          color: Colors.white,
                    
                        ),
                      ),
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
                expandedHeight: 230.0,
                // backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  // title: const Text('Demo'),
                  background: Stack(
                    children: [
                      BookHeadBgColor(book.Img),
                      Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: _bookHead(),
                      )
                    ],
                  ),
                ),
              ),
              SliverList(
                  delegate: SliverChildListDelegate([
                _bookDesc(),
                Divider(
                  endIndent: 12,
                  indent: 12,
                ),
                _bookMenu(),
                Divider(
                  endIndent: 12,
                  indent: 12,
                ),
                _sameAuthorBooks(),
                Padding(
                  padding: const EdgeInsets.only(left: 17.0, top: 15.0),
                  child: Center(
                    child: Text(
                      '到底啦',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ),
                SizedBox(
                  height: 40,
                )
              ])),
            ],
          ),
          Store.connect<ShelfModel>(
              builder: (context, ShelfModel model, child) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                unselectedItemColor: _colorModel.dark ? Colors.white : null,
                items: [
                  model.inShelf(this.widget._bookInfo.Id)
                      ? BottomNavigationBarItem(
                          icon: Icon(
                            Icons.clear,
                          ),
                          label: '移除书架',
                        )
                      : BottomNavigationBarItem(
                          icon: Icon(
                            Icons.playlist_add,
                          ),
                          label: '加入书架',
                        ),

                  BottomNavigationBarItem(
                    icon: ImageIcon(
                      AssetImage("images/read.png"),
                    ),
                    label: '立即阅读',
                  ),
                  // BottomNavigationBarItem(
                  //   icon: Icon(
                  //     Icons.cloud_download,
                  //   ),
                  //   label: '全本缓存',
                  // ),
                ],
                onTap: (int i) async {
                  switch (i) {
                    case 0:
                      {
                        Store.value<ShelfModel>(context).modifyShelf(book);
                      }
                      break;
                    case 1:
                      {
                        Book b = await DbHelper.instance.getBook(book.Id);

                        Routes.navigateTo(
                          context,
                          Routes.read,
                          params: {
                            'read': jsonEncode(b == null ? book : b),
                          },
                        );
                      }
                      break;
                    // case 2:
                    //   {
                    //     BotToast.showText(text: "开始下载...");
                    //
                    //     var value = Store.value<ReadModel>(context);
                    //     value.book = _bookInfo as Book;
                    //     value.book.UTime = _bookInfo.LastTime;
                    //     value.bookTag = BookTag(0, 0, _bookInfo.Name, 0.0);
                    //     value.downloadAll();
                    //   }
                    //   break;
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
