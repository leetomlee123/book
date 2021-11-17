import 'dart:convert';

import 'package:book/common/DbHelper.dart';
import 'package:book/common/Http.dart';
import 'package:book/common/PicWidget.dart';
import 'package:book/common/RatingBar.dart';
import 'package:book/common/Screen.dart';
import 'package:book/common/common.dart';
import 'package:book/entity/Book.dart';
import 'package:book/entity/BookInfo.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
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
  }

  Widget _bookHead() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      height: 100,
      child:
          Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        PicWidget(
          book.Img,
          height: 130,
          width: 95,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Text(
                book.Name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, color: Colors.white),
              ),
              Text('作者: ${book.Author}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.white)),
              Text('类型: ' + book.CName,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: TextStyle(fontSize: 12, color: Colors.white)),
              Text('状态: ${this.widget._bookInfo.BookStatus}',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: TextStyle(fontSize: 12, color: Colors.white)),
              RatingBar(
                itemSize: 15,
                initialRating: this.widget._bookInfo.Rate ?? 1,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemBuilder: (context, _) => Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {},
              )
            ],
          ),
        ),
      ]),
    );
  }

  Widget _bookDesc() {
    return TextEllipsis(this.widget._bookInfo.Desc ?? "".trim());
  }

  Widget _bookMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '目录',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          ListTile(
            leading: Container(
              width: 70,
              child: Row(
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
          ),
        ],
      ),
    );
  }

  Widget _sameAuthorBooks() {
    return Offstage(
      offstage: this.widget._bookInfo.SameAuthorBooks?.isEmpty ?? true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '作者还写过',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            ListView.builder(
              padding: const EdgeInsets.only(),
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, i) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 115,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        PicWidget(
                          this.widget._bookInfo.SameAuthorBooks[i].Img,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  this.widget._bookInfo.SameAuthorBooks[i].Name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  this
                                      .widget
                                      ._bookInfo
                                      .SameAuthorBooks[i]
                                      .Author,
                                  style: TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                    this
                                        .widget
                                        ._bookInfo
                                        .SameAuthorBooks[i]
                                        .LastChapter,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  onTap: () async {
                    String url = Common.detail +
                        '/${this.widget._bookInfo.SameAuthorBooks[i].Id}';
                    Response future = await HttpUtil.instance.dio.get(url);
                    var d = future.data['data'];
                    BookInfo bookInfo = BookInfo.fromJson(d);
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => BookDetail(bookInfo)));
                  },
                );
              },
              itemCount: this.widget._bookInfo.SameAuthorBooks?.length ?? 0,
              cacheExtent: 200,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBottom() {
    return Store.connect<ShelfModel>(
        builder: (context, ShelfModel model, child) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: BoxDecoration( color: SpUtil.getBool("dark") ? Colors.black : Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(1.0)),
          ),
          padding: EdgeInsets.only(bottom: Screen.bottomSafeHeight),

          child: ButtonBar(
            alignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                  onPressed: () {
                    SpUtil.putString(book.Id, "");
                    model.modifyShelf(book);
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      //执行缩放动画
                      return ScaleTransition(child: child, scale: animation);
                    },
                    child: Text(model.inShelf(this.widget._bookInfo.Id)
                        ? "移出书架"
                        : "加入书架"),
                    key:
                        ValueKey<bool>(model.inShelf(this.widget._bookInfo.Id)),
                  )),
              TextButton(
                  onPressed: () async {
                    Book b = await DbHelper.instance.getBook(book.Id);

                    Routes.navigateTo(
                      context,
                      Routes.read,
                      params: {
                        'read': jsonEncode(b == null ? book : b),
                      },
                    );
                  },
                  child: Text(SpUtil.haveKey(book.Id) ? "继续阅读" : "立即阅读")),
            ],
          ),
        ),
      );
    });
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
                expandedHeight: 210.0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: EdgeInsets.only(top: Screen.topSafeHeight + 45),
                    child: _bookHead(),
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
              ])),
            ],
          ),
          _buildBottom()
        ],
      ),
    );
  }
}
