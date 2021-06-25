import 'dart:convert';

import 'package:book/common/DbHelper.dart';
import 'package:book/common/PicWidget.dart';
import 'package:book/common/Screen.dart';
import 'package:book/entity/Book.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:book/widgets/ConfirmDialog.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
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
  double picHeight = (Screen.width / 4) * 1.3;
  final double coverWidth = 76.0;
  final double aspectRatio = 0.62;
  final double coverHeight = 122.58;
  int spacingLen = 20;
  int axisLen = 4;

  @override
  void initState() {
    isShelf = this.widget.type == '';
    _shelfModel = Store.value<ShelfModel>(context);
    _refreshController = RefreshController();
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
      if (SpUtil.haveKey('auth') && isShelf)
        _refreshController.requestRefresh();
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
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        spacing: 4, //主轴上子控件的间距
        runSpacing: 15, //交叉轴上子控件之间的间距
        children: cover(), //要显示的子控件集合
      ),
    );
    // return Flow(
    //   children: cover(),
    //   delegate: MyFlowDelegate(coverWidth),
    // );
  }

  List<Widget> cover() {
    List<Widget> wds = [];
    List<Book> books = _shelfModel.shelf;
    Book book;
    for (var i = 0; i < books.length; i++) {
      book = books[i];
      wds.add(Container(
        width: coverWidth,
        child: GestureDetector(
          child: Stack(
            alignment: AlignmentDirectional.topCenter,
            children: <Widget>[
              Column(
                children: [
                  PicWidget(
                    book.Img,
                    width: coverWidth,
                    height: coverHeight,
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Center(
                    child: Text(
                      book.Name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                ],
              ),
              Offstage(
                offstage: book.NewChapterCount != 1,
                child: Align(
                  alignment: Alignment.topRight,
                  child: Image.asset(
                    'images/h6.png',
                    width: 30,
                    height: 30,
                  ),
                ),
              ),
              Offstage(
                offstage: this.widget.type != "sort",
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: coverWidth,
                    height: coverHeight,
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Image.asset(
                        'images/pick.png',
                        color: !_shelfModel.picks(i)
                            ? Colors.white
                            : Theme.of(context).primaryColor,
                        width: 30,
                        height: 30,
                      ),
                    ),
                  ),
                  onTap: () {
                    _shelfModel.changePick(i);
                  },
                ),
              ),
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
        ),
      ));
    }
    int len = 0;
    // if (SpUtil.haveKey("lenx")) {
    //   len = SpUtil.getInt("lenx");
    // } else {
    len = (Screen.width - 20) ~/ coverWidth;
    if (((Screen.width - 20) % coverWidth) < (len - 1) * 5) {
      len -= 1;
    }
    SpUtil.putInt("lenx", len);
    // }
    //不满4的倍数填充container
    int z = wds.length < len ? len - wds.length : len - wds.length % len;
    if (z != 0) {
      for (var i = 0; i < z; i++) {
        wds.add(Container(
          width: coverWidth,
        ));
      }
    }
    return wds;
  }

  //书架列表模式
  Widget listModel() {
    return AnimationLimiter(
      child: ListView.builder(
          itemExtent: (20 + picHeight),
          itemCount: _shelfModel.shelf.length,
          itemBuilder: (context, i) {
            return AnimationConfiguration.staggeredList(
              position: i,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: GestureDetector(
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
                  ),
                ),
              ),
            );
          }),
    );
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
    _shelfModel.upToTop(b, i);
  }

  getBookItemView(Book item, int i) {
    return Container(
      child: Dismissible(
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
                          alignment: AlignmentDirectional.topEnd,
                          children: <Widget>[
                            PicWidget(
                              item.Img,
                              height: picHeight,
                              width: Screen.width / 4 - 10,
                            ),
                            Offstage(
                              offstage: item.NewChapterCount != 1,
                              child: Align(
                                alignment: Alignment.topRight,
                                child: Image.asset(
                                  'images/h6.png',
                                  width: 30,
                                  height: 30,
                                ),
                              ),
                            ),
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
                        padding: const EdgeInsets.only(left: 10.0, right: 10),
                        child: Text(
                          item.Name,
                          style: TextStyle(
                              fontSize: 18.0, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        width: ScreenUtil.getScreenW(context) - 120,
                        padding: const EdgeInsets.only(left: 10.0, right: 10),
                        child: Text(
                          item.Author,
                          style: TextStyle(
                            fontSize: 12.0,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(left: 10.0, right: 10),
                        child: Text(
                          item.LastChapter,
                          style: TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        width: ScreenUtil.getScreenW(context) - 120,
                      ),
                      Container(
                        padding: const EdgeInsets.only(left: 10.0, right: 10),
                        child: Text(item?.UTime ?? '',
                            style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Offstage(
              offstage: this.widget.type != "sort",
              child: Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      margin: EdgeInsets.only(left: 20),
                      height: 115,
                      width: ScreenUtil.getScreenW(context),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Image.asset(
                          'images/pick.png',
                          color: !_shelfModel.picks(i)
                              ? Colors.white
                              : Theme.of(context).primaryColor,
                          width: 30,
                          height: 30,
                        ),
                      ),
                    ),
                    onTap: () {
                      _shelfModel.changePick(i);
                    },
                  )),
            )
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
      ),
    );
  }
}
