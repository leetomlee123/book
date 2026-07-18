import 'dart:convert';

import 'package:book/common/DbHelper.dart';
import 'package:book/common/PicWidget.dart';
import 'package:book/common/Screen.dart';
import 'package:book/common/app_colors.dart';
import 'package:book/common/local_store.dart';
import 'package:book/entity/Book.dart';
import 'package:book/entity/BookInfo.dart';
import 'package:book/event/event.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/book/SourceSwitchSheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:readmore/readmore.dart';

/// 书籍详情（微信读书风格）
class BookDetail extends ConsumerStatefulWidget {
  final BookInfo _bookInfo;

  BookDetail(this._bookInfo);

  @override
  ConsumerState<BookDetail> createState() => _BookDetailState();
}

class _BookDetailState extends ConsumerState<BookDetail> {
  late Book book;

  BookInfo get info => widget._bookInfo;

  @override
  void initState() {
    super.initState();
    book = info.toBook();
  }

  bool get _dark => SpUtil.getBool('dark');

  Color get _scaffold =>
      _dark ? AppColors.scaffoldDark : AppColors.scaffold;
  Color get _surface => _dark ? AppColors.surfaceDark : AppColors.surface;
  Color get _primary =>
      _dark ? AppColors.textOnDark : AppColors.textPrimary;
  Color get _secondary => AppColors.textSecondary;
  Color get _divider =>
      _dark ? AppColors.dividerDark : AppColors.divider;

