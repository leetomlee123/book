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
import 'package:book/entity/Chapter.dart';
import 'package:book/entity/ChapterNode.dart';
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

enum Load { Loading, Done }

class ReadModel with ChangeNotifier {
  Book book;
  List<Chapter> chapters = [];

  //本书记录
  // BookTag bookTag;
  ReadPage prePage;
  ReadPage curPage;
  ReadPage nextPage;
  List<Widget> allContent = [];

  //页面控制器
  PageController pageController;
  ScrollController listController;

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
  //缓存批量提交大小
  int BATCH_NUM = 100;
  bool refresh = true;

  //显示上层 设置
  bool showMenu = false;

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

  bool sSave;
  Load load;

  //获取本书记录
  getBookRecord() async {
    showMenu = false;
    font = false;
    loadOk = false;
    sSave = true;
    load = Load.Done;
    if (SpUtil.haveKey(book.Id)) {
      chapters = await DbHelper.instance.getChapters(book.Id);

      if (chapters.isEmpty) {
        await getChapters();
      } else {
        getChapters();
      }

      //书的最后一章
      if (book.CId == "-1") {
        book.cur = chapters.length - 1;
      }
      await intiPageContent(book.cur, false);
      // if (isPage) {
      pageController = PageController(initialPage: book.index);
      // } else {
      //   listController = ScrollController(initialScrollOffset: bookTag.offset);
      // }
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
      book.cur = cur;
      if (SpUtil.haveKey('${book.Id}chapters')) {
        chapters = await DbHelper.instance.getChapters(book.Id);
      } else {
        await getChapters();
      }

      if (book.CId == "-1") {
        book.cur = chapters.length - 1;
      }
      await intiPageContent(book?.cur ?? 0, false);
      int idx = (cur == 0) ? 0 : (prePage?.pageOffsets?.length ?? 0);
      if (isPage) {
        pageController = PageController(initialPage: idx);
      } else {
        listController = ScrollController(initialScrollOffset: 0.0);
      }
      book.index = idx;
      loadOk = true;
    }
//      if (pageController.hasClients) {
//        pageController.jumpToPage(idx);
//      }
    // if (!isPage) {
    //   listController.addListener(() {
    //     double offset = listController.offset;
    //     print(offset);
    // if (offset > (prePage.height + curPage.height)) {
    //   print('准备下一章');
    //   //  print("next chapter");
    //   //  if (!chapterLoading) {
    //   //    nextChapter();
    //   //  }
    // }
    //   });
    // }
    notifyListeners();
  }

  checkPosition(double offset) {
    if ((Load.Done == load) && (offset > (prePage.height + curPage.height))) {
      // print('准备下一章');
      nextChapter();
    }
  }

  nextChapter() async {
    load = Load.Loading;
    double hs = prePage.height + curPage.height + Screen.height;
    int tempCur = book.cur + 1;
    if (tempCur >= chapters.length) {
      BotToast.showText(text: "已经是最后一页");
      pageController.previousPage(
          duration: Duration(microseconds: 1), curve: Curves.ease);
    } else {
      book.cur += 1;
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
        curPage = await loadChapter(book.cur);
        int preLen = prePage?.pageOffsets?.length ?? 0;
        int curLen = curPage?.pageOffsets?.length ?? 0;
        book.index = preLen + curLen - 1;
        Navigator.pop(context);
      } else {
        curPage = nextPage;
      }
      nextPage = null;
      fillAllContent();
      double offset = listController.offset;
      var d = offset - hs;
      // listController.animateTo(
      //   d,
      //   duration: new Duration(milliseconds: 300), // 300ms
      //   curve: Curves.bounceIn,
      // );
      listController.jumpTo(d);
      // print('load next ok');
      ReadPage temp = await loadChapter(book.cur + 1);
      if (book.cur == tempCur) {
        // print('next init');
        nextPage = temp;
        fillAllContent();
      }
    }
    load = Load.Done;
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
    await Future.wait<dynamic>(
            [loadChapter(idx - 1), loadChapter(idx), loadChapter(idx + 1)])
        .then((e) {
      prePage = e[0];
      curPage = e[1];
      nextPage = e[2];
      // print(e); //[true,true,false]
    }).catchError((e) {
      print(e);
    });
    // await Future.wait([
    //   loadChapter(idx - 1).then((value) => {prePage = value}),
    //   loadChapter(idx).then((value) => {curPage = value}),
    //   loadChapter(idx + 1).then((value) => {nextPage = value}),
    // ]);
    // prePage = await loadChapter(idx - 1);
    // curPage = await loadChapter(idx);
    // nextPage = await loadChapter(idx + 1);

