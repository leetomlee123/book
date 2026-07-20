import 'dart:convert';

import 'package:book/common/pic_widget.dart';
import 'package:book/common/app_colors.dart';
import 'package:book/entity/search_item.dart';
import 'package:book/model/explore_model.dart';
import 'package:book/route/routes.dart';
import 'package:book/store/providers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom-tab discovery page driven by book-source `exploreUrl` / `ruleExplore`.
class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(exploreModelProvider).ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final model = ref.watch(exploreModelProvider);

    return Scaffold(
      backgroundColor: dark ? AppColors.scaffoldDark : AppColors.scaffold,
      appBar: AppBar(
        title: Text(
          '发现',
          style: TextStyle(
            color: dark ? AppColors.textOnDark : AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: dark ? AppColors.scaffoldDark : AppColors.scaffold,
        foregroundColor: dark ? AppColors.textOnDark : AppColors.textPrimary,
        iconTheme: IconThemeData(
          color: dark ? AppColors.textOnDark : AppColors.textPrimary,
        ),
        actions: [
          IconButton(
            tooltip: '搜索',
            icon: const Icon(Icons.search),
            onPressed: () {
              Routes.navigateTo(context, Routes.search, params: {
                'type': 'book',
                'name': '',
              });
            },
          ),
          IconButton(
            tooltip: '刷新书源',
            icon: const Icon(Icons.refresh),
            onPressed: () => model.reloadSources(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SourceBar(model: model, dark: dark),
          if (model.kinds.length > 1) _KindBar(model: model, dark: dark),
          Divider(
            height: 1,
            color: dark ? AppColors.dividerDark : AppColors.divider,
          ),
          Expanded(child: _BookList(model: model, dark: dark)),
        ],
      ),
    );
  }
}

class _SourceBar extends StatelessWidget {
  final ExploreModel model;
  final bool dark;
  const _SourceBar({required this.model, required this.dark});

  @override
  Widget build(BuildContext context) {
    if (model.exploreSources.isEmpty) {
      return const SizedBox.shrink();
    }
    final accent = AppColors.accentOf(context);
    final accentSoft = AppColors.accentSoftOf(context);
    final unselected = dark ? AppColors.textOnDark : AppColors.textSecondary;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: model.exploreSources.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final s = model.exploreSources[i];
          final selected =
              model.activeSource?.bookSourceUrl == s.bookSourceUrl;
          return ChoiceChip(
            label: Text(s.bookSourceName.isEmpty ? s.bookSourceUrl : s.bookSourceName),
            selected: selected,
            onSelected: (_) => model.selectSource(s),
            selectedColor: accentSoft,
            backgroundColor:
                dark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F3F3),
            side: BorderSide.none,
            labelStyle: TextStyle(
              fontSize: 12,
              color: selected ? accent : unselected,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
      ),
    );
  }
}

class _KindBar extends StatelessWidget {
  final ExploreModel model;
  final bool dark;
  const _KindBar({required this.model, required this.dark});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentOf(context);
    final accentSoft = AppColors.accentSoftOf(context);
    final unselected = dark ? AppColors.textOnDark : AppColors.textSecondary;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
        itemCount: model.kinds.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final k = model.kinds[i];
          final selected = model.activeKind?.title == k.title &&
              model.activeKind?.url == k.url;
          return FilterChip(
            label: Text(k.title),
            selected: selected,
            onSelected: (_) => model.selectKind(k),
            selectedColor: accentSoft,
            backgroundColor:
                dark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F3F3),
            checkmarkColor: accent,
            side: BorderSide.none,
            labelStyle: TextStyle(
              fontSize: 12,
              color: selected ? accent : unselected,
            ),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
      ),
    );
  }
}

class _BookList extends StatelessWidget {
  final ExploreModel model;
  final bool dark;
  const _BookList({required this.model, required this.dark});

  @override
  Widget build(BuildContext context) {
    final primary = dark ? AppColors.textOnDark : AppColors.textPrimary;
    final secondary = AppColors.textSecondary;
    final tertiary = AppColors.textTertiary;

    if (model.loading && model.books.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CupertinoActivityIndicator(radius: 14),
            const SizedBox(height: 12),
            Text(
              '加载发现…',
              style: TextStyle(fontSize: 13, color: secondary),
            ),
          ],
        ),
      );
    }

    if (model.books.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                model.error ?? '暂无内容',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: secondary,
                ),
              ),
            ),
          ),
          if ((model.error ?? '').contains('书源'))
            Center(
              child: TextButton(
                onPressed: () =>
                    Routes.navigateTo(context, Routes.sources),
                child: const Text('去书源管理'),
              ),
            ),
        ],
      );
    }

    const picW = 72.0;
    final picH = picW / .65;
    final rowH = picH + 20;
    final showFooter = model.loading || model.noMore;

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
          model.loadMore();
        }
        return false;
      },
      child: ListView.builder(
        itemExtent: rowH,
        itemCount: model.books.length + (showFooter ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= model.books.length) {
            return SizedBox(
              height: rowH,
              child: Center(
                child: model.loading
                    ? const CupertinoActivityIndicator()
                    : Text(
                        '没有更多了',
                        style: TextStyle(
                          fontSize: 12,
                          color: tertiary,
                        ),
                      ),
              ),
            );
          }
          final item = model.books[i];
          return _BookRow(
            item: item,
            picW: picW,
            picH: picH,
            rowH: rowH,
            primary: primary,
            secondary: secondary,
            tertiary: tertiary,
            onTap: () async {
              final b = await model.openDetail(item);
              if (b == null || !context.mounted) return;
              Routes.navigateTo(
                context,
                Routes.detail,
                params: {'detail': jsonEncode(b)},
              );
            },
          );
        },
      ),
    );
  }
}

class _BookRow extends StatelessWidget {
  final SearchItem item;
  final double picW;
  final double picH;
  final double rowH;
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final VoidCallback onTap;

  const _BookRow({
    required this.item,
    required this.picW,
    required this.picH,
    required this.rowH,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: rowH,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.coverRadius),
              child: PicWidget(item.coverUrl, width: picW, height: picH),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                    Text(
                      item.author.isEmpty ? '未知作者' : item.author,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 12,
                        color: secondary,
                      ),
                    ),
                    Text(
                      item.description.isEmpty ? '暂无简介' : item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: secondary,
                      ),
                    ),
                    Row(
                      children: [
                        if (item.sourceName.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentSoftOf(context),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.sourceName,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.accentOf(context),
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            item.latestChapter,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: tertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
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
