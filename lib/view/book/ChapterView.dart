import 'dart:convert';

import 'package:book/common/common.dart';
import 'package:book/common/net.dart';
import 'package:book/entity/BookInfo.dart';
import 'package:book/model/ColorModel.dart';
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

  double ITEM_HEIGH = 50.0;

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
      if (_scrollController.offset < ITEM_HEIGH * 8 && showToTopBtn) {
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
      curIndex = Store.value<ReadModel>(context).bookTag.cur - 8;
      await _scrollController.animateTo(
          (Store.value<ReadModel>(context).bookTag.cur - 8) * ITEM_HEIGH,
          duration: Duration(microseconds: 1),
          curve: Curves.ease);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Store.connect<ReadModel>(builder: (context, ReadModel data, child) {
      var value = Store.value<ColorModel>(context);
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
                        width: 80,
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
                  padding: EdgeInsets.only(left: 5, right: 15),
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
                  itemExtent: ITEM_HEIGH,
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
                      selected: index == data.bookTag.cur,
                      onTap: () async {
                        Navigator.of(context).pop();
                        //不是卷目录
                        data.bookTag.cur = index;
                        await Future.delayed(Duration(microseconds: 3000));
                        data.intiPageContent(index, true);
                      },
                    );
                  },
                  itemCount: data.chapters.length,
                ),
              ),
            ),
            // ButtonBar(children: [
            //   Text('a'),
            //   Text('a'),
            // ],)
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            FloatingActionButton(
                heroTag: "refresh",
                backgroundColor:
                    value.dark ? Colors.white : value.theme.primaryColor,
                onPressed: refresh,
                child: Icon(Icons.refresh)),
            SizedBox(
              height: 10.0,
            ),
            FloatingActionButton(
                heroTag: "tree",
                backgroundColor:
                    value.dark ? Colors.white : value.theme.primaryColor,
                onPressed: topOrBottom,
                child: Icon(
                  showToTopBtn ? Icons.arrow_upward : Icons.arrow_downward,
                ))
          ],
        ),
      );
    });
  }

  Future goDetail(ReadModel data, context) async {
    String url = Common.detail + '/${data.book.Id}';
    Response future = await Util(context).http().get(url);
    var d = future.data['data'];
    BookInfo bookInfo = BookInfo.fromJson(d);

    Routes.navigateTo(context, Routes.detail,
        params: {"detail": jsonEncode(bookInfo)});
    data.saveData();
    data.loadOk = false;
    // data.clear();
  }

  topOrBottom() async {
    if (_scrollController.hasClients) {
      int temp = showToTopBtn
          ? 1
          : Store.value<ReadModel>(context).chapters.length - 8;
      await _scrollController.animateTo(temp * ITEM_HEIGH,
          duration: Duration(microseconds: 1), curve: Curves.ease);
    }
  }

  Future<void> refresh() async {
    Store.value<ReadModel>(context).reloadChapters();
    if (_scrollController.hasClients) {
      int temp = Store.value<ReadModel>(context).chapters.length - 8;
      await _scrollController.animateTo(temp * ITEM_HEIGH,
          duration: Duration(microseconds: 1), curve: Curves.ease);
    }
  }
}
