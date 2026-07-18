import 'package:book/common/app_colors.dart';
import 'package:book/store/Store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ChapterView extends ConsumerStatefulWidget {
  const ChapterView({super.key});

  @override
  ConsumerState<ChapterView> createState() => _ChapterViewItem();
}

class _ChapterViewItem extends ConsumerState<ChapterView> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  bool showToTopBtn = false;
  bool _centeredOnce = false;

  @override
  void initState() {
    super.initState();
    _itemPositionsListener.itemPositions.addListener(_onPositionsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerCurrentChapter();
    });
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onPositionsChanged);
    super.dispose();
  }

  void _onPositionsChanged() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;
    final minIndex =
        positions.map((e) => e.index).reduce((a, b) => a < b ? a : b);
    final next = minIndex >= 8;
    if (next != showToTopBtn && mounted) {
      setState(() => showToTopBtn = next);
    }
  }

  /// [alignment] 0=顶 0.5=中 1=底（scrollable_positioned_list 约定）。
  void _jumpTo(int index, {double alignment = 0}) {
    if (!_itemScrollController.isAttached) return;
    final chapters = ref.read(readModelProvider).chapters;
    if (chapters.isEmpty) return;
    _itemScrollController.jumpTo(
      index: index.clamp(0, chapters.length - 1),
      alignment: alignment,
    );
  }

  Future<void> _scrollTo(int index, {double alignment = 0}) async {
    if (!_itemScrollController.isAttached) return;
    final chapters = ref.read(readModelProvider).chapters;
    if (chapters.isEmpty) return;
    await _itemScrollController.scrollTo(
      index: index.clamp(0, chapters.length - 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      alignment: alignment,
    );
  }

  /// 打开目录时把当前章节滚到可视区域中间。
  void _centerCurrentChapter() {
    final model = ref.read(readModelProvider);
    final chapters = model.chapters;
    if (chapters.isEmpty || !_itemScrollController.isAttached) return;
    final cur = (model.book?.cur ?? 0).clamp(0, chapters.length - 1);
    _jumpTo(cur, alignment: 0.5);
    _centeredOnce = true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = ref.watch(readModelProvider);
    final chapters = data.chapters;
    final cur = data.book?.cur ?? 0;

    // 目录异步到位后，再居中一次当前章（首帧可能还是空列表）。
    if (!_centeredOnce && chapters.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _centeredOnce) return;
        _centerCurrentChapter();
      });
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: data.chaptersLoading && chapters.isEmpty
                  ? Center(
                      child: Text(
                        data.loadingHint.isEmpty
                            ? '正在加载目录…'
                            : data.loadingHint,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : chapters.isEmpty
                      ? Center(
                          child: Text(
                            '暂无章节',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : ScrollablePositionedList.builder(
                          itemScrollController: _itemScrollController,
                          itemPositionsListener: _itemPositionsListener,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: chapters.length,
                          itemBuilder: (context, index) {
                            final chapter = chapters[index];
                            final selected = index == cur;
                            final cached = chapter.hasContent == '2';
                            return _ChapterTile(
                              index: index,
                              title: chapter.chapterName,
                              selected: selected,
                              cached: cached,
                              onTap: () {
                                Navigator.of(context).pop();
                                data.book!.cur = index;
                                Future.delayed(
                                  const Duration(milliseconds: 400),
                                  () async {
                                    await data.initPageContent(index, true);
                                  },
                                );
                              },
                            );
                          },
                        ),
            ),
            _BottomBar(
              showToTop: showToTopBtn,
              reloading: data.chaptersLoading,
              onReload: data.chaptersLoading ? null : refresh,
              onJump: data.chaptersLoading ? null : topOrBottom,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> topOrBottom() async {
    final chapters = ref.read(readModelProvider).chapters;
    if (chapters.isEmpty) return;
    if (showToTopBtn) {
      await _scrollTo(0);
    } else {
      await _scrollTo(chapters.length - 1);
    }
  }

  Future<void> refresh() async {
    final model = ref.read(readModelProvider);
    await model.reloadChapters();
    if (!mounted) return;
    final chapters = model.chapters;
    if (chapters.isEmpty) return;
    final last = chapters.length - 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollTo(last);
    });
  }
}

class _ChapterTile extends StatelessWidget {
  final int index;
  final String title;
  final bool selected;
  final bool cached;
  final VoidCallback onTap;

  const _ChapterTile({
    required this.index,
    required this.title,
    required this.selected,
    required this.cached,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor = selected ? AppColors.brand : AppColors.textPrimary;
    final indexColor = selected ? AppColors.brand : AppColors.textTertiary;

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: selected ? AppColors.brandSoft : null,
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                '${index + 1}',
                textAlign: TextAlign.left,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: indexColor,
                  fontSize: 12,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: titleColor,
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  height: 1.3,
                ),
              ),
            ),
            if (cached)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  '已缓存',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final bool showToTop;
  final bool reloading;
  final VoidCallback? onReload;
  final VoidCallback? onJump;

  const _BottomBar({
    required this.showToTop,
    this.reloading = false,
    required this.onReload,
    required this.onJump,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: theme.scaffoldBackgroundColor,
      elevation: 0,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 0.5),
          ),
        ),
        padding: EdgeInsets.fromLTRB(8, 4, 8, 4 + bottom),
        child: reloading
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    '正在重新加载目录…',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            : Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: onReload,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('重新加载'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(width: 0.5, height: 20, color: AppColors.divider),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: onJump,
                      icon: Icon(
                        showToTop
                            ? Icons.vertical_align_top
                            : Icons.vertical_align_bottom,
                        size: 18,
                      ),
                      label: Text(showToTop ? '回到顶部' : '回到底部'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