  @override
  Widget build(BuildContext context) {
    final bottomBarH = AppDimens.ctaHeight + Screen.bottomSafeHeight + 20;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _scaffold,
        body: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _heroCard(),
                      const SizedBox(height: 12),
                      _sectionCard(
                        title: '简介',
                        child: _descBody(),
                      ),
                      const SizedBox(height: 12),
                      _sectionCard(
                        title: '目录',
                        trailing: Text(
                          '查看',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.brand,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTrailingTap: _openRead,
                        child: _catalogBody(),
                      ),
                      if (info.SameAuthorBooks.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _sectionCard(
                          title: '作者还写过',
                          child: _sameAuthorBody(),
                        ),
                      ],
                      SizedBox(height: bottomBarH + 16),
                    ],
                  ),
                ),
              ],
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // App bar (plain, no colored / blurred header)
  // ---------------------------------------------------------------------------

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: _scaffold,
      foregroundColor: _primary,
      systemOverlayStyle:
          _dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).popUntil(ModalRoute.withName('/'));
            eventBus.fire(NavEvent(0));
          },
          child: Text(
            '书架',
            style: TextStyle(color: _primary, fontSize: 15),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Hero card (cover + meta)
  // ---------------------------------------------------------------------------

  Widget _heroCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.pagePadding),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        boxShadow: AppShadows.softBar,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimens.coverRadius),
              boxShadow: AppShadows.cover,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.coverRadius),
              child: PicWidget(book.Img, height: 128, width: 92),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                _displayText(book.Name, fallback: '未知书名'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: _primary,
                ),
              ),
                const SizedBox(height: 8),
                _metaRow(
                  Icons.person_outline,
                  _displayText(book.Author, fallback: '佚名'),
                ),
                if (_hasText(book.CName)) ...[
                  const SizedBox(height: 4),
                  _metaRow(Icons.category_outlined, book.CName.trim()),
                ],
                if (_hasText(book.originName)) ...[
                  const SizedBox(height: 4),
                  _metaRow(Icons.cloud_outlined, book.originName.trim()),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (info.BookStatus.isNotEmpty)
                      _chip(
                        info.BookStatus,
                        bg: AppColors.brandSoft,
                        fg: AppColors.brand,
                      ),
                    if (info.Rate > 0)
                      _chip(
                        '${info.Rate.toStringAsFixed(1)} 分',
                        bg: const Color(0x1AFA9D3B),
                        fg: const Color(0xFFFA9D3B),
                      ),
                    if (info.Count > 0)
                      _chip(
                        '${_formatCount(info.Count)} 人气',
                        bg: _dark
                            ? const Color(0x22FFFFFF)
                            : const Color(0x0F000000),
                        fg: _secondary,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _secondary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: _secondary, height: 1.2),
          ),
        ),
      ],
    );
  }

  Widget _chip(String text, {required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w500),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section card shell
  // ---------------------------------------------------------------------------

  Widget _sectionCard({
    required String title,
    required Widget child,
    Widget? trailing,
    VoidCallback? onTrailingTap,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.pagePadding),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _primary,
                ),
              ),
              const Spacer(),
              if (trailing != null)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTrailingTap,
                  child: trailing,
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Description
  // ---------------------------------------------------------------------------

  Widget _descBody() {
    final desc = info.Desc.trim();
    if (desc.isEmpty) {
      return Text(
        '暂无简介',
        style: TextStyle(fontSize: 14, color: _secondary, height: 1.6),
      );
    }
    return ReadMoreText(
      desc,
      trimLines: 4,
      trimMode: TrimMode.Line,
      colorClickableText: AppColors.brand,
      trimCollapsedText: ' 展开',
      trimExpandedText: ' 收起',
      style: TextStyle(
        fontSize: 14,
        height: 1.7,
        color: _primary.withValues(alpha: 0.88),
      ),
      moreStyle: const TextStyle(
        fontSize: 14,
        color: AppColors.brand,
        fontWeight: FontWeight.w500,
      ),
      lessStyle: const TextStyle(
        fontSize: 14,
        color: AppColors.brand,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Catalog / latest chapter
  // ---------------------------------------------------------------------------

  Widget _catalogBody() {
    final latest = info.LastChapter.trim();
    final time = info.LastTime.trim();
    return InkWell(
      onTap: _openRead,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.menu_book_outlined,
                size: 18,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    latest.isEmpty ? '暂无章节信息' : latest,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _primary,
                    ),
                  ),
                  if (time.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '更新于 $time',
                      style: TextStyle(fontSize: 12, color: _secondary),
                    ),
                  ] else
                    Text(
                      '最新章节',
                      style: TextStyle(fontSize: 12, color: _secondary),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: _secondary, size: 20),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Same author
  // ---------------------------------------------------------------------------

  Widget _sameAuthorBody() {
    final list = info.SameAuthorBooks;
    return Column(
      children: [
        for (var i = 0; i < list.length; i++) ...[
          if (i > 0)
            Divider(height: 1, color: _divider),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppDimens.coverRadius),
                  child: PicWidget(
                    list[i].Img,
                    height: 72,
                    width: 52,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayText(list[i].Name, fallback: '未知书名'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _displayText(list[i].Author, fallback: '佚名'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: _secondary),
                      ),
                      if (_hasText(list[i].LastChapter)) ...[
                        const SizedBox(height: 4),
                        Text(
                          list[i].LastChapter.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom action bar
  // ---------------------------------------------------------------------------

  Widget _buildBottomBar() {
    final model = ref.watch(shelfModelProvider);
    final inShelf = model.inShelf(info.Id);
    final hasRead = SpUtil.haveKey(book.Id);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          boxShadow: [
            BoxShadow(
              color: const Color(0x14000000),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
          12,
          10,
          12,
          Screen.bottomSafeHeight + 10,
        ),
        child: Row(
          children: [
            _barIconBtn(
              icon: inShelf
                  ? Icons.bookmark_remove_outlined
                  : Icons.bookmark_add_outlined,
              label: inShelf ? '移出' : '书架',
              onTap: () {
                SpUtil.putString(book.Id, '');
                model.modifyShelf(book);
              },
            ),
            _barIconBtn(
              icon: Icons.swap_horiz,
              label: '换源',
              onTap: () {
                final readModel = ref.read(readModelProvider);
                readModel.book = book;
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => SourceSwitchSheet(readModel: readModel),
                );
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: AppDimens.ctaHeight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  onPressed: _openRead,
                  child: Text(
                    hasRead ? '继续阅读' : '立即阅读',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barIconBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: _primary),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: _secondary),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _openRead() async {
    Book? b = await DbHelper.instance.getBook(book.Id);
    if (!mounted) return;
    Routes.navigateTo(
      context,
      Routes.read,
      params: {
        'read': jsonEncode(b ?? book),
      },
    );
  }

  String _formatCount(int n) {
    if (n >= 10000) {
      final v = n / 10000;
      return v >= 10 ? '${v.toStringAsFixed(0)}万' : '${v.toStringAsFixed(1)}万';
    }
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}k';
    }
    return '$n';
  }

  bool _hasText(String? s) {
    if (s == null) return false;
    final t = s.trim();
    return t.isNotEmpty && t != 'null';
  }

  String _displayText(String? s, {String fallback = ''}) {
    if (!_hasText(s)) return fallback;
    return s!.trim();
  }
}
