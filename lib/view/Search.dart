import 'dart:convert';

import 'package:book/common/common.dart';
import 'package:book/common/util.dart';
import 'package:book/entity/BookInfo.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/SearchModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'BookDetail.dart';

class Search extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _SearchState();
  }
}

class _SearchState extends State<Search> {
  SearchModel searchModel;
  Widget body;
  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Store.connect<ColorModel>(
        builder: (context, ColorModel data, child) => Theme(
              child: Scaffold(
                appBar: AppBar(
                  title: buildSearchWidget(),
                  elevation: 0,
                  automaticallyImplyLeading: false,
                ),
                body: Store.connect<SearchModel>(
                    builder: (context, SearchModel data, child) =>
                        data.showResult
                            ? resultWidget()
                            : suggestionWidget(data)),
              ),
              data: data.theme,
            ));
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    var widgetsBinding = WidgetsBinding.instance;
    widgetsBinding.addPostFrameCallback((callback) {
      searchModel = Store.value<SearchModel>(context);
      searchModel.context = context;
      searchModel.controller = controller;
      searchModel.initHistory();
      searchModel.initHot();
    });
  }

  Widget buildSearchWidget() {
    return Row(
      children: <Widget>[
        Expanded(
          child: Store.connect<ColorModel>(
              builder: (context, ColorModel data, child) => Container(
                  //修饰黑色背景与圆角
                  decoration: BoxDecoration(
                    //灰色的一层边框
                    color: data.dark ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(25.0)),
                  ),
                  alignment: Alignment.center,
                  height: 40,
                  child: Center(
                    child: TextField(
                      controller: controller,
                      onSubmitted: (word) {
                        searchModel.search(word);
                      },
                      autofocus: false,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.only(bottom: 6, left: 20),
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () {
                            controller.text = "";
                            searchModel.reset();
                          },
                        ),
                        hintText: "书籍/作者名",
                      ),
                    ),
                  ))),
          flex: 5,
        ),
        SizedBox(
          width: 5,
        ),
        Expanded(
          child: Center(
            child: Padding(
              child: GestureDetector(
                child: Text('搜索'),
                onTap: () {
                  searchModel.search(controller.text);
                },
              ),
              padding: EdgeInsets.only(left: 1, right: 1),
            ),
          ),
          flex: 1,
        )
      ],
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
      child: ListView.builder(
        itemBuilder: (context, i) {
          var auth = searchModel.bks[i].Author;
          var cate = searchModel.bks[i].CName;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: <Widget>[
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    new Container(
                      padding: const EdgeInsets.only(left: 10.0, top: 10.0),
                      child: Image.network(
                        searchModel.bks[i].Img,
                        height: 100,
                        width: 80,
                        fit: BoxFit.cover,
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
                      padding: const EdgeInsets.only(left: 10.0, top: 10.0),
                      child: Text(
                        searchModel.bks[i].Name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.only(left: 10.0, top: 10.0),
                      child: new Text('$cate | $auth',
                          style: TextStyle(
                            fontSize: 14,
                          )),
                    ),
                    Container(
                      padding: const EdgeInsets.only(left: 10.0, top: 10.0),
                      child: Text(searchModel.bks[i].Desc.trim(),
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
              Response future = await Util(context).http().get(url);
              var d = future.data['data'];
              BookInfo b = BookInfo.fromJson(d);
              Routes.navigateTo(context, Routes.detail,
                  params: {"detail": jsonEncode(b)});
            },
          );
        },
        itemCount: searchModel.bks.length,
      ),
    );
  }

  Widget suggestionWidget(data) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.only(left: 15, right: 15, top: 10),
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
              children: data.getHistory(),
              spacing: 3, //主轴上子控件的间距
              runSpacing: 5, //交叉轴上子控件之间的间距
            ),
            Row(
              children: <Widget>[
                Text(
                  '热门书籍',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Column(
              children: searchModel.hot,
            )
          ],
        ),
      ),
    );
  }
}
