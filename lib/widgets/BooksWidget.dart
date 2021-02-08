import 'dart:convert';

import 'package:book/common/DbHelper.dart';
import 'package:book/common/PicWidget.dart';
import 'package:book/common/Screen.dart';
import 'package:book/entity/Book.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:book/widgets/ConfirmDialog.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class BooksWidget extends StatefulWidget {
  final String type;

  BooksWidget(this.type);

  @override
  _BooksWidgetState createState() => _BooksWidgetState();
}

class _BooksWidgetState extends State<BooksWidget> {
  Widget body;
  RefreshController _refreshController;
  ShelfModel _shelfModel;
  bool isShelf;

  @override
  void initState() {
    isShelf = this.widget.type == '';
    _refreshController =
        RefreshController(initialRefresh: SpUtil.haveKey('auth') && isShelf);
    _shelfModel = Store.value<ShelfModel>(context);
    eventBus
        .on<SyncShelfEvent>()
        .listen((SyncShelfEvent booksEvent) => freshShelf());
    super.initState();
    var widgetsBinding = WidgetsBinding.instance;
    widgetsBinding.addPostFrameCallback((callback) {
      _shelfModel.context = context;
      _shelfModel.setShelf();
      if (isShelf) {
        _shelfModel.freshToken();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
        enablePullDown: true,
        footer: CustomFooter(
          builder: (BuildContext context, LoadStatus mode) {
            if (mode == LoadStatus.idle) {
            } else if (mode == LoadStatus.loading) {
              body = CupertinoActivityIndicator();
            } else if (mode == LoadStatus.failed) {
              body = Text("加载失败！点击重试！");
            } else if (mode == LoadStatus.canLoading) {
              body = Text("松手,加载更多!");
            } else {
              body = Text("到底了!");
            }
            return Center(
              child: body,
            );
          },
        ),
        controller: _refreshController,
        onRefresh: freshShelf,
        child: _shelfModel.model ? coverModel() : listModel());
  }

  //刷新书架
  freshShelf() async {
    if (SpUtil.haveKey('auth')) {
      await _shelfModel.refreshShelf();
    }
    _refreshController.refreshCompleted();
  }

  //书架封面模式
  Widget coverModel() {
    return GridView(
      shrinkWrap: true,
      padding: EdgeInsets.all(10.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10.0,
          crossAxisSpacing: 10.0,
          childAspectRatio: 0.75),
      children: cover(),
    );
  }

  List<Widget> cover() {
    List<Widget> wds = [];
    List<Book> books = _shelfModel.shelf;
    Book book;
    for (var i = 0; i < books.length; i++) {
      book = books[i];
      wds.add(GestureDetector(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Stack(
              alignment: AlignmentDirectional.topCenter,
              children: <Widget>[
                Container(
                  child: PicWidget(
                    book.Img,
                    width: (ScreenUtil.getScreenW(context) - 100) / 3,
                    height: ((ScreenUtil.getScreenW(context) - 100) / 3) * 1.3,
                  ),
                  decoration:
                      BoxDecoration(shape: BoxShape.rectangle, boxShadow: [
                    BoxShadow(
                        offset: Offset(2, 1), //x,y轴
                        color: Colors.black38, //投影颜色
                        blurRadius: 10.0 //投影距离
                        )
                  ]),
                ),
                book.NewChapterCount == 1
                    ? Container(
                        width: (ScreenUtil.getScreenW(context) - 100) / 3,
                        height:
                            ((ScreenUtil.getScreenW(context) - 100) / 3) * 1.3,
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Image.asset(
                            'images/h6.png',
                            width: 30,
                            height: 30,
                          ),
                        ),
                      )
                    : Container(),
                this.widget.type == "sort"
                    ? GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: (ScreenUtil.getScreenW(context) - 80) / 3,
                          height:
                              ((ScreenUtil.getScreenW(context) - 80) / 3) * 1.2,
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Image.asset(
                              'images/pick.png',
                              color: !_shelfModel.picks(i)
                                  ? Colors.white
                                  : Store.value<ColorModel>(context)
                                      .theme
                                      .primaryColor,
                              width: 30,
                              height: 30,
                            ),
                          ),
                        ),
                        onTap: () {
                          _shelfModel.changePick(i);
                        },
                      )
                    : Container()
              ],
            ),
            Text(
              book.Name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          ],
        ),
        onTap: () async {
          await goRead(_shelfModel.shelf[i], i);
        },
        onLongPress: () {
          Routes.navigateTo(
            context,
            Routes.sortShelf,
          );
        },
      ));
    }

    return wds;
  }

  //书架列表模式
  Widget listModel() {
    return ListView.builder(
        itemExtent: (10 + (Screen.width / 4) * 1.2),
        itemCount: _shelfModel.shelf.length,
        itemBuilder: (context, i) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              await goRead(_shelfModel.shelf[i], i);
            },
            child: getBookItemView(_shelfModel.shelf[i], i),
            onLongPress: () {
              Routes.navigateTo(
                context,
                Routes.sortShelf,
              );
            },
          );
        });
  }

  Future goRead(Book book, int i) async {
    Book b = await DbHelper.instance.getBook(book.Id);
    Routes.navigateTo(
      context,
      Routes.read,
      params: {
        'read': jsonEncode(b),
      },
    );
    _shelfModel.upTotop(b, i);
  }

  getBookItemView(Book item, int i) {
    return Dismissible(
      key: Key(item.Id.toString()),
      child: Stack(
        children: [
          Container(
            child: Row(
              children: <Widget>[
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.only(left: 15.0, top: 10.0),
                      child: Stack(
                        children: <Widget>[
                          PicWidget(
                            item.Img,
                            height: (Screen.width / 4) * 1.2,
                            width: Screen.width / 4,
                          ),
                          item.NewChapterCount == 1
                              ? Container(
                                  height: (Screen.width / 4) * 1.2,
                                  width: Screen.width / 4,
                                  child: Align(
                                    alignment: Alignment.topRight,
                                    child: Image.asset(
                                      'images/h6.png',
                                      width: 30,
                                      height: 30,
                                    ),
                                  ),
                                )
                              : Container(),
                        ],
                      ),
                    )
                  ],
                ),
                Column(
               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: ScreenUtil.getScreenW(context) - 120,
                      padding: const EdgeInsets.only(
                          left: 10.0,  right: 10),
                      child: Text(
                        item.Name,
                        style: TextStyle(
                            fontSize: 18.0, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.only(
                          left: 10.0, right: 10),
                      child: Text(
                        item.LastChapter,
                        style: TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      width: ScreenUtil.getScreenW(context) - 120,
                    ),
                    Container(
                      padding: const EdgeInsets.only(
                          left: 10.0, right: 10),
                      child: Text(item?.UTime ?? '',
                          style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ),
                  ],
                ),

              ],
            ),
          ),
          Align(
              alignment: Alignment.topRight,
              child: this.widget.type == "sort"
                  ? GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        margin: EdgeInsets.only(right: 20),
                        height: 115,
                        width: ScreenUtil.getScreenW(context),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Image.asset(
                            'images/pick.png',
                            color: !_shelfModel.picks(i)
                                ? Colors.black38
                                : Store.value<ColorModel>(context)
                                    .theme
                                    .primaryColor,
                            width: 30,
                            height: 30,
                          ),
                        ),
                      ),
                      onTap: () {
                        _shelfModel.changePick(i);
                      },
                    )
                  : Container())
        ],
      ),
      onDismissed: (direction) {
        _shelfModel.modifyShelf(item);
      },
      background: Container(
        color: Colors.green,
        // 这里使用 ListTile 因为可以快速设置左右两端的Icon
        child: ListTile(
          leading: Icon(
            Icons.bookmark,
            color: Colors.white,
          ),
        ),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        // 这里使用 ListTile 因为可以快速设置左右两端的Icon
        child: ListTile(
          trailing: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      confirmDismiss: (direction) async {
        var _confirmContent;

        var _alertDialog;

        if (direction == DismissDirection.endToStart) {
          // 从右向左  也就是删除
          _confirmContent = '确认删除     ${item.Name}';
          _alertDialog = ConfirmDialog(
            _confirmContent,
            () {
              // 展示 SnackBar
              Navigator.of(context).pop(true);
            },
            () {
              Navigator.of(context).pop(false);
            },
          );
        } else {
          return false;
        }
        var isDismiss = await showDialog(
            context: context,
            builder: (context) {
              return _alertDialog;
            });
        return isDismiss;
      },
    );
  }
}
