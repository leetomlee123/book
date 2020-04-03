//import 'dart:convert';
//
//import 'package:book/common/common.dart';
//import 'package:book/common/util.dart';
//import 'package:book/entity/Book.dart';
//import 'package:book/entity/BookInfo.dart';
//import 'package:dio/dio.dart';
//import 'package:extended_image/extended_image.dart';
//import 'package:flustars/flustars.dart';
//import 'package:flutter/material.dart';
//
//import 'BookDetail.dart';
//
//class BookCity extends StatefulWidget {
//  @override
//  State<StatefulWidget> createState() {
//    // TODO: implement createState
//    return _BookCityState();
//  }
//}
//
//class _BookCityState extends State<BookCity>
//    with SingleTickerProviderStateMixin {
//  final List<Tab> titleTabs = <Tab>[
//    Tab(
//      text: '男生',
//    ),
//    Tab(
//      text: '女生',
//    ),
//  ];
//  TabController mController;
//
//  @override
//  void initState() {
//    // TODO: implement initState
//    super.initState();
//    mController = TabController(length: 2, vsync: this)
//      ..addListener(() {
//        if (mController.index.toDouble() == mController.animation.value) {
//          switch (mController.index) {
//            case 0:
//              print(1);
//              break;
//            case 1:
//              print(2);
//              break;
//          }
//        }
//      });
//  }
//
//  @override
//  void dispose() {
//    // TODO: implement dispose
//    super.dispose();
//    mController.dispose();
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    // TODO: implement build
//    return Scaffold(
//      appBar: AppBar(
//        title: TabBar(
//            controller: mController,
//            isScrollable: true,
//            indicator: UnderlineTabIndicator(
//                borderSide: BorderSide(style: BorderStyle.none)),
//            tabs: titleTabs),
//        centerTitle: true,
//        elevation: 0,
//      ),
//      body: TabBarView(
//        controller: mController,
//        children: <Widget>[
//          Center(child: RankItem("male")),
//          Center(child: RankItem("female")),
//        ],
//      ),
//    );
//  }
//}
//
//class RankItem extends StatefulWidget {
//  String gender;
//
//  RankItem(this.gender);
//
//  @override
//  State<StatefulWidget> createState() {
//    // TODO: implement createState
//    return _RankItemState();
//  }
//}
//
//class _RankItemState extends State<RankItem>
//    with AutomaticKeepAliveClientMixin {
//  String storeKey;
//
//  @override
//  void initState() {
//    storeKey = Common.toplist + this.widget.gender;
//
//    // TODO: implement initState
//    super.initState();
//    if (SpUtil.haveKey(storeKey)) {
//      List list = jsonDecode(SpUtil.getString(storeKey));
//      bks = list.map((f) => Book.fromJson(f)).toList();
//    }
//    initData();
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    // TODO: implement build
//    return tabView();
//  }
//
//  List<Book> bks = [];
//
//  Widget tabView() {
//    return GridView.count(
//      //水平子Widget之间间距
//      crossAxisSpacing: 10.0,
//      //垂直子Widget之间间距
//      mainAxisSpacing: 10.0,
//      //GridView内边距
//      padding: EdgeInsets.all(10.0),
//      //一行的Widget数量
//      crossAxisCount: 3,
//      //子Widget宽高比例
//      childAspectRatio: 0.5,
//      //子Widget列表
//      children: getWidgetList(),
//    );
//  }
//
//  List<Widget> getWidgetList() {
//    return bks.map((item) => getItemContainer(item)).toList();
//  }
//
//  Widget getItemContainer(Book item) {
//    return GestureDetector(
//      child: Container(
//        child: Column(
//          children: <Widget>[
//            ExtendedImage.network(
//              item.Img,
//              fit: BoxFit.fitHeight,
//              cache: true,
//              retries: 1,
//              loadStateChanged: (ExtendedImageState state) {
//                switch (state.extendedImageLoadState) {
//                  case LoadState.loading:
//                    return null;
//                    break;
//
//                  case LoadState.completed:
//                    return null;
//                    break;
//                  case LoadState.failed:
//                    return Image.asset(
//                      "images/nocover.jpg",
//                      width: 80,
//                      height: 100,
//                    );
//                    break;
//                }
//              },
//            ),
//            Text(
//              item.Name,
//              overflow: TextOverflow.ellipsis,
//            ),
//            Text(
//              "${item.Author}|${item.CName}",
//              overflow: TextOverflow.ellipsis,
//            ),
//          ],
//        ),
//      ),
//      onTap: () async {
//        String url = Common.detail + '/${item.Id}';
//        Response future = await Util(context).http().get(url);
//        var d = future.data['data'];
//        BookInfo bookInfo = BookInfo.fromJson(d);
//
//        Navigator.of(context).push(MaterialPageRoute(
//            builder: (BuildContext context) => BookDetail(bookInfo)));
//      },
//    );
//  }
//
//  Future<void> initData() async {
//    bks = [];
//    Response response =
//        await Util(context).http().get(Common.rank + "/${this.widget.gender}");
//    List list = response.data["data"];
//    bks = list.map((f) => Book.fromJson(f)).toList();
//    if (mounted) {
//      setState(() {});
//    }
//    SpUtil.putString(storeKey, jsonEncode(bks));
//  }
//
//  @override
//  // TODO: implement wantKeepAlive
//  bool get wantKeepAlive => true;
//}
