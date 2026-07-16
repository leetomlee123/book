import 'dart:convert';

import 'package:book/common/Screen.dart';
import 'package:book/common/app_colors.dart';
import 'package:book/common/common.dart';
import 'package:book/common/local_store.dart';
import 'package:book/entity/Book.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:book/widgets/has_update_icon_img.dart';
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
  Widget? body;
  late RefreshController _refreshController;
  late ShelfModel _shelfModel;
  late bool isShelf;

  final double aspectRatioList = 0.69;
  final double aspectRatioCover = AppDimens.coverAspect;

  @override
  void initState() {
    super.initState();
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

  double get _coverWidth {
    final pad = AppDimens.pagePadding * 2;
    final gaps = AppDimens.shelfSpacing * (AppDimens.shelfColumns - 1);
    return (Screen.width - pad - gaps) / AppDimens.shelfColumns;
  }

  double get _coverHeight => _coverWidth / aspectRatioCover;

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
        enablePullDown: true,
        footer: CustomFooter(
          builder: (BuildContext context, LoadStatus? mode) {
            if (mode == LoadStatus.idle) {
            } else if (mode == LoadStatus.loading) {
              body = CupertinoActivityIndicator();
            } else if (mode == LoadStatus.failed) {
              body = Text("加载失败！点击重试！");
            } else if (mode == LoadStatus.canLoading) {
              body = Text("松手,加载更多!");
            } else {
              body = Text(DateUtil.formatDate(DateTime.now(),
                  format: DateFormats.full));
            }
            return Center(
              child: body,
            );
          },
        ),
        controller: _refreshController,
        onRefresh: freshShelf,
        child: _shelfModel.shelf.isEmpty
            ? _emptyShelf()
            : Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppDimens.pagePadding),
                child: _shelfModel.cover ? coverModel() : listModel(),
              ));
  }

  Widget _emptyShelf() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_outlined,
              size: 56, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text(
            '书架空空如也',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            '去搜索添加喜欢的书吧',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
          ),
        ],
      ),
    );
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

  //书架封面模式 — 3 列网格 + 软阴影 + 进度文案
  Widget coverModel() {
    final w = _coverWidth;
    final h = _coverHeight;
    return GridView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppDimens.shelfColumns,
        crossAxisSpacing: AppDimens.shelfSpacing,
        mainAxisSpacing: AppDimens.shelfRunSpacing,
        // cover + title + progress
        childAspectRatio: w / (h + 48),
      ),
      itemCount: _shelfModel.shelf.length,
      itemBuilder: (context, i) {
        final book = _shelfModel.shelf[i];
        return bookAction(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimens.coverRadius),
                  boxShadow: AppShadows.cover,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimens.coverRadius),
                  child: HasUpdateIconImg(w, h, this.widget.type, i),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                book.Name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _progressLabel(book),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          i,
        );
      },
    );
  }

  String _progressLabel(Book book) {
    final name = book.ChapterName.isNotEmpty
        ? book.ChapterName
        : (book.LastChapter.isNotEmpty ? book.LastChapter : '');
    if (name.isEmpty) return '未开始阅读';
    return '读到 · $name';
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

  //书架列表模式
  Widget listModel() {
    final w = _coverWidth * 0.85;
    final h = w / aspectRatioList;
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: _shelfModel.shelf.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 12),
      itemBuilder: (c, i) => bookAction(getBookItemView(i, w, h), i),
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

  getBookItemView(int i, double coverW, double coverH) {
    Book item = _shelfModel.shelf[i];
    return Dismissible(
      key: Key(item.Id.toString()),
      child: Container(
        height: coverH + 16,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.coverRadius),
              child: HasUpdateIconImg(
                  coverW, coverH, this.widget.type, i),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.Name,
                      style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                      maxLines: 1,
                    ),
                    Text(
                      item.Author,
                      style: const TextStyle(
                        fontSize: 12.0,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                    ),
                    Text(
                      _progressLabel(item),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (item.UTime.isNotEmpty)
                      Text(
                        item.UTime,
                        style: const TextStyle(
                            color: AppColors.textTertiary, fontSize: 11),
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
        color: AppColors.danger.withValues(alpha: 0.15),
        child: const ListTile(
          leading: Icon(Icons.delete, color: AppColors.danger),
        ),
      ),
    );
  }
}
