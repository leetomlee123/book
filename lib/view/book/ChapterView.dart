import 'dart:convert';

import 'package:book/common/common.dart';
import 'package:book/common/Http.dart';
import 'package:book/entity/BookInfo.dart';
import 'package:book/model/ReadModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ChapterView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ChapterViewItem();
  }
}

class _ChapterViewItem extends State<ChapterView> {
  ScrollController _scrollController = new ScrollController();

  double itemHeight = 45.0;

  bool up = false;
  int curIndex = 0;
  bool showToTopBtn = false; //是否显示“返回到顶部”按钮

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  @override
  void initState() {
    super.initState();
    var widgetsBinding = WidgetsBinding.instance;
    widgetsBinding.addPostFrameCallback((callback) {
      scrollTo();
    });
    //监听滚动事件，打印滚动位置
    _scrollController.addListener(() {
      if (_scrollController.offset < itemHeight * 8 && showToTopBtn) {
        setState(() {
          showToTopBtn = false;
        });
      } else if (_scrollController.offset >= 1000 && showToTopBtn == false) {
        setState(() {
          showToTopBtn = true;
        });
      }
    });
  }

//滚动到当前阅读位置
  scrollTo() async {
    if (_scrollController.hasClients) {
      curIndex = Store.value<ReadModel>(context).book.cur - 8;
      await _scrollController.animateTo(
          (Store.value<ReadModel>(context).book.cur - 8) * itemHeight,
          duration: Duration(microseconds: 1),
          curve: Curves.ease);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Store.connect<ReadModel>(builder: (context, ReadModel data, child) {
      return Scaffold(
        appBar: PreferredSize(
          child: Container(
            padding: EdgeInsets.only(left: 10, top: 30),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      child: CachedNetworkImage(
                        imageUrl: data.book.Img,
                        width: 85,
                        height: 80,
                      ),
                      onTap: () async {
                        await goDetail(data, context);
                      },
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 5,
                        ),
                        Text(
                          data.book.Name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.clip,
                        ),
                        Text(
                          data.book.Author,
                          style: TextStyle(
                            fontWeight: FontWeight.w100,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  height: 5,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 10, right: 15),
                  child: Row(
                    children: [
                      Text(
                        '共${data.chapters.length}章',
                        style: TextStyle(fontSize: 12),
                      ),
                      Expanded(child: Container()),
                      GestureDetector(
                        child: Text(
                          '简介',
                          style: TextStyle(fontSize: 14),
                        ),
                        onTap: () async {
                          await goDetail(data, context);
                        },
                      )
                    ],
                  ),
                ),
                Divider()
              ],
            ),
          ),
          preferredSize: Size.fromHeight(130),
        ),
        body: Column(
          children: [
            Expanded(
              child: Scrollbar(
                child: ListView.builder(
                  controller: _scrollController,
                  itemExtent: itemHeight,
                  itemBuilder: (context, index) {
                    var title = data.chapters[index].name;
                    var has = data.chapters[index].hasContent;
                    return ListTile(
                      title: Text(
                        title,
                        style: TextStyle(fontSize: 13),
                      ),
                      trailing: Text(
                        has == 2 ? "已缓存" : "",
                        style: TextStyle(fontSize: 8),
                      ),
                      selected: index == data.book.cur,
                      onTap: () async {
                        Navigator.of(context).pop();
                        //不是卷目录
                        data.book.cur = index;

                        Future.delayed(Duration(milliseconds: 300 ), () {
                          data.initPageContent(index, true);
                        });
                      },
                    );
                  },
                  itemCount: data.chapters.length,
                ),
              ),
            ),
            Divider(),
            ButtonBar(
              mainAxisSize: MainAxisSize.max,
              alignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton(onPressed: refresh, child: Text("重新加载")),
                TextButton(
                    onPressed: topOrBottom,
                    child: Text(!showToTopBtn ? "回到底部" : "回到顶部"))
              ],
            ),

            // ButtonBar(children: [
            //   Text('a'),
            //   Text('a'),
            // ],)
          ],
        ),
      );
    });
  }

  Future goDetail(ReadModel data, context) async {
    String url = Common.detail + '/${data.book.Id}';
    Response future = await HttpUtil(showLoading: true).http().get(url);
    var d = future.data['data'];
    BookInfo bookInfo = BookInfo.fromJson(d);
    Routes.navigateTo(context, Routes.detail,
        params: {"detail": jsonEncode(bookInfo)}, replace: true);
    data.saveData();
    data.loadOk = false;
    // data.clear();
  }

  topOrBottom() async {
    if (_scrollController.hasClients) {
      int temp = showToTopBtn
          ? 0
          : Store.value<ReadModel>(context).chapters.length - 8;
      await _scrollController.animateTo(temp * itemHeight,
          duration: Duration(microseconds: 1), curve: Curves.ease);
    }
  }

  Future<void> refresh() async {
    Store.value<ReadModel>(context).reloadChapters();
    if (_scrollController.hasClients) {
      int temp = Store.value<ReadModel>(context).chapters.length - 8;
      await _scrollController.animateTo(temp * itemHeight,
          duration: Duration(microseconds: 1), curve: Curves.ease);
    }
  }
}
