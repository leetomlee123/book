import 'dart:convert';

import 'package:book/common/PicWidget.dart';
import 'package:book/common/common.dart';
import 'package:book/entity/Book.dart';
import 'package:book/entity/BookInfo.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/ReadBook.dart';
import 'package:book/view/Search.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class BookShelf extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return new _BookShelfState();
  }
}

class _BookShelfState extends State<BookShelf>
    with AutomaticKeepAliveClientMixin {
  Widget body;
  RefreshController _refreshController =
      RefreshController(initialRefresh: SpUtil.haveKey('login'));

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // TODO: implement build
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              eventBus.fire(OpenEvent(""));
            },
          ),
          elevation: 0,
          title: Text(
            '书架',
            style: TextStyle(
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (BuildContext context) => Search()));
              },
            )
          ],
        ),
        body: Store.connect<ShelfModel>(
            builder: (context, ShelfModel model, child) => SmartRefresher(
                enablePullDown: true,
                header: WaterDropHeader(),
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
                child: ListView.builder(
                    itemCount: model.shelf.length,
                    itemBuilder: (context, i) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          model.shelf[i].NewChapterCount = 0;
                          Book temp = model.shelf[i];
                          model.upTotop(temp);
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (BuildContext context) => ReadBook(
                                  BookInfo.id(temp.Id, temp.Name, temp.Img))));
                        },
                        child: getBookItemView(model.shelf[i]),
                      );
                    }))));
  }

//刷新书架
  freshShelf() async {
    if (SpUtil.haveKey('login')) {
      Store.value<ShelfModel>(context).refreshShelf();
      _refreshController.refreshCompleted();
    }
  }

  getBookItemView(Book item) {
    return Dismissible(
      key: Key(item.Id.toString()),
      child: Container(
        child: Row(
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.only(left: 10.0, top: 10.0),
                  child: Stack(
                    children: <Widget>[
                      PicWidget(item.Img, null, null),
                      item.NewChapterCount == 1
                          ? Container(
                              height: 100,
                              width: 80,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: ScreenUtil.getScreenW(context) - 120,
                  padding: const EdgeInsets.only(left: 10.0, top: 10.0),
                  child: Text(
                    item.Name,
                    style: TextStyle(fontSize: 16.0),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(left: 10.0, top: 5.0),
                  child: Text(
                    item.LastChapter,
                    style: TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  width: ScreenUtil.getScreenW(context) - 120,
                ),
                Container(
                  padding: const EdgeInsets.only(left: 10.0, top: 10.0),
                  child: Text(item.UTime,
                      style: TextStyle(color: Colors.grey, fontSize: 11)),
                ),
              ],
            ),
          ],
        ),
      ),
      onDismissed: (direction) {
        Store.value<ShelfModel>(context).modifyShelf(item);
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
          _alertDialog = _createDialog(
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
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;

  @override
  void initState() {
    // TODO: implement initState
    eventBus
        .on<SyncShelfEvent>()
        .listen((SyncShelfEvent booksEvent) => freshShelf());
    super.initState();
    var widgetsBinding = WidgetsBinding.instance;
    widgetsBinding.addPostFrameCallback((callback) {
      if (SpUtil.haveKey(Common.listbookname)) {
        var name = SpUtil.getString(Common.listbookname);
        List decode2 = json.decode(name);
        List<Book> bks = decode2.map((m) => Book.fromJson(m)).toList();

        Store.value<ShelfModel>(context).shelf = bks;
        Store.value<ShelfModel>(context).context = context;
        if (mounted) {
          setState(() {});
        }
      }
    });
  }
}
