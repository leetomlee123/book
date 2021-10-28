import 'dart:convert';

import 'package:book/common/Http.dart';
import 'package:book/common/PicWidget.dart';
import 'package:book/common/common.dart';
import 'package:book/entity/BookInfo.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/SearchModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:book/widgets/SearchAiItem.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:keframe/frame_separate_widget.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class Search extends StatefulWidget {
  final String type;
  final String name;

  Search(this.type, this.name);

  @override
  State<StatefulWidget> createState() {
    return _SearchState();
  }
}

class _SearchState extends State<Search> {
  SearchModel searchModel;
  ColorModel value;
  Widget body;
  GlobalKey textFieldKey;
  TextEditingController controller = TextEditingController();
  OverlayEntry searchSuggest;
  OverlayState overlayState;
  double aiItemH = 40;
  double height;

  double width;

  double xPosition;

  double yPosition;

  @override
  Widget build(BuildContext context) {
    value = Store.value<ColorModel>(context);
    return Scaffold(
      appBar: AppBar(
        title: buildSearchWidget(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        // actions: [TextButton(
       
        //   onPressed: () {
        //     Navigator.pop(context);
        //   }, child: Text("返回"),
        // )],
      ),
      body:
          Store.connect<SearchModel>(builder: (context, SearchModel d, child) {
        return d.showResult ? resultWidget() : suggestionWidget(d);
      }),
    );
  }

  @override
  void dispose() {
    super.dispose();
    searchModel.clear();
    controller?.dispose();
  }

  @override
  void deactivate() {
    super.deactivate();
    removeOverlay();
  }

  @override
  void initState() {
    overlayState = Overlay.of(context);
    textFieldKey = GlobalKey();
    super.initState();
    if (this.widget.type == "book" && this.widget.name != "") {
      controller.text = this.widget.name;
    }

    var widgetsBinding = WidgetsBinding.instance;
    widgetsBinding.addPostFrameCallback((callback) {
      initModel();
    });
  }

  Future<void> initModel() async {
    searchModel = Store.value<SearchModel>(context);
    searchModel.showResult = false;
    searchModel.context = context;
    searchModel.textFieldKey = textFieldKey;
    searchModel.controller = controller;
    searchModel.store_word = Common.book_search_history;
    searchModel.initHistory();
    findOverLayPosition();
    await searchModel.initBookHot();
    searchModel.getHot();
  }

  Widget buildSearchWidget() {
    return Container(
      child: TextField(
        key: textFieldKey,
        controller: controller,
        onSubmitted: (word) {
          removeOverlay();
          searchModel.search(word);
        },
        onChanged: (value) async {
          if (value.isNotEmpty) {
            await searchModel.searchAi(value);
            if (searchModel.bksAi.isNotEmpty) {
              if (searchSuggest != null) removeOverlay();

              searchSuggest = _buildSearchSuggest();

              overlayState.insert(searchSuggest);
            } else {
              removeOverlay();
            }
          } else {
            if (searchSuggest != null) removeOverlay();
          }
          setState(() {});
        },
        style: TextStyle(
          fontSize: 15,
          height: 1.3,
        ),
        autofocus: false,
        decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            hintStyle: TextStyle(
              fontSize: 15,
            ),
            prefixIcon: Icon(
              Icons.search,
            ),
            suffixIcon: IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                controller.text = "";
                searchModel.reset();
                removeOverlay();
              },
            ),
            hintText: "书籍/作者名"),
      ),
      height: 40,
    );
  }

  void removeOverlay() {
    searchSuggest?.remove();
    searchSuggest = null;
  }

  void findOverLayPosition() {
    RenderBox renderBox = textFieldKey.currentContext.findRenderObject();
    height = renderBox.size.height;
    width = renderBox.size.width;

    Offset offset = renderBox.localToGlobal(Offset.zero);
    xPosition = offset.dx;

    yPosition = offset.dy;
  }

  // 生成搜索建议
  OverlayEntry _buildSearchSuggest() {
    return OverlayEntry(builder: (context) {
      return Positioned(
        left: xPosition,
        width: width,
        top: yPosition + height + 5,
        height: 500,
        child: SearchAiItem(
            height: aiItemH,
            function: (id) async {
              searchModel.setHistory(controller.value.text);

              String url = Common.detail + '/$id';
              Response future = await HttpUtil.instance.dio.get(url);
              var d = future.data['data'];
              BookInfo b = BookInfo.fromJson(d);
              Routes.navigateTo(
                context,
                Routes.detail,
                params: {
                  'detail': jsonEncode(b),
                },
              );
              removeOverlay();
            }),
      );
    });
  }

  Widget resultWidget() {
    var picW = SpUtil.getDouble(Common.book_pic_width, defValue: .0);
    var picH = picW / .65;
    return SmartRefresher(
        enablePullDown: true,
        enablePullUp: true,
        header: WaterDropHeader(),
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
        controller: searchModel.refreshController,
        onRefresh: searchModel.onRefresh,
        onLoading: searchModel.onLoading,
        child: ListView.builder(
          itemExtent: picH,
          itemBuilder: (c, i) {
            var item = searchModel.bks[i];
            return FrameSeparateWidget(
                index: i,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    String url = Common.detail + '/${searchModel.bks[i].Id}';
                    Response future = await HttpUtil.instance.dio.get(url);
                    var d = future.data['data'];
                    BookInfo b = BookInfo.fromJson(d);
                    Routes.navigateTo(context, Routes.detail,
                        params: {"detail": jsonEncode(b)});
                  },
                  child: Container(
                    height: 130,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    child: Row(
                      children: <Widget>[
                        PicWidget(
                          item.Img,
                          width: picW,
                          height: picH,
                        ),

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
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold),
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
                                  item.Desc ?? "尚无介绍.....",
                                  style: TextStyle(
                                    fontSize: 12.0,
                                  ),
                                  maxLines: 2,
                                ),
                                Text(
                                  item.LastChapter,
                                  style: TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ));
          },
          itemCount: searchModel.bks.length,
        ));
  }

  Widget suggestionWidget(data) {
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
                    searchModel.clearHistory();
                  },
                )
              ],
            ),
            Wrap(
              children: searchModel?.getHistory() ?? [],
              spacing: 10, //主轴上子控件的间距
            ),
            Row(
              children: <Widget>[
                Text(
                  '热门书籍',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: () {
                    searchModel.getHot();
                  },
                )
              ],
            ),
            Wrap(
              children: searchModel?.showHot ?? [], spacing: 10, //主轴上子控件的间距
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
