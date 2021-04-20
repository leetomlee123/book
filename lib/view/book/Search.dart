import 'dart:convert';

import 'package:book/common/Http.dart';
import 'package:book/common/PicWidget.dart';
import 'package:book/common/common.dart';
import 'package:book/entity/BookInfo.dart';
import 'package:book/entity/GBook.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/SearchModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
  bool isBookSearch = false;
  SearchModel searchModel;
  ColorModel value;
  Widget body;
  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    value = Store.value<ColorModel>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: buildSearchWidget(),
        elevation: 0,
        automaticallyImplyLeading: false,
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
  }

  @override
  void initState() {
    super.initState();
    isBookSearch = this.widget.type == "book";
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
    searchModel.controller = controller;
    searchModel.isBookSearch = this.isBookSearch;
    searchModel.store_word =
        isBookSearch ? Common.book_search_history : Common.movie_search_history;
    searchModel.initHistory();
    if (isBookSearch) {
      await searchModel.initBookHot();
    } else {
      await searchModel.initMovieHot();
    }
    searchModel.getHot();
  }

  Widget buildSearchWidget() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF2F2F2),
        // borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              Icons.search,
              size: 22,
              color: Color(0xFF999999),
            ),
          ),
          Expanded(
              child: Container(
            child: TextField(
              controller: controller,
              onSubmitted: (word) {
                searchModel.search(word);
              },
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF333333),
                height: 1.3,
              ),
              autofocus: false,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF999999),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    controller.text = "";
                    searchModel.reset();
                  },
                ),
                hintText: isBookSearch ? "书籍/作者名" : "美剧/作者",
              ),
            ),
            height: 40,
          )),

          // _suffix(),
        ],
      ),
    );
  }

  Widget resultWidget() {
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
      child: isBookSearch
          ? ListView.builder(
              itemBuilder: (context, i) {
                var auth = searchModel.bks[i].Author;
//                var cate = searchModel.bks[i].CName??"";
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: <Widget>[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            padding:
                                const EdgeInsets.only(left: 10.0, top: 10.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: PicWidget(
                                searchModel.bks[i]?.Img ?? "",
                                height: 115,
                                width: 90,
                              ),
                            ),
                          )
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        verticalDirection: VerticalDirection.down,
                        // textDirection:,
                        textBaseline: TextBaseline.alphabetic,

                        children: <Widget>[
                          Container(
                            width: ScreenUtil.getScreenW(context) - 120,
                            padding:
                                const EdgeInsets.only(left: 10.0, top: 10.0),
                            child: Text(
                              searchModel.bks[i].Name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 15),
                            ),
                          ),
                          Container(
                            padding:
                                const EdgeInsets.only(left: 10.0, top: 10.0),
                            child: new Text('$auth',
                                style: TextStyle(
                                  fontSize: 14,
                                )),
                          ),
                          Container(
                            padding:
                                const EdgeInsets.only(left: 10.0, top: 10.0),
                            child: Text(searchModel.bks[i].Desc ?? "",
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: TextStyle(
                                  fontSize: 12,
                                )),
                            width: ScreenUtil.getScreenW(context) - 120,
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () async {
                    String url = Common.detail + '/${searchModel.bks[i].Id}';
                    Response future =
                        await HttpUtil(showLoading: true).http().get(url);
                    var d = future.data['data'];
                    BookInfo b = BookInfo.fromJson(d);
                    Routes.navigateTo(context, Routes.detail,
                        params: {"detail": jsonEncode(b)});
                  },
                );
              },
              itemCount: searchModel.bks.length,
            )
          : GridView(
              shrinkWrap: true,
              padding: EdgeInsets.all(5.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 1.0,
                  crossAxisSpacing: 10.0,
                  childAspectRatio: 0.7),
              children: searchModel.mks.map((i) => img(i)).toList(),
            ),
    );
  }

  Widget img(GBook gbk) {
    return GestureDetector(
      child: Column(
        children: <Widget>[
          PicWidget(
            gbk.cover,
            width: (ScreenUtil.getScreenW(context) - 40) / 3,
            height: ((ScreenUtil.getScreenW(context) - 40) / 3) * 1.2,
          ),
          Spacer(),
          Text(
            gbk.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        ],
      ),
      onTap: () async {
        Routes.navigateTo(context, Routes.vDetail,
            params: {"gbook": jsonEncode(gbk)});
      },
    );
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
//          ListView(
//            shrinkWrap: true,
//            children: data.getHistory(),
//          ),
            Wrap(
              children: searchModel?.getHistory() ?? [],
              spacing: 10, //主轴上子控件的间距
              alignment: WrapAlignment.start, //交叉轴上子控件之间的间距
            ),
            Row(
              children: <Widget>[
                Text(
                  '热门${this.widget.type == "book" ? "书籍" : "美剧"}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: Container(),
                ),
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
}
