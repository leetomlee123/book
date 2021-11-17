import 'dart:convert';

import 'package:book/common/Screen.dart';
import 'package:book/common/common.dart';
import 'package:book/entity/Book.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:book/widgets/has_update_icon_img.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:keframe/frame_separate_widget.dart';
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

  final double aspectRatioList = 0.69;
  final double aspectRatioCover = 0.75;
  double bookPicWidth = SpUtil.getDouble(Common.book_pic_width, defValue: .0);
  int spacingLen = 20;
  int axisLen = 4;

  @override
  void initState() {
    super.initState();
    if (bookPicWidth == .0) {
      bookPicWidth = Screen.width / 4.3;
      SpUtil.putDouble(Common.book_pic_width, bookPicWidth);
    }
    isShelf = this.widget.type == '';
    _shelfModel = Store.value<ShelfModel>(context);
    _refreshController = RefreshController();
    var widgetsBinding = WidgetsBinding.instance;
    widgetsBinding.addPostFrameCallback((callback) {
      _shelfModel.context = context;
      if (isShelf) {
        _shelfModel.freshToken();
      }
      if (isShelf) _refreshController.requestRefresh();
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
              body = Text(DateUtil.formatDate(DateTime.now(),
                  format: DateFormats.zh_h_m_s));
            }
            return Center(
              child: body,
            );
          },
        ),
        controller: _refreshController,
        onRefresh: freshShelf,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: _shelfModel.cover ? coverModel() : listModel(),
        ));
  }

  //刷新书架
  freshShelf() async {
    if (_shelfModel.shelf.isEmpty) {
      await _shelfModel.initShelf();
    }
    if (SpUtil.haveKey('auth')) {
      try {
        await _shelfModel.refreshShelf();
      } catch (e) {
        _refreshController.refreshCompleted();
      }
    }
    _refreshController.refreshCompleted();
  }

  //书架封面模式
  Widget coverModel() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        spacing: 20, //主轴上子控件的间距
        runSpacing: 30, //交叉轴上子控件之间的间距
        children: cover(), //要显示的子控件集合
      ),
    );
  }

  Widget bookAction(Widget widget, int i) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        this.widget.type == "sort"
            ? _shelfModel.changePick(i)
            : await readBook(i);
      },
      child: widget,
      onLongPress: () {
        Routes.navigateTo(
          context,
          Routes.sortShelf,
        );
      },
    );
  }

  /**
   * 封面子项
   */
  List<Widget> cover() {
    List<Widget> wds = [];
    List<Book> books = _shelfModel.shelf;
    Book book;
    for (int i = 0; i < books.length; i++) {
      book = books[i];
      wds.add(Container(
        width: bookPicWidth,
        child: bookAction(
            Column(
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusDirectional.circular(3)),
                  clipBehavior: Clip.antiAlias,
                  child: HasUpdateIconImg(bookPicWidth,
                      bookPicWidth / aspectRatioCover, this.widget.type, i),
                ),
                SizedBox(
                  height: 5,
                ),
                Center(
                  child: Text(
                    book.Name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
            i),
      ));
    }
    int len = 0;

    len = (Screen.width - 20) ~/ bookPicWidth;
    if (((Screen.width - 20) % bookPicWidth) < (len - 1) * 5) {
      len -= 1;
    }
    SpUtil.putInt("lenx", len);
    // }
    //不满4的倍数填充container
    int z = wds.length < len ? len - wds.length : len - wds.length % len;
    if (z != 0) {
      for (var i = 0; i < z; i++) {
        wds.add(Container(
          width: bookPicWidth,
        ));
      }
    }
    return wds;
  }

  //书架列表模式
  Widget listModel() {
    return ListView.builder(
      cacheExtent: 500,
      itemCount: _shelfModel.shelf.length,
      itemBuilder: (c, i) => FrameSeparateWidget(
        index: i,
        child: bookAction(getBookItemView(i), i),
      ),
    );
  }

  Future readBook(int i) async {
    var b = _shelfModel.shelf[i];
    Routes.navigateTo(
      context,
      Routes.read,
      params: {
        'read': jsonEncode(b),
      },
    );
    _shelfModel.sort(i);
  }

  /**
   * 列表子项
   */
  getBookItemView(int i) {
    Book item = _shelfModel.shelf[i];
    return Dismissible(
      key: Key(item.Id.toString()),
      child: Container(
        height: bookPicWidth / aspectRatioList,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: <Widget>[
            HasUpdateIconImg(bookPicWidth, bookPicWidth / aspectRatioList,
                this.widget.type, i),
            //expanded 回占据剩余空间 text maxLine=1 就不会超过屏幕了
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.Name,
                      style: TextStyle(
                          fontSize: 18.0, fontWeight: FontWeight.bold),
                      maxLines: 1,
                    ),
                    Text(
                      item.Author,
                      style: TextStyle(
                        fontSize: 12.0,
                      ),
                      maxLines: 1,
                    ),
                    Text(
                      item.LastChapter,
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      item?.UTime ?? '',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
        var _alertDialog;

        if (direction == DismissDirection.endToStart) {
          // 从右向左  也就是删除

          _alertDialog = AlertDialog(
              title: Text("确认删除"),
              content: Text(item.Name),
              actions: <Widget>[
                TextButton(
                    child: Text("取消"),
                    onPressed: () => Navigator.of(context).pop(false)),
                TextButton(
                    child: Text("确定"),
                    onPressed: () => Navigator.of(context).pop(true)),
              ]);
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

  @override
  void dispose() {
    _refreshController?.dispose();
    super.dispose();
  }
}
