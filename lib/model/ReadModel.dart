import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:book/common/DbHelper.dart';
import 'package:book/common/LoadDialog.dart';
import 'package:book/common/ReadSetting.dart';
import 'package:book/common/ReaderPageAgent.dart';
import 'package:book/common/Screen.dart';
import 'package:book/common/common.dart';
import 'package:book/common/net.dart';
import 'package:book/entity/Book.dart';
import 'package:book/entity/BookTag.dart';
import 'package:book/entity/Chapter.dart';
import 'package:book/entity/ReadPage.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/store/Store.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ReadModel with ChangeNotifier {
  Book book;
  List<Chapter> chapters = [];

  //本书记录
  BookTag bookTag;
  ReadPage prePage;
  ReadPage curPage;
  ReadPage nextPage;
  List<Widget> allContent = [];

  //页面控制器
  PageController pageController;
  ScrollController listController;

  //章节slider value
  double value;

  //背景色数据
  List<List> bgs = [
    [250, 245, 235],
    [245, 234, 204],
    [230, 242, 230],
    [228, 241, 245],
    [245, 228, 228],
  ];

  // List<String> bgimg = [
  //   "https://qidian.gtimg.com/qd/images/read.qidian.com/body_base_bg.5988a.png",
  //   "https://qidian.gtimg.com/qd/images/read.qidian.com/theme/body_theme1_bg.9987a.png",
  //   "https://qidian.gtimg.com/qd/images/read.qidian.com/theme/body_theme2_bg.75a33.png",
  //   "https://qidian.gtimg.com/qd/images/read.qidian.com/theme/theme_3_bg.31237.png",
  //   "https://qidian.gtimg.com/qd/images/read.qidian.com/theme/body_theme5_bg.85f0d.png",
  // ];

  bool refresh = true;

  //显示上层 设置
  bool showMenu = false;

  //章节切换过程中 页面切换数
  int offset = 0;

  //offset tag 上一章 -1 下一张 +1
  int offsetTag = 0;

  //背景色索引
  int bgIdx = 0;

//章节翻页标志
  bool loadOk = false;

  //页面宽高
  double contentH;
  double contentW;
  bool jump = true;

//阅读方式
  bool isPage = true;

  //页面上下文
  BuildContext context;

