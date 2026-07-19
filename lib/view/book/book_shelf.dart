import 'package:book/common/screen.dart';
import 'package:book/common/app_colors.dart';
import 'package:book/common/common.dart';
import 'package:book/common/local_store.dart';
import 'package:book/route/routes.dart';
import 'package:book/store/providers.dart';
import 'package:book/widgets/books_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 书架（微信读书风格）
class BookShelf extends ConsumerStatefulWidget {
  const BookShelf({super.key});

  @override
  ConsumerState<BookShelf> createState() => _BookShelfState();
}

class _BookShelfState extends ConsumerState<BookShelf> {
  @override
  void initState() {
    super.initState();
    if (!SpUtil.containsKey(Common.top_safe_height)) {
      SpUtil.putDouble(Common.top_safe_height, Screen.topSafeHeight);
    }
    if (!SpUtil.containsKey(Common.shimmer_nums)) {
      SpUtil.putInt(
        Common.shimmer_nums,
        (Screen.height -
                Screen.topSafeHeight -
                Screen.bottomSafeHeight -
                60) ~/
            25,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final shelfModel = ref.watch(shelfModelProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final count = shelfModel.shelf.length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: dark ? AppColors.scaffoldDark : AppColors.scaffold,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _ShelfHeader(
                count: count,
                coverMode: shelfModel.cover,
                onSearch: () {
                  Routes.navigateTo(context, Routes.search, params: {
                    'type': 'book',
                    'name': '',
                  });
                },
                onToggleMode: shelfModel.toggleModel,
                onManage: () =>
                    Routes.navigateTo(context, Routes.sortShelf),
              ),
              Expanded(child: BooksWidget('')),
            ],
          ),
        ),
      ),
    );
  }
}

/// 顶栏：标题 + 数量 + 搜索 / 视图 / 整理
class _ShelfHeader extends StatelessWidget {
  final int count;
  final bool coverMode;
  final VoidCallback onSearch;
  final VoidCallback onToggleMode;
  final VoidCallback onManage;

  const _ShelfHeader({
    required this.count,
    required this.coverMode,
    required this.onSearch,
    required this.onToggleMode,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final onSurface = dark ? AppColors.textOnDark : AppColors.textPrimary;

    return Container(
      color: dark ? AppColors.surfaceDark : AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '书架',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: onSurface,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      count == 0 ? '暂无藏书' : '共 $count 本',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // _HeaderIcon(
              //   icon: Icons.search,
              //   tooltip: '搜索',
              //   onTap: onSearch,
              // ),
              _HeaderIcon(
                icon: coverMode
                    ? Icons.view_list_outlined
                    : Icons.grid_view_outlined,
                tooltip: coverMode ? '列表模式' : '封面模式',
                onTap: onToggleMode,
              ),
              _HeaderIcon(
                icon: Icons.checklist_rtl,
                tooltip: '书架整理',
                onTap: onManage,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 搜索入口条（微信读书感）
          Material(
            color: dark ? const Color(0xFF2A2A2A) : const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: onSearch,
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: AppDimens.searchBarHeight,
                child: Row(
                  children: const [
                    SizedBox(width: 12),
                    Icon(Icons.search, size: 18, color: AppColors.textTertiary),
                    SizedBox(width: 6),
                    Text(
                      '搜索书架或全网书籍',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 22,
        color: dark ? AppColors.textOnDark : AppColors.textPrimary,
      ),
    );
  }
}
