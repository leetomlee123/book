import 'dart:convert';

import 'package:book/common/PicWidget.dart';
import 'package:book/common/app_colors.dart';
import 'package:book/common/common.dart';
import 'package:book/common/local_store.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/SearchModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class Search extends StatefulWidget {
  final String type;
  final String name;

  /// When true, hosted inside [MainShell] — no back button, keep state.
  final bool embedded;

  Search(this.type, this.name, {this.embedded = false});

  @override
  State<StatefulWidget> createState() {
    return _SearchState();
  }
}

class _SearchState extends State<Search> {
  late SearchModel searchModel;
  ColorModel? value;
  Widget? body;
  late GlobalKey textFieldKey;
  TextEditingController controller = TextEditingController();
  OverlayEntry? searchSuggest;
  OverlayState? overlayState;
  double aiItemH = 40;
  double? height;

  double? width;

  double? xPosition;

  double? yPosition;

  @override
  Widget build(BuildContext context) {
    value = Store.value<ColorModel>(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? AppColors.scaffoldDark : AppColors.scaffold,
      appBar: AppBar(
        title: buildSearchWidget(),
        elevation: 0,
        automaticallyImplyLeading: !widget.embedded,
        titleSpacing: widget.embedded ? AppDimens.pagePadding : 0,
      ),
      body:
          Store.connect<SearchModel>(builder: (context, SearchModel d, child) {
        // Prefer the watched model so rebuilds stay in sync with the provider.
        return d.showResult ? resultWidget(d) : suggestionWidget(d);
      }),
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
  void deactivate() {
    super.deactivate();
    removeOverlay();
  }

  @override
  void initState() {
    super.initState();
    overlayState = Overlay.of(context);
    textFieldKey = GlobalKey();
    // Non-listening read only — do not mutate / notify here (Riverpod forbids
    // provider updates while the tree is building).
    searchModel = Store.value<SearchModel>(context);
    if (widget.type == "book" && widget.name != "") {
      controller.text = widget.name;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      initModel();
    });
  }

  Future<void> initModel() async {
    // Safe to mutate SearchModel after the first frame.
    // Don't clobber an in-flight / finished search if the user typed quickly.
    if (!searchModel.showResult && searchModel.word.isEmpty) {
      searchModel.showResult = false;
    }
    searchModel.context = context;
    searchModel.textFieldKey = textFieldKey;
    searchModel.controller = controller;
    searchModel.store_word = Common.book_search_history;
    searchModel.initHistory();
    findOverLayPosition();
    await searchModel.initBookHot();
    if (!mounted) return;
    // Skip hot-list notify if results are already on screen.
    if (!searchModel.showResult) {
      searchModel.getHot();
    }
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
        key: textFieldKey,
        controller: controller,
        onSubmitted: (word) {
          removeOverlay();
          searchModel.search(word);
        },
        onChanged: (value) async {
          removeOverlay();
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
                    removeOverlay();
                    setState(() {});
                  },
                ),
          hintText: "搜索书名或作者",
        ),
      ),
    );
  }

  void removeOverlay() {
    searchSuggest?.remove();
    searchSuggest = null;
  }

  void findOverLayPosition() {
    final renderObject = textFieldKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return;
    height = renderObject.size.height;
    width = renderObject.size.width;

    Offset offset = renderObject.localToGlobal(Offset.zero);
    xPosition = offset.dx;

    yPosition = offset.dy;
  }

  Widget resultWidget(SearchModel model) {
    // book_pic_width may never have been written; 0 makes itemExtent 0 → blank list.
    var picW = SpUtil.getDouble(Common.book_pic_width, defValue: .0);
    if (picW <= 0) {
      picW = 72;
    }
    final picH = picW / .65;
    final rowH = picH + 20; // vertical padding 10*2
    return SmartRefresher(
        enablePullDown: true,
        enablePullUp: true,
        header: WaterDropHeader(),
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
              body = Text("到底了!");
            }
            return Center(
              child: body,
            );
          },
        ),
        controller: model.refreshController,
        onRefresh: model.onRefresh,
        onLoading: model.onLoading,
        child: model.bks.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('暂无搜索结果')),
                ],
              )
            : ListView.builder(
          itemExtent: rowH,
          itemCount: model.bks.length,
          itemBuilder: (c, i) {
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: <Widget>[
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppDimens.coverRadius),
                      child: PicWidget(
                        item.Img,
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
                              item.Desc.isEmpty ? "暂无简介" : item.Desc,
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
                                          fontSize: 11,
                                          color: AppColors.brand),
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    item.LastChapter,
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
        ));
  }

  Widget suggestionWidget(SearchModel model) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  '搜索历史',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: Container(),
                ),
                IconButton(
                  icon: ImageIcon(
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
              spacing: 10, //主轴上子控件的间距
              children: model.getHistory(),
            ),
            Row(
              children: <Widget>[
                Text(
                  '书源提示',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: () {
                    model.getHot();
                  },
                )
              ],
            ),
            Wrap(
              spacing: 10, //主轴上子控件的间距
              children: model.showHot,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant Search oldWidget) {
    super.didUpdateWidget(oldWidget);
  }
}
