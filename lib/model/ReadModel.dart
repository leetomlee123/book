import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:book/common/LoadDialog.dart';
import 'package:book/common/ReaderPageAgent.dart';
import 'package:book/common/Screen.dart';
import 'package:book/common/common.dart';
import 'package:book/common/toast.dart';
import 'package:book/common/util.dart';
import 'package:book/entity/BookInfo.dart';
import 'package:book/entity/BookTag.dart';
import 'package:book/entity/Chapter.dart';
import 'package:book/entity/ReadPage.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/store/Store.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ReadModel with ChangeNotifier {
  BookInfo bookInfo;

  //本书记录
  BookTag bookTag;
  ReadPage prePage;
  ReadPage curPage;
  ReadPage nextPage;
  List<Widget> allContent = [];

  //页面控制器
  PageController pageController;

  //章节slider value
  double value;

  //背景色数据
  List<List> bgs = [
    [246, 242, 234],
    [242, 233, 209],
    [231, 241, 231],
    [228, 239, 242],
    [242, 228, 228],
  ];

  //页面字体大小
  double fontSize = 29.0;

  //显示上层 设置
  bool showMenu = false;

  //背景色索引
  int bgIdx = 0;

  //页面宽高
  double contentH;
  double contentW;

  //页面上下文
  BuildContext context;

