import 'dart:convert';

import 'package:book/common/screen.dart';
import 'package:book/data/repositories/book_repository.dart';
import 'package:book/common/app_colors.dart';
import 'package:book/common/local_store.dart';
import 'package:book/entity/book.dart';
import 'package:book/model/shelf_model.dart';
import 'package:book/route/routes.dart';
import 'package:book/store/providers.dart';
import 'package:book/widgets/has_update_icon_img.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class BooksWidget extends ConsumerStatefulWidget {
  final String type;

  const BooksWidget(this.type, {super.key});

  @override
  ConsumerState<BooksWidget> createState() => _BooksWidgetState();
}

class _BooksWidgetState extends ConsumerState<BooksWidget> {
  late RefreshController _refreshController;
  late ShelfModel _shelfModel;
  late bool isShelf;

  final double aspectRatioList = 0.69;
  final double aspectRatioCover = AppDimens.coverAspect;

  @override
  void initState() {
    super.initState();
    isShelf = widget.type == '';
    _shelfModel = ref.read(shelfModelProvider);
    _refreshController = RefreshController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _shelfModel.context = context;
      if (isShelf) {
        _shelfModel.freshToken();
        _refreshController.requestRefresh();
      }
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  double get _coverWidth {
    final pad = AppDimens.pagePadding * 2;
    final gaps = AppDimens.shelfSpacing * (AppDimens.shelfColumns - 1);
    return (Screen.width - pad - gaps) / AppDimens.shelfColumns;
  }

  double get _coverHeight => _coverWidth / aspectRatioCover;

  bool get _dark => Theme.of(context).brightness == Brightness.dark;

  Color get _primary =>
      _dark ? AppColors.textOnDark : AppColors.textPrimary;

  @override
  Widget build(BuildContext context) {
    _shelfModel = ref.watch(shelfModelProvider);
    return SmartRefresher(
      enablePullDown: true,
      header: ClassicHeader(
        refreshingText: '刷新中…',
        completeText: '刷新完成',
        idleText: '下拉刷新',
        releaseText: '松开刷新',
        textStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        refreshingIcon: const CupertinoActivityIndicator(radius: 8),
      ),
      controller: _refreshController,
      onRefresh: freshShelf,
      child: _shelfModel.shelf.isEmpty
          ? _emptyShelf()
          : Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.pagePadding,
              ),
              child: _shelfModel.cover ? coverModel() : listModel(),
            ),
    );
  }

  Widget _emptyShelf() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.menu_book_outlined,
                size: 36,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '书架空空如也',
              style: TextStyle(
                color: _primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '去发现页或搜索添加喜欢的书吧',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            FilledButton.tonal(
              onPressed: () {
                Routes.navigateTo(context, Routes.search, params: {
                  'type': 'book',
                  'name': '',
                });
              },
              style: FilledButton.styleFrom(
                foregroundColor: AppColors.brand,
                backgroundColor: AppColors.brandSoft,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('去搜索'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> freshShelf() async {
    if (_shelfModel.shelf.isEmpty) {
      await _shelfModel.initShelf();
    }
    if (SpUtil.haveKey('auth')) {
      try {
        await _shelfModel.refreshShelf();
      } catch (_) {
        // ignore network refresh errors
      }
    } else {
      await _shelfModel.refreshShelf();
    }
    if (mounted) _refreshController.refreshCompleted();
  }

  // ---------------------------------------------------------------------------
  // Cover grid
  // ---------------------------------------------------------------------------

  Widget coverModel() {
    final w = _coverWidth;
    final h = _coverHeight;
    return GridView.builder(
      padding: const EdgeInsets.only(top: 14, bottom: 28),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppDimens.shelfColumns,
        crossAxisSpacing: AppDimens.shelfSpacing,
        mainAxisSpacing: AppDimens.shelfRunSpacing,
        // cover + title + progress
        childAspectRatio: w / (h + 52),
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
                  child: HasUpdateIconImg(w, h, widget.type, i),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _titleLabel(book),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: _primary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 3),
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
    final chapter = book.readingChapter.trim();
    final last = book.latestChapter.trim();
    final name = chapter.isNotEmpty
        ? chapter
        : (last.isNotEmpty ? last : '');
    if (name.isEmpty || name == 'null') return '未开始阅读';
    return '读到 · $name';
  }

  String _authorLabel(Book book) {
    final a = book.author.trim();
    if (a.isEmpty || a == 'null') return '佚名';
    return a;
  }

  String _titleLabel(Book book) {
    final n = book.name.trim();
    if (n.isEmpty || n == 'null') return '未知书名';
    return n;
  }

  Widget bookAction(Widget child, int i) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        widget.type == 'sort' ? _shelfModel.changePick(i) : await readBook(i);
      },
      onLongPress: () {
        Routes.navigateTo(context, Routes.sortShelf);
      },
      child: child,
    );
  }

  // ---------------------------------------------------------------------------
  // List mode
  // ---------------------------------------------------------------------------

  Widget listModel() {
    final w = _coverWidth * 0.9;
    final h = w / aspectRatioList;
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 28),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      itemCount: _shelfModel.shelf.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        indent: w + 16,
        color: _dark ? AppColors.dividerDark : AppColors.divider,
      ),
      itemBuilder: (c, i) => bookAction(getBookItemView(i, w, h), i),
    );
  }

  Future<void> readBook(int i) async {
    final b = _shelfModel.shelf[i];
    // Prefer durable DB progress over possibly-stale in-memory shelf object.
    Book openBook = b;
    try {
      final dbBook = await BookRepository.instance.getById(b.id);
      if (dbBook != null) {
        openBook = dbBook;
        // Keep shelf row in sync for labels / next open.
        b.chapterIndex = dbBook.chapterIndex;
        b.pageIndex = dbBook.pageIndex;
        b.scrollOffset = dbBook.scrollOffset;
        if (dbBook.readingChapter.isNotEmpty) {
          b.readingChapter = dbBook.readingChapter;
        }
      }
    } catch (_) {}
    if (!mounted) return;
    Routes.navigateTo(
      context,
      Routes.read,
      params: {'read': jsonEncode(openBook)},
    );
    _shelfModel.sort(i);
  }

  Widget getBookItemView(int i, double coverW, double coverH) {
    final item = _shelfModel.shelf[i];
    return Dismissible(
      key: Key(item.id.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _shelfModel.modifyShelf(item),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.danger,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        height: coverH + 20,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimens.coverRadius),
                boxShadow: AppShadows.cover,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.coverRadius),
                child: HasUpdateIconImg(coverW, coverH, widget.type, i),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12, right: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _titleLabel(item),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _authorLabel(item),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _progressLabel(item),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (item.updatedAt.isNotEmpty && item.updatedAt != 'null') ...[
                      const SizedBox(height: 4),
                      Text(
                        item.updatedAt,
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