//是否修改font
  bool font = false;

  //获取本书记录
  getBookRecord() async {
    showMenu = false;
    font = false;
    offset = 0;
    offsetTag = 0;
    loadOk = false;

    if (SpUtil.haveKey(book.Id)) {
      bookTag = BookTag(book?.cur??0, book?.index??0, book.Name, 0.0);
      // bookTag = await DbHelper.instance.getBookProcess(book.Id, book.Name);
      chapters = await DbHelper.instance.getChapters(book.Id);

      if (chapters.isEmpty) {
        await getChapters();
      } else {
        getChapters();
      }

      //书的最后一章
      if (book.CId == "-1") {
        bookTag.cur = chapters.length - 1;
      }
      await intiPageContent(bookTag.cur, false);
      // if (isPage) {
      pageController =
          new PageController(initialPage: bookTag.index, keepPage: false);
      // } else {
      //   listController = ScrollController(initialScrollOffset: bookTag.offset);
      // }
      value = bookTag.cur.toDouble();
      loadOk = true;
      //本书已读过
    } else {
      int cur = 0;
      String userName = SpUtil.getString("username");
      if (userName.isNotEmpty) {
        var url = Common.process + '/$userName/${book.Id}';
        Response response = await Util(null).http().get(url);
        String data = response.data['data'];
        if (data.isNotEmpty) {
          cur = int.parse(data);
        }
      }
      bookTag = BookTag(cur, 0, book.Name, 0.0);
      if (SpUtil.haveKey('${book.Id}chapters')) {
        chapters = await DbHelper.instance.getChapters(book.Id);
      } else {
        await getChapters();
      }

      if (book.CId == "-1") {
        bookTag.cur = chapters.length - 1;
      }

      await intiPageContent(bookTag.cur, false);
      int idx = (cur == 0) ? 0 : (prePage?.pageOffsets?.length ?? 0);
      // if (isPage) {
      pageController = new PageController(initialPage: idx, keepPage: false);
      // } else {
      //   listController = ScrollController(initialScrollOffset: 0.0);
      // }
      loadOk = true;

//      notifyListeners();
    }
//      if (pageController.hasClients) {
//        pageController.jumpToPage(idx);
//      }
//    if (!isPage) {
//      listController.addListener(() {
//        double offset = listController.offset;
//        if (offset > (prePage.height + curPage.height)) {
//          print("next chapter");
//          if (!chapterLoading) {
//            nextChapter();
//          }
//        }
//      });
//    }
    notifyListeners();
    print('pagecontroller hashcode ${pageController.hashCode}');
  }

  nextChapter() async {
    bookTag.cur += 1;
    int idx = bookTag.cur;
    double offset = listController.offset;

    var d = offset - prePage.height - curPage.height;
    prePage = await loadChapter(idx - 1);
    curPage = await loadChapter(idx);
    nextPage = await loadChapter(idx + 1);
    fillAllContent();
    value = bookTag.cur.toDouble();
    listController.jumpTo(prePage.height + d);
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

    fillAllContent(notify: jump);
    value = bookTag.cur.toDouble();
    if (jump) {
      int ix = prePage?.pageOffsets?.length ?? 0;
      pageController.jumpToPage(ix);
    }
  }

  changeChapter(int idx) async {
    bookTag.index = idx;
    offset = offset + offsetTag;
    int preLen = prePage?.pageOffsets?.length ?? 0;
    int curLen = curPage?.pageOffsets?.length ?? 0;

    // print("idx:$idx preLen:$preLen curLen:$curLen");
    if ((idx + 1 - preLen) > (curLen)) {
      //下一章
      int temp = bookTag.cur + 1;
      if (temp >= chapters.length) {
        BotToast.showText(text: "已经是最后一页");
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
          int preLen = prePage?.pageOffsets?.length ?? 0;
          int curLen = curPage?.pageOffsets?.length ?? 0;
          bookTag.index = preLen + curLen - 1;
          Navigator.pop(context);
        } else {
          curPage = nextPage;
        }
        nextPage = null;
        fillAllContent();
        pageController.jumpToPage(prePage?.pageOffsets?.length ?? 0);
        ReadPage temp = await loadChapter(bookTag.cur + 1);
        nextPage = temp;
        fillAllContent();
      }
    } else if (idx < preLen) {
      //上一章
      print('上一张');
      int temp = bookTag.cur - 1;
      if (temp < 0) {
        return;
      } else {
        bookTag.cur -= 1;
        nextPage = curPage;
        curPage = prePage;
        prePage = null;
        fillAllContent();
        var p = curPage?.pageOffsets?.length ?? 0;
        pageController.jumpToPage(p > 0 ? p - 1 : 0);
        prePage = await loadChapter(bookTag.cur - 1);
        fillAllContent();
        int ix = (prePage?.pageOffsets?.length ?? 0) + idx;
        pageController.jumpToPage(ix);
      }
    }
  }

  switchBgColor(i) {
    bgIdx = i;
    SpUtil.putInt('bgIdx', i);
    notifyListeners();
  }

  Future getChapters() async {
    var url = Common.chaptersUrl + '/${book.Id}/${chapters?.length ?? 0}';
    Response response =
        await Util(chapters.isEmpty ? context : null).http().get(url);

    List data = response.data['data'];
    if (data == null) {
      print("load cps ok");
      return;
    }

    List<Chapter> list = data.map((c) => Chapter.fromJson(c)).toList();
    chapters.addAll(list);
    //书的最后一章
    if (book.CId == "-1") {
      bookTag.cur = chapters.length - 1;
      value = bookTag.cur.toDouble();
    }
    SpUtil.putString('${book.Id}chapters', "");
    DbHelper.instance.addChapters(list, book.Id);
    notifyListeners();
    print("load cps ok");
  }

  Future<ReadPage> loadChapter(int idx) async {
    ReadPage r = new ReadPage();
    if (idx < 0) {
      r.chapterName = "1";
      r.pageOffsets = List(1);
      r.height = Screen.height;
      r.chapterContent = "Fall In Love At First Sight ,Miss.Zhang";
      return r;
    } else if (idx == chapters.length) {
      r.chapterName = "-1";
      r.pageOffsets = List(1);
      r.chapterContent = "没有更多内容,等待作者更新";
      return r;
    }

    r.chapterName = chapters[idx].name;
    String id = chapters[idx].id;
    var bool = await DbHelper.instance.getHasContent(id);
    if (!bool) {
      r.chapterContent = await compute(requestDataWithCompute, id);

      if (r.chapterContent.isNotEmpty) {
        // SpUtil.putString(id, r.chapterContent);
        DbHelper.instance.udpChapter(r.chapterContent, id);
        chapters[idx].hasContent = 2;
      }
      // SpUtil.putString('${book.Id}chapters', jsonEncode(chapters));
    } else {
      r.chapterContent = await DbHelper.instance.getContent(id);
    }
    if (r.chapterContent.isEmpty) {
      r.chapterContent = "章节数据不存在,可手动重载或联系管理员";
      r.pageOffsets = [r.chapterContent];
      return r;
    }
    // if (isPage) {
    var k = '${book.Id}pages' + r.chapterName;
    if (SpUtil.haveKey(k)) {
      r.pageOffsets = SpUtil.getStringList(k);
      SpUtil.remove(k);
    } else {
      r.pageOffsets = ReaderPageAgent()
          .getPageOffsets(r.chapterContent, contentH, contentW);
      // SpUtil.putStringList('pages' + id, r.pageOffsets);
    }
    // } else {
    //   r.pageOffsets = [r.chapterContent];
    //   if (SpUtil.haveKey('height' + id)) {
    //     r.height = SpUtil.getDouble('height' + id);
    //   } else {
    //     r.height = ReaderPageAgent()
    //         .getPageHeight(r.chapterContent, contentH, contentW);
    //     SpUtil.putDouble('height' + id, r.height);
    //   }
    // }
    return r;
  }

  fillAllContent({bool notify = true}) {
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
    if (notify) {
      notifyListeners();
    }
  }