//是否修改font
  bool font = false;

  //获取本书记录
  getBookRecord() async {
    showMenu = false;
    if (SpUtil.haveKey(bookInfo.Id)) {
      bookTag = BookTag.fromJson(jsonDecode(SpUtil.getString(bookInfo.Id)));
      getChapters();
      //书的最后一章
      if (bookInfo.CId == "-1") {
        bookTag.cur = bookTag.chapters.length - 1;
      }
      intiPageContent(bookTag.cur, false);
      pageController = PageController(initialPage: bookTag.index);
      value = bookTag.cur.toDouble();
      notifyListeners();
      //本书已读过
    } else {
      bookTag = BookTag(0, 0, bookInfo.Name, []);
      if (SpUtil.haveKey('${bookInfo.Id}chapters')) {
        var string = SpUtil.getString('${bookInfo.Id}chapters');
        List v = jsonDecode(string);
        bookTag.chapters = v.map((f) => Chapter.fromJson(f)).toList();
      }
      pageController = PageController(initialPage: 0);
      getChapters().then((_) {
        if (bookInfo.CId == "-1") {
          bookTag.cur = bookTag.chapters.length - 1;
        }
        intiPageContent(bookTag.cur, false);
      });
      saveData();
    }
  }

  Future intiPageContent(int idx, bool jump) async {
    showGeneralDialog(
      context: context,
      barrierLabel: "",
      barrierDismissible: true,
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (BuildContext context, Animation animation,
          Animation secondaryAnimation) {
        return LoadingDialog();
      },
    );
    prePage = await loadChapter(idx - 1);
    curPage = await loadChapter(idx);
    nextPage = await loadChapter(idx + 1);
    Navigator.pop(context);

    fillAllContent();
    value = bookTag.cur.toDouble();
    if (jump) {
      int ix = prePage?.pageOffsets?.length ?? 0;
      pageController.jumpToPage(ix);
    }
  }

  changeChapter(int idx) async {
    bookTag.index = idx;

    int preLen = prePage == null ? 0 : prePage.pageOffsets.length;
    int curLen = curPage == null ? 0 : curPage.pageOffsets.length;

    if ((idx + 1 - preLen) > (curLen)) {
      int temp = bookTag.cur + 1;
      if (temp >= bookTag.chapters.length) {
        Toast.show("已经是最后一页");
        pageController.previousPage(
            duration: Duration(microseconds: 1), curve: Curves.ease);
      } else {
        bookTag.cur += 1;
        prePage = curPage;
        if (nextPage.chapterName == "-1") {
          showGeneralDialog(
            context: context,
            barrierLabel: "",
            barrierDismissible: true,
            transitionDuration: Duration(milliseconds: 300),
            pageBuilder: (BuildContext context, Animation animation,
                Animation secondaryAnimation) {
              return LoadingDialog();
            },
          );
          curPage = await loadChapter(bookTag.cur);
          Navigator.pop(context);
        } else {
          curPage = nextPage;
        }
        nextPage = await loadChapter(bookTag.cur + 1);

        fillAllContent();

        pageController.jumpToPage(prePage?.pageOffsets?.length ?? 0);
      }
    } else if (idx < preLen) {
      int temp = bookTag.cur - 1;
      if (temp < 0) {
        return;
      } else {
        bookTag.cur -= 1;
        nextPage = curPage;
        curPage = prePage;
        prePage = await loadChapter(bookTag.cur - 1);

        fillAllContent();
        int ix = (prePage?.pageOffsets?.length ?? 0) +
            curPage.pageOffsets.length -
            1;
        pageController.jumpToPage(ix);
//        notifyListeners();
      }
    }
  }

  switchBgColor(i) {
    bgIdx = i;
    notifyListeners();
  }

  Future getChapters() async {
    print("load chpaters");
    var url = Common.chaptersUrl +
        '/${bookInfo.Id}/${bookTag?.chapters?.length ?? 0}';
//    var ctx;
//    if ((bookTag?.chapters?.length ?? 0) == 0 && context != null) {
//      ctx = context;
//      Toast.show('加载目录...');
//    }
    Response response = await Util(null).http().get(url);

    List data = response.data['data'];
    if (data == null) {
      return;
    }

    List<Chapter> list = data.map((c) => Chapter.fromJson(c)).toList();
    bookTag.chapters.addAll(list);
    //书的最后一章
    if (bookInfo.CId == "-1") {
      bookTag.cur = bookTag.chapters.length - 1;
      value = bookTag.cur.toDouble();
    }
    notifyListeners();
  }

  Future<ReadPage> loadChapter(int idx) async {
    ReadPage r = new ReadPage();
    if (idx < 0) {
      r.chapterName = "1";
      r.pageOffsets = List(1);
      r.chapterContent = "封面";
      return r;
    } else if (idx == bookTag.chapters.length) {
      r.chapterName = "-1";
      r.pageOffsets = List(1);
      r.chapterContent = "没有更多内容,等待作者更新";
      return r;
    }

    r.chapterName = bookTag.chapters[idx].name;
    String id = bookTag.chapters[idx].id;

    if (!SpUtil.haveKey(id)) {
      r.chapterContent = await compute(requestDataWithCompute, id);

      SpUtil.putString(id, r.chapterContent);

      r.pageOffsets = ReaderPageAgent.getPageOffsets(
          r.chapterContent, contentH, contentW, fontSize);
      SpUtil.putString('pages' + id, r.pageOffsets.join('-'));
      bookTag.chapters[idx].hasContent = 2;
    } else {
      r.chapterContent = SpUtil.getString(id);
      if (SpUtil.haveKey('pages' + id)) {
        r.pageOffsets = SpUtil.getString('pages' + id)
            .split('-')
            .map((f) => int.parse(f))
            .toList();
      } else {
        r.pageOffsets = ReaderPageAgent.getPageOffsets(
            r.chapterContent, contentH, contentW, fontSize);
      }
    }

    return r;
  }

  fillAllContent() {
    allContent = [];
    if (prePage != null) {
      allContent.addAll(chapterContent(prePage));
    }
    if (curPage != null) {
      allContent.addAll(chapterContent(curPage));
    }
    if (nextPage != null) {
      allContent.addAll(chapterContent(nextPage));
    }
    notifyListeners();
  }

  Widget readView() {
    return Theme(
      child: Scaffold(
        backgroundColor: Store.value<ColorModel>(context).dark
            ? null
            : Color.fromRGBO(bgs[bgIdx][0], bgs[bgIdx][1], bgs[bgIdx][2], 1),
        body: PageView.builder(
          controller: pageController,
          physics: AlwaysScrollableScrollPhysics(),
          itemBuilder: (BuildContext context, int index) {
            return allContent[index];
          },
          //条目个数
          itemCount: (prePage == null ? 0 : prePage.pageOffsets.length) +
              (curPage == null ? 0 : curPage.pageOffsets.length) +
              (nextPage == null ? 0 : nextPage.pageOffsets.length),
          onPageChanged: (idx) => changeChapter(idx),
        ),
      ),
      data: Store.value<ColorModel>(context).theme,
    );
  }

  modifyFont() {
    if (!font) {
      font = !font;
    }
    bookTag.index = 0;

    var keys = SpUtil.getKeys();
    for (var key in keys) {
      if (key.startsWith("pages")) {
        SpUtil.remove(key);
      }
    }
    intiPageContent(bookTag.cur, true);
//    notifyListeners();
  }

  toggleShowMenu() {
    showMenu = !showMenu;
    notifyListeners();
  }

  saveData() {
    SpUtil.putString(bookInfo.Id, jsonEncode(bookTag));
    SpUtil.putDouble('fontSize', fontSize);
    SpUtil.putInt('bgIdx', bgIdx);
  }

  void tapPage(BuildContext context, TapDownDetails details) {
    var wid = ScreenUtil.getScreenW(context);
    var space = wid / 3;
    var curWid = details.localPosition.dx;
    if (curWid > 0 && curWid < space) {
      pageController.previousPage(
          duration: Duration(microseconds: 1), curve: Curves.ease);
    } else if (curWid > space && curWid < 2 * space) {
      toggleShowMenu();
    } else {
      pageController.nextPage(
          duration: Duration(microseconds: 1), curve: Curves.ease);
    }
  }

  reCalcPages() {
    SpUtil.getKeys().forEach((f) {
      if (f.startsWith('pages')) {
        SpUtil.remove(f);
      }
    });
  }

  downloadAll() async {
    if (bookTag?.chapters?.isEmpty ?? 0 == 0) {
      await getChapters();
      saveData();
    }
    List<String> ids = [];
    if (SpUtil.haveKey(Common.downloadlist)) {
      ids = SpUtil.getStringList(Common.downloadlist);
    }
    if (!ids.contains(bookInfo.Id)) {
      ids.add(bookInfo.Id);
    }
    SpUtil.putStringList(Common.downloadlist, ids);
    for (var chapter in bookTag.chapters) {
      String id = chapter.id;
      if (!SpUtil.haveKey(id)) {
        String content = await compute(requestDataWithCompute, id);
        SpUtil.putString(chapter.id, content);
        chapter.hasContent = 2;
      }
    }
    Toast.show("${bookInfo?.Name ?? ""}下载完成");
    saveData();
  }

  static Future<String> requestDataWithCompute(String id) async {
    try {
      var url = Common.bookContentUrl + '/$id';
      var client = new HttpClient();
      var request = await client.getUrl(Uri.parse(url));
      var response = await request.close();
      var responseBody = await response.transform(utf8.decoder).join();
      var dataList = jsonDecode(responseBody);
      return dataList['data']['content'].toString();
    } catch (e) {
      print(e);
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    saveData();
    super.dispose();
  }

  List<Widget> chapterContent(ReadPage r) {
    List<Widget> contents = [];
    for (var i = 0; i < r.pageOffsets.length; i++) {
      var content = r.stringAtPageIndex(i);
      if (content.startsWith("\n")) {
        content = content.substring(1);
      }

      contents.add(
        GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (TapDownDetails details) {
              tapPage(context, details);
            },
            child: (r.chapterName == "-1" || r.chapterName == "1")
                ? Container(
                    child: Text(r.chapterContent),
                    alignment: Alignment.center,
                  )
                : Container(
                    child: Column(
                      children: <Widget>[
                        SizedBox(height: ScreenUtil.getStatusBarH(context)),
                        Container(
                          height: 30,
                          padding: EdgeInsets.only(left: 3),
                          child: Text(
                            r.chapterName,
                            style: TextStyle(
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: Container(
                              padding: EdgeInsets.only(
                                right: 5,
                                left: 15,
                              ),
                              child: Text(
                                content,
                                style: TextStyle(
                                  fontSize: fontSize / Screen.textScaleFactor,
                                ),
                              )),
                        ),
                        Container(
                          height: 30,
                          padding: EdgeInsets.only(right: 8),
                          child: Row(
                            children: <Widget>[
                              Expanded(child: Container()),
                              Text(
                                '第${i + 1}/${r.pageOffsets.length}页',
                                style: TextStyle(
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                      crossAxisAlignment: CrossAxisAlignment.start,
                    ),
                    width: double.infinity,
                    height: double.infinity,
                  )),
      );
    }
    return contents;
  }

  clear() {
    bookTag = null;
    allContent = null;
  }
}