    fillAllContent(notify: jump);
    if (isPage && jump) {
      int ix = prePage?.pageOffsets?.length ?? 0;
      pageController.jumpToPage(ix);
    }
    Navigator.pop(context);
  }

  changeChapter(int idx) async {
    book.index = idx;
    int preLen = prePage?.pageOffsets?.length ?? 0;
    int curLen = curPage?.pageOffsets?.length ?? 0;

    // print("idx:$idx preLen:$preLen curLen:$curLen");
    if ((idx + 1 - preLen) > (curLen)) {
      //下一章
      int tempCur = book.cur + 1;
      if (tempCur >= chapters.length) {
        BotToast.showText(text: "已经是最后一页");
        pageController.previousPage(
            duration: Duration(microseconds: 1), curve: Curves.ease);
      } else {
        book.cur += 1;
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
          curPage = await loadChapter(book.cur);
          int preLen = prePage?.pageOffsets?.length ?? 0;
          int curLen = curPage?.pageOffsets?.length ?? 0;
          book.index = preLen + curLen - 1;
          Navigator.pop(context);
        } else {
          curPage = nextPage;
        }
        nextPage = null;
        fillAllContent();
        pageController.jumpToPage(prePage?.pageOffsets?.length ?? 0);
        // print('load next ok');
        ReadPage temp = await loadChapter(book.cur + 1);
        if (book.cur == tempCur) {
          // print('next init');
          nextPage = temp;
          fillAllContent();
        }
      }
    } else if (idx < preLen) {
      //上一章
      print('上一张');
      int tempCur = book.cur - 1;
      if (tempCur < 0) {
        return;
      } else {
        book.cur -= 1;
        nextPage = curPage;
        curPage = prePage;
        prePage = null;
        fillAllContent();
        var p = curPage?.pageOffsets?.length ?? 0;
        pageController.jumpToPage(p > 0 ? p - 1 : 0);
        ReadPage temp = await loadChapter(book.cur - 1);
        if (tempCur == book.cur) {
          prePage = temp;
          fillAllContent();
          int ix = (prePage?.pageOffsets?.length ?? 0) + idx;
          pageController.jumpToPage(ix);
        }
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
      // print("load cps ok");
      return;
    }

    List<Chapter> list = data.map((c) => Chapter.fromJson(c)).toList();
    chapters.addAll(list);
    //书的最后一章
    if (book.CId == "-1") {
      book.cur = chapters.length - 1;
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
    if (chapters[idx].hasContent != 2) {
      r.chapterContent = await compute(requestDataWithCompute, id);
      if (r.chapterContent.isNotEmpty) {
        // SpUtil.putString(id, r.chapterContent);
        var temp = [ChapterNode(r.chapterContent, id)];
        DbHelper.instance.udpChapter(temp);
        chapters[idx].hasContent = 2;
      }
      // SpUtil.putString('${book.Id}chapters', jsonEncode(chapters));
    } else {
      r.chapterContent = await DbHelper.instance.getContent(id);
    }
    if (r.chapterContent.isEmpty) {
      r.chapterContent = "章节数据不存在,可手动重载或联系管理员";
      r.pageOffsets = [(r.chapterContent.length - 1).toString()];
      return r;
    }
    if (isPage) {
      var k = '${book.Id}pages' + r.chapterName;
      // bool has = await DbHelper.instance.hasContents(k);
      if (SpUtil.haveKey(k)) {
        r.pageOffsets = SpUtil.getStringList(k);
        SpUtil.remove(k);
        // r.pageOffsets = await DbHelper.instance.getContents(k);
        // await DbHelper.instance.delContents(k);
      } else {
        r.pageOffsets = ReaderPageAgent()
            .getPageOffsets(r.chapterContent, contentH, contentW);
        // SpUtil.putStringList('pages' + id, r.pageOffsets);
      }
    } else {
      r.pageOffsets = [r.chapterContent];
      if (SpUtil.haveKey('height' + id)) {
        r.height = SpUtil.getDouble('height' + id);
      } else {
        r.height = ReaderPageAgent().getPageHeight(r.chapterContent, contentW);
      }
    }
    print("xx $idx");
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

    book.index = 0;

    var keys = SpUtil.getKeys();
    for (var key in keys) {
      if (key.contains("pages")) {
        SpUtil.remove(key);
      }
    }
    intiPageContent(book.cur, true);
//    notifyListeners();
  }

  toggleShowMenu() {
    showMenu = !showMenu;
    notifyListeners();
  }

  saveData() async {
    if (sSave) {
      SpUtil.putString(book.Id, "");
      await DbHelper.instance
          .updBookProcess(book?.cur ?? 0, book?.index ?? 0, book.Id);
      // await DbHelper.instance.addCords(
      //     '${book.Id}pages${prePage?.chapterName ?? ' '}',
      //     prePage?.pageOffsets ?? []);
      // await DbHelper.instance.addCords(
      //     '${book.Id}pages${curPage?.chapterName ?? ' '}',
      //     curPage?.pageOffsets ?? []);
      // await DbHelper.instance.addCords(
      //     '${book.Id}pages${nextPage?.chapterName ?? ' '}',
      //     nextPage?.pageOffsets ?? []);
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
            .patch(Common.process + '/$userName/${book.Id}/${book?.cur ?? 0}');
      }
      // print("保存成功");
    }
  }

  void tapPage(BuildContext context, TapDownDetails details) {
    var wid = ScreenUtil.getScreenW(context);
    var space = wid / 3;
    var curWid = details.localPosition.dx;
    if (isPage && (curWid > 0 && curWid < space)) {
      pageController.previousPage(
          duration: Duration(microseconds: 1), curve: Curves.ease);
    } else if (curWid > space && curWid < 2 * space) {
      toggleShowMenu();
    } else {
      if (isPage) {
        pageController.nextPage(
            duration: Duration(microseconds: 1), curve: Curves.ease);
      }
    }
  }

  reCalcPages() {
    SpUtil.getKeys().forEach((f) {
      if (f.contains('pages')) {
        SpUtil.remove(f);
      }
    });
  }

  Widget firstPage() {
    return Container(
      padding: EdgeInsets.only(top: 100),
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
              height: 15,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                book.Desc,
                style: TextStyle(
                  fontWeight: FontWeight.w100,
                  fontSize: 11,
                ),
              ),
            ),
            // SizedBox(
            //   height: Screen.height / 2,
            // )
          ],
        ),
      ),
    );
  }

  Widget noMorePage() {
    return Container(
      child: Center(
        child: Text('曾经沧海难为水,除却巫山不是云'),
      ),
    );
  }

  List<Widget> chapterContent(ReadPage r) {
    List<Widget> contents = [];
    String cts = r.chapterContent;
    if (r.chapterName == "-1" || r.chapterName == "1") {
      contents.add(GestureDetector(
        child: r.chapterName == "1" ? firstPage() : noMorePage(),
        behavior: HitTestBehavior.opaque,
        onTapDown: (TapDownDetails details) {
          tapPage(context, details);
        },
      ));
    } else {
      int sum = r.pageOffsets.length;
      for (var i = 0; i < sum; i++) {
        int end = int.parse(r.pageOffsets[i]);
        String content = cts.substring(0, end);
        cts = cts.substring(end, cts.length);

        while (cts.startsWith("\n")) {
          cts = cts.substring(1);
        }

        contents.add(Store.connect<ColorModel>(
            builder: (context, ColorModel model, child) {
          return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (TapDownDetails details) {
                tapPage(context, details);
              },
              child: isPage
                  ? Container(
                      child: Column(
                        children: <Widget>[
                          SizedBox(height: ScreenUtil.getStatusBarH(context)),
                          Container(
                            height: 30,
                            alignment: Alignment.centerLeft,
                            padding: EdgeInsets.only(left: 3),
                            child: Text(
                              r.chapterName,
                              // strutStyle: StrutStyle(
                              //     forceStrutHeight: true,
                              //     height: textLineHeight),
                              style: TextStyle(
                                fontSize: 12 / Screen.textScaleFactor,
                                color:
                                    model.dark ? Colors.white30 : Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                              child: Container(
                                  padding: EdgeInsets.fromLTRB(15, 0, 5, 0),
                                  alignment: i == (sum - 1)
                                      ? Alignment.topLeft
                                      : Alignment.centerLeft,
                                  child: Text(
                                    content,
                                    textScaleFactor: Screen.textScaleFactor,
                                    style: TextStyle(
                                        fontFamily: model.font,
                                        locale: Locale('zh_CN'),
                                        fontSize: ReadSetting.getFontSize(),
                                        height: ReadSetting.getLineHeight()),
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
                                    fontSize: 12 / Screen.textScaleFactor,
                                    color: model.dark
                                        ? Colors.white30
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
                            )),
                        SizedBox(
                          height: Screen.height / 2,
                        )
                      ],
                    ));
        }));
      }
    }
    return contents;
  }

  clear() async {
    allContent = null;
    chapters = [];
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
      // print("load cps ok");
      return;
    }

    chapters = data.map((c) => Chapter.fromJson(c)).toList();

    // SpUtil.putString('${book.Id}chapters', jsonEncode(chapters));
    DbHelper.instance.addChapters(chapters, book.Id);
    notifyListeners();
  }

  Future<void> reloadCurrentPage() async {
    toggleShowMenu();
    var chapter = chapters[book.cur];
    var future =
        await Util(context).http().get(Common.reload + '/${chapter.id}/reload');
    var content = future.data['data']['content'];
    if (content.isNotEmpty) {
      var temp = [ChapterNode(content, chapter.id)];
      await DbHelper.instance.udpChapter(temp);
      chapters[book.cur].hasContent = 2;
      curPage = await loadChapter(book.cur);
      fillAllContent();
    }
  }

  reSetPages() {
    prePage = null;
    curPage = null;
    nextPage = null;
  }

  downloadAll(int start) async {
    if (chapters?.isEmpty ?? 0 == 0) {
      await getChapters();
    }
    List<ChapterNode> cpNodes = [];
    for (var i = start; i < chapters.length; i++) {
      Chapter chapter = chapters[i];
      var id = chapter.id;
      if (chapter.hasContent != 2) {
        String content = await compute(requestDataWithCompute, id);
        if (content.isNotEmpty) {
          cpNodes.add(ChapterNode(content, id));
          chapters[i].hasContent = 2;
        }
      }
      if (cpNodes.length % BATCH_NUM == 0) {
        await DbHelper.instance.udpChapter(cpNodes);
        cpNodes.clear();
      }
    }
    if (cpNodes.isNotEmpty) {
      await DbHelper.instance.udpChapter(cpNodes);
      cpNodes.clear();
    }
    BotToast.showText(text: "${book?.Name ?? ""}下载完成");
  }

  static Future<String> requestDataWithCompute(String id) async {
    var url = Common.bookContentUrl + '/$id';
    var client = new HttpClient();
    // print('download $url');
    var request = await client.getUrl(Uri.parse(url));
    var response = await request.close();
    // print('download $url ok');
    var responseBody = await response.transform(utf8.decoder).join();
    var dataList = await parseJson(responseBody);
    String dataList2 = dataList['data']['content'];
    return dataList2;
  }

  @override
  Future<void> dispose() async {
    super.dispose();
  }
}