//  Color.fromRGBO(122, 122, 122, 1)

  modifyFont() {
    if (!font) {
      font = !font;
    }

    // SpUtil.putDouble('fontSize', fontSize);

    bookTag.index = 0;

    var keys = SpUtil.getKeys();
    for (var key in keys) {
      if (key.contains("pages")) {
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

  saveData() async {
    SpUtil.putString(book.Id, "");
    await DbHelper.instance
        .updBookProcess(bookTag?.cur ?? 0, bookTag?.index ?? 0, book.Id);
    SpUtil.putStringList('${book.Id}pages${prePage?.chapterName ?? ' '}',
        prePage?.pageOffsets ?? []);
    SpUtil.putStringList('${book.Id}pages${curPage?.chapterName ?? ''}',
        curPage?.pageOffsets ?? []);
    SpUtil.putStringList('${book.Id}pages${nextPage?.chapterName ?? ''}',
        nextPage?.pageOffsets ?? []);
    String userName = SpUtil.getString("username");
    if (userName.isNotEmpty) {
      Util(null)
          .http()
          .patch(Common.process + '/$userName/${book.Id}/${bookTag?.cur ?? 0}');
    }
    print("保存成功");
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
      if (f.contains('pages')) {
        SpUtil.remove(f);
      }
    });
  }

  downloadAll(int start) async {
    if (chapters?.isEmpty ?? 0 == 0) {
      await getChapters();
//      saveData();

    }
    // List<String> ids = [];
    // if (SpUtil.haveKey(Common.downloadlist)) {
    //   ids = SpUtil.getStringList(Common.downloadlist);
    // }
    // if (!ids.contains(book.Id)) {
    //   ids.add(book.Id);
    // }
    // SpUtil.putStringList(Common.downloadlist, ids);
    for (var i = start; i < chapters.length; i++) {
      Chapter chapter = chapters[i];
      var id = chapter.id;
      var bool = await DbHelper.instance.getHasContent(id);
      if (!bool) {
        String content = await compute(requestDataWithCompute, id);
        if (content.isNotEmpty) {
          // SpUtil.putString(chapter.id, content);
          DbHelper.instance.udpChapter(content, id);
          chapter.hasContent = 2;
        }
      }
      await Future.delayed(Duration(seconds: 1));
    }

    BotToast.showText(text: "${book?.Name ?? ""}下载完成");
    // SpUtil.putString('${book.Id}chapters', jsonEncode(chapters));
  }

  static Future<String> requestDataWithCompute(String id) async {
    try {
      var url = Common.bookContentUrl + '/$id';
      var client = new HttpClient();
      var request = await client.getUrl(Uri.parse(url));
      var response = await request.close();
      var responseBody = await response.transform(utf8.decoder).join();
      var dataList = await parseJson(responseBody);
      return dataList['data']['content'];
    } catch (e) {
      print(e);
    }
  }

  Widget firstPage() {
    return Container(
      padding: EdgeInsets.only(top: 150),
      child: Center(
        child: Column(
          children: [
            CachedNetworkImage(
              imageUrl: book.Img,
              width: 150,
              height: 160,
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              book.Name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              overflow: TextOverflow.clip,
            ),
            SizedBox(
              height: 5,
            ),
            Text(
              book.Author,
              style: TextStyle(
                fontWeight: FontWeight.w100,
                fontSize: 10,
              ),
            ),
            SizedBox(
              height: 45,
            ),
          ],
        ),
      ),
    );
  }

  Widget noMorePage() {
    return Container(
      child: Text('曾经沧海难为水,除却巫山不是云'),
    );
  }

  List<Widget> chapterContent(ReadPage r) {
    List<Widget> contents = [];
    for (var i = 0; i < r.pageOffsets.length; i++) {
      var content = r.pageOffsets[i];
//      if (content.startsWith("\n")) {
//        content = content.substring(1);
//      }

      contents.add(Store.connect<ColorModel>(
          builder: (context, ColorModel model, child) {
        return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (TapDownDetails details) {
              if (isPage) {
                tapPage(context, details);
              }
            },
            child: (r.chapterName == "-1" || r.chapterName == "1")
                ? (r.chapterName == "1" ? firstPage() : noMorePage())
                : isPage
                    ? Container(
                        child: Column(
                          children: <Widget>[
                            SizedBox(height: ScreenUtil.getStatusBarH(context)),
                            Container(
                              height: 30,
                              padding: EdgeInsets.only(left: 3),
                              child: Text(
                                r.chapterName,
                                // strutStyle: StrutStyle(
                                //     forceStrutHeight: true,
                                //     height: textLineHeight),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: model.dark
                                      ? Colors.white38
                                      : Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                                child: Container(
                                    padding: EdgeInsets.fromLTRB(
                                        15, 0, 5, Screen.bottomSafeHeight),
                                    child: Text.rich(
                                      TextSpan(children: [
                                        TextSpan(
                                            text: content,
                                            style: TextStyle(
                                              textBaseline:
                                                  TextBaseline.ideographic,
                                              color: model.dark
                                                  ? Colors.white54
                                                  : Colors.black,
                                              fontSize:
                                                  ReadSetting.getFontSize() /
                                                      Screen.textScaleFactor,
                                              // height: ReadSetting
                                              //     .getLatterHeight(),
                                              // letterSpacing: ReadSetting
                                              //     .getLatterSpace()
                                            ))
                                      ]),
                                      textAlign: TextAlign.justify,
                                    ))),
                            Container(
                              height: 30,
                              padding: EdgeInsets.only(right: 8),
                              child: Row(
                                children: <Widget>[
                                  Expanded(child: Container()),
                                  Text(
                                    '第${i + 1}/${r.pageOffsets.length}页',
                                    // strutStyle: StrutStyle(
                                    //     forceStrutHeight: true,
                                    //     height: textLineHeight),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: model.dark
                                          ? Colors.white38
                                          : Colors.black,
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
                      )
                    : Column(
                        children: [
                          Center(
                            child: Text(
                              r.chapterName,
                              style: TextStyle(
                                  fontSize: ReadSetting.getFontSize() + 2.0),
                            ),
                          ),
                          Container(
                              padding: EdgeInsets.only(
                                right: 5,
                                left: 15,
                              ),
                              child: Text(
                                content,
                                style: TextStyle(
                                    color: model.dark
                                        ? Color.fromRGBO(128, 128, 128, 1)
                                        : null,
                                    fontSize: ReadSetting.getFontSize() /
                                        Screen.textScaleFactor),
                                textAlign: TextAlign.justify,
                              ))
                        ],
                      ));
      }));
    }
    return contents;
  }

  clear() async {
    bookTag = null;
    allContent = null;
    chapters = [];
    // await _DbHelper.instance.close();

    // pageController.dispose();
    loadOk = false;
  }

  Future<void> reloadChapters() async {
    chapters = [];
    DbHelper.instance.clearChapters(book.Id);

    // var key = '${book.Id}chapters';
    // if (SpUtil.haveKey(key)) {
    //   SpUtil.remove(key);
    // }
    var url = Common.chaptersUrl + '/${book.Id}/0';
    Response response = await Util(null).http().get(url);

    List data = response.data['data'];
    if (data == null) {
      print("load cps ok");
      return;
    }

    chapters = data.map((c) => Chapter.fromJson(c)).toList();

    // SpUtil.putString('${book.Id}chapters', jsonEncode(chapters));
    DbHelper.instance.addChapters(chapters, book.Id);
    notifyListeners();
  }

  Future<void> reloadCurrentPage() async {
    toggleShowMenu();
    var chapter = chapters[bookTag.cur];
    var future =
        await Util(context).http().get(Common.reload + '/${chapter.id}/reload');
    var content = future.data['data']['content'];
    if (content.isNotEmpty) {
      // SpUtil.putString(chapter.id, content);
      DbHelper.instance.udpChapter(content, chapter.id);
      chapters[bookTag.cur].hasContent = 2;
    }
    curPage = await loadChapter(bookTag.cur);
    fillAllContent();
  }

  reSetPages() {
    prePage = null;
    curPage = null;
    nextPage = null;
  }

  @override
  Future<void> dispose() async {
    super.dispose();
  }
}
