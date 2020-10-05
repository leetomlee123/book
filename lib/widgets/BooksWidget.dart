import 'dart:convert';

import 'package:book/common/PicWidget.dart';
import 'package:book/entity/Book.dart';
import 'package:book/entity/BookInfo.dart';
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
  RefreshController _refreshController =
      RefreshController(initialRefresh: SpUtil.haveKey('login'));
  ShelfModel _shelfModel;
  @override
  void initState() {
    _shelfModel = Store.value<ShelfModel>(context);
    eventBus
        .on<SyncShelfEvent>()
        .listen((SyncShelfEvent booksEvent) => freshShelf());
    super.initState();
    var widgetsBinding = WidgetsBinding.instance;
    widgetsBinding.addPostFrameCallback((callback) {
      _shelfModel.context = context;
      _shelfModel.setShelf();
      _shelfModel.freshToken();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
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
        child: _shelfModel.model ? coverModel() : listModel());
  }

  //刷新书架
  freshShelf() async {
    if (SpUtil.haveKey('auth')) {
      _shelfModel.refreshShelf();
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
          mainAxisSpacing: 1.0,
          crossAxisSpacing: 10.0,
          childAspectRatio: 0.7),
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
              children: <Widget>[
                PicWidget(
                  book.Img,
                  width: (ScreenUtil.getScreenW(context) - 80) / 3,
                  height: ((ScreenUtil.getScreenW(context) - 80) / 3) * 1.2,
                ),
                book.NewChapterCount == 1
                    ? Container(
                        width: (ScreenUtil.getScreenW(context) - 80) / 3,
                        height:
                            ((ScreenUtil.getScreenW(context) - 80) / 3) * 1.2,
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
          Book temp = _shelfModel.shelf[i];

          _shelfModel.shelf[i].NewChapterCount = 0;
          _shelfModel.upTotop(temp);
          
          Routes.navigateTo(
            context,
            Routes.read,
            params: {
              'read': jsonEncode(BookInfo.id(temp.Id, temp.Name, temp.Img)),
            },
          );
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
        itemCount: _shelfModel.shelf.length,
        itemBuilder: (context, i) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              Book temp = _shelfModel.shelf[i];

              _shelfModel.shelf[i].NewChapterCount = 0;
          
              Routes.navigateTo(
                context,
                Routes.read,
                params: {
                  'read': jsonEncode(BookInfo.id(temp.Id, temp.Name, temp.Img)),
                },
              );
              _shelfModel.upTotop(temp);

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
                      padding: const EdgeInsets.only(left: 10.0, top: 10.0),
                      child: Stack(
                        children: <Widget>[
                          PicWidget(item.Img),
                          item.NewChapterCount == 1
                              ? Container(
                                  height: 115,
                                  width: 97,
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
                      width: ScreenUtil.getScreenW(context) - 115,
                      padding: const EdgeInsets.only(left: 10.0, top: 8.0),
                      child: Text(
                        item.Name,
                        style: TextStyle(
                            fontSize: 16.0, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.only(left: 10.0, top: 12.0),
                      child: Text(
                        item.LastChapter,
                        style: TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      width: ScreenUtil.getScreenW(context) - 115,
                    ),
                    Container(
                      padding: const EdgeInsets.only(left: 10.0, top: 22.0),
                      child: Text(item.UTime,
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
                        // color: Colors.red,
                        height: 115,
                        width: ScreenUtil.getScreenW(context),
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

// //整理书架悬浮层
//   Widget pickWidget() {
//     return Container(
//       width: Screen.width,
//       height: Screen.height,
//       child: Column(
//         children: [
//           AppBar(
//             title: Text("书架整理"),
//             elevation: 0,
//             centerTitle: true,
//             automaticallyImplyLeading: false,
//             leading: IconButton(
//                 icon: Icon(Icons.arrow_back),
//                 onPressed: () {
//                   _shelfModel.sortShelfModel();
//                 }),
//           ),
//           Expanded(
//             child: Opacity(
//               opacity: 0.0,
//               child: Container(
//                 width: double.infinity,
//               ),
//             ),
//           ),
//           Row(
//             children: [
//               GestureDetector(
//                 child: Text("全选"),
//               ),
//               GestureDetector(
//                 child: Text(
//                   "删除",
//                   style: TextStyle(color: Colors.red),
//                 ),
//               ),
//             ],
//           )
//         ],
//       ),
//     );
//   }
