import 'dart:convert';

import 'package:book/common/PicWidget.dart';
import 'package:book/common/common.dart';
import 'package:book/common/net.dart';
import 'package:book/entity/GBook.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class TagVideo extends StatefulWidget {
  final String category;
  final String name;

  TagVideo(this.category, this.name);

  @override
  State<StatefulWidget> createState() {
    return TagVideoState();
  }
}

class TagVideoState extends State<TagVideo> {
  Widget body;
  int page = 1;
  List<GBook> gbks = [];
  RefreshController refreshController =
      RefreshController(initialRefresh: false);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getSearchData();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Store.connect<ColorModel>(
        builder: (context, ColorModel model, child) => Theme(
              child: Scaffold(
                appBar: AppBar(
                  title: Text(this.widget.name),
                  centerTitle: true,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                ),
                body: SmartRefresher(
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
                  controller: refreshController,
                  onRefresh: onRefresh,
                  onLoading: onLoading,
                  child: GridView(
                    shrinkWrap: true,

                    padding: EdgeInsets.all(5.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 1.0,
                        crossAxisSpacing: 10.0,
                        childAspectRatio: 0.7),
                    children: gbks.map((i) => img(i)).toList(),
                  ),
                ),
              ),
              data: model.theme,
            ));
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
          Expanded(
            child: Container(),
          ),
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

  getSearchData() async {
    var ctx;
    if (gbks.length == 0) {
      ctx = context;
    }
    var url = '${Common.tag_movies}/${this.widget.category}/page/$page';

    Response res = await Util(ctx).http().get(url);
    List data = res.data;
    if (data == null) {
      refreshController.loadNoData();
    } else {
      data.forEach((f) {
        gbks.add(GBook.fromJson(f));
      });
    }
    if(mounted){
      setState(() {

      });
    }
  }

  void onRefresh() {
    gbks = [];
    page = 1;
    getSearchData();
    refreshController.refreshCompleted();
    if (mounted) {
      setState(() {});
    }
  }

  void onLoading() {
    page += 1;
    getSearchData();
    refreshController.loadComplete();
    if (mounted) {
      setState(() {});
    }
  }
}
