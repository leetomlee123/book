import 'dart:convert';

import 'package:book/common/pic_widget.dart';
import 'package:book/common/app_colors.dart';
import 'package:book/common/common.dart';
import 'package:book/common/local_store.dart';
import 'package:book/model/search_model.dart';
import 'package:book/route/routes.dart';
import 'package:book/store/providers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Search extends ConsumerStatefulWidget {
  final String type;
  final String name;

  /// When true, hosted inside [MainShell] — no back button, keep state.
  final bool embedded;

  const Search(this.type, this.name, {super.key, this.embedded = false});

  @override
  ConsumerState<Search> createState() {
    return _SearchState();
  }
}

class _SearchState extends ConsumerState<Search> {
  late SearchModel searchModel;
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(searchModelProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? AppColors.scaffoldDark : AppColors.scaffold,
      appBar: AppBar(
        title: buildSearchWidget(),
        elevation: 0,
        automaticallyImplyLeading: !widget.embedded,
        titleSpacing: widget.embedded ? AppDimens.pagePadding : 0,
      ),
      body: d.showResult ? resultWidget(d) : suggestionWidget(d),
    );
  }

  @override
  void dispose() {
    // Keep SearchModel state when embedded in MainShell tabs.
    if (!widget.embedded) {
      try {
        searchModel.clear();
      } catch (_) {}
    }
    // Don't dispose controller if SearchModel still holds it (embedded tab).
    if (!widget.embedded) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Non-listening read only — do not mutate / notify here (Riverpod forbids
    // provider updates while the tree is building).
    searchModel = ref.read(searchModelProvider);
    if (widget.type == "book" && widget.name != "") {
      controller.text = widget.name;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      initModel();
    });
  }

  void initModel() {
    // Safe to mutate SearchModel after the first frame.
    searchModel.context = context;
    searchModel.controller = controller;
    searchModel.historyKey = PrefsKeys.bookSearchHistory;
    searchModel.initHistory();
  }

  Widget buildSearchWidget() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: AppDimens.searchBarHeight,
      decoration: BoxDecoration(
        color: dark ? AppColors.surfaceDark : const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        onSubmitted: (word) {
          searchModel.search(word);
        },
        onChanged: (value) async {
          setState(() {});
        },
        style: const TextStyle(fontSize: 14, height: 1.2),
        autofocus: false,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          hintStyle: TextStyle(
            fontSize: 14,
            color: AppColors.textTertiary,
          ),
          prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textSecondary),
          prefixIconConstraints: const BoxConstraints(minWidth: 36),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                  onPressed: () {
                    controller.text = "";
                    searchModel.reset();
                    setState(() {});
                  },
                ),
          hintText: "搜索书名或作者",
        ),
      ),
    );
  }

  Widget resultWidget(SearchModel model) {
    // book_pic_width may never have been written; 0 makes itemExtent 0 → blank list.
    var picW = SpUtil.getDouble(PrefsKeys.bookPicWidth, defValue: .0);
    if (picW <= 0) {
      picW = 72;
    }
    final picH = picW / .65;
    final rowH = picH + 20; // vertical padding 10*2
    return _resultBody(model, picW, picH, rowH);
  }

  Widget _resultBody(
    SearchModel model,
    double picW,
    double picH,
    double rowH,
  ) {
    // First-page search in flight — show spinner, not "empty".
    if (model.loading && model.bks.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 140),
          Center(child: CupertinoActivityIndicator(radius: 14)),
          SizedBox(height: 16),
          Center(
            child: Text(
              '正在搜索书源…',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
        ],
      );
    }
    if (model.bks.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(
            child: Text(
              '暂无搜索结果',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
        ],
      );
    }

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
        // +1 footer row when loading more / no more.
        itemCount: model.bks.length + (showFooter ? 1 : 0),
        itemBuilder: (c, i) {
          if (i >= model.bks.length) {
            return SizedBox(
              height: rowH,
              child: Center(
                child: model.loading
                    ? const CupertinoActivityIndicator()
                    : const Text(
                        '到底了',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
              ),
            );
          }
          var item = model.bks[i];
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              final b = await model.openDetail(item);
              if (b == null || !mounted) return;
              Routes.navigateTo(context, Routes.detail,
                  params: {"detail": jsonEncode(b)});
            },
            child: Container(
              height: rowH,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimens.coverRadius),
                    child: PicWidget(
                      item.coverUrl,
                      width: picW,
                      height: picH,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            item.name,
                            style: const TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary),
                            maxLines: 1,
                          ),
                          Text(
                            item.author,
                            style: const TextStyle(
                              fontSize: 12.0,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                          ),
                          Text(
                            item.description.isEmpty ? "暂无简介" : item.description,
                            style: const TextStyle(
                              fontSize: 12.0,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                          ),
                          Row(
                            children: [
                              if (item.sourceName.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandSoft,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.sourceName,
                                    style: const TextStyle(
                                        fontSize: 11, color: AppColors.brand),
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  item.latestChapter,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textTertiary),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
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
        },
      ),
    );
  }

  Widget suggestionWidget(SearchModel model) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                const Text(
                  '搜索历史',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const ImageIcon(
                    AssetImage("images/clear.png"),
                    size: 18,
                  ),
                  onPressed: () {
                    model.clearHistory();
                  },
                )
              ],
            ),
            Wrap(
              spacing: 10,
              children: model.getHistory(),
            ),
          ],
        ),
      ),
    );
  }
}
