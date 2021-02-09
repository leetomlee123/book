import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:battery/battery.dart';
import 'package:book/common/DbHelper.dart';
import 'package:book/common/Http.dart';
import 'package:book/common/LoadDialog.dart';
import 'package:book/common/ReadSetting.dart';
import 'package:book/common/ReaderPageAgent.dart';
import 'package:book/common/Screen.dart';
import 'package:book/common/common.dart';
import 'package:book/entity/Book.dart';
import 'package:book/entity/Chapter.dart';
import 'package:book/entity/ChapterNode.dart';
import 'package:book/entity/EveryPoet.dart';
import 'package:book/entity/ReadPage.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/system/BatteryView.dart';
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
  EveryPoet _everyPoet;
  var currentPageValue = 0.0;

  var electricQuantity = 1.0;
  double allContentHeight = 0;

  //本书记录
  // BookTag bookTag;
  ReadPage prePage;
  ReadPage curPage;
  ReadPage nextPage;
  List<Widget> allContent = [];
  List<ReadPage> allPages = [];

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

  //缓存批量提交大小
  int batchNum = 100;
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
    electricQuantity = (await Battery().batteryLevel) / 100;
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
      checkCur();

      await intiPageContent(book.cur, false);
      // if (isPage) {
      if (book.index == -1) {
        //最后一页
        book.index = (prePage?.pageOffsets?.length ?? 0) +
            (curPage?.pageOffsets?.length ?? 0) -
            1;
      }
      if (isPage) {
        pageController = PageController(initialPage: book.index);
      } else {
        listController = ScrollController(initialScrollOffset: book.position);
      }
      loadOk = true;
      //本书已读过
    } else {
      int cur = 0;
      String userName = SpUtil.getString("username");
      if (userName.isNotEmpty) {
        var url = Common.process + '/$userName/${book.Id}';
        Response response = await HttpUtil().http().get(url);
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
      if (isPage) {
        int idx = (cur == 0) ? 0 : (prePage?.pageOffsets?.length ?? 0);
        book.index = idx;
        pageController = PageController(initialPage: idx);
      } else {
        allContentHeight = (prePage?.height ?? 0) +
            (curPage?.height ?? 0) +
            (nextPage?.height ?? 0);
        listController = ScrollController(
            initialScrollOffset: book.cur == 0 ? 0 : prePage?.height ?? 0);

        listController.addListener(() {
          if (load == Load.Done) {
            if (listController.offset >=
                ((prePage?.height ?? 0) + (curPage?.height ?? 0))) {
              //翻到下一页
              print('预加载下一章');
              loadNextChapter();
            }
          } else if (listController.offset < prePage.height) {
            print('预加载上一章');
            loadPreChapter();
          }
        });
      }
      loadOk = true;
    }
    notifyListeners();
  }

  loadPreChapter() {
    load = Load.Loading;

    load = Load.Done;
  }

  loadNextChapter() async {
    load = Load.Loading;
    //下一章
    int tempCur = book.cur + 1;
    if (tempCur >= chapters.length) {
      //到最后一页
      book.index = -1;
    } else {
      book.cur += 1;

      if (nextPage.chapterName == "-1") {
        BotToast.showCustomLoading(toastBuilder: (_) => LoadingDialog());
        curPage = await loadChapter(book.cur);
        BotToast.closeAllLoading();
      }

      ReadPage temp = await loadChapter(book.cur + 1);
      if (book.cur == tempCur) {
        //计算此时在nextPage的位置
        // double positionX = listController.offset - (txPage?.height ?? 0);
        allContentHeight += temp?.height ?? 0;
        if (temp != null) {
          allContent.addAll(chapterContent(temp));
        }
        allPages.add(temp);
        //每次翻页刷新电池电量
        electricQuantity = (await Battery().batteryLevel) / 100;
        if (refresh) {
          notifyListeners();
        }
      }
    }
    load = Load.Done;
  }

  checkCur() {
    if (book.cur < 0) {
      book.cur = 0;
    }
    if (book.cur > chapters.length - 1) {
      book.cur = chapters.length - 1;
    }
  }

  Future intiPageContent(int idx, bool jump) async {
    BotToast.showCustomLoading(toastBuilder: (_) => LoadingDialog());

    try {
      await Future.wait([
        loadChapter(idx - 1).then((value) => {prePage = value}),
        loadChapter(idx).then((value) => {curPage = value}),
        loadChapter(idx + 1).then((value) => {nextPage = value}),
      ]);
      if (!isPage) {
        allPages = [];
        allPages.add(prePage);
        allPages.add(curPage);
        allPages.add(nextPage);
      }
      fillAllContent(refresh: jump);
      if (jump) {
        if (isPage) {
          int ix = prePage?.pageOffsets?.length ?? 0;
          pageController.jumpToPage(ix);
        } else {
          listController.jumpTo(prePage?.height ?? 0);
        }
      }
    } catch (e) {
      print(e);
    }
    BotToast.closeAllLoading();
  }

  fillAllContent({bool refresh = true}) async {
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
    //每次翻页刷新电池电量
    electricQuantity = (await Battery().batteryLevel) / 100;
    if (refresh) {
      notifyListeners();
    }
  }

  //触发章节
  changeChapter(int idx) async {
    book.index = idx;
    int preLen = prePage?.pageOffsets?.length ?? 0;
    int curLen = curPage?.pageOffsets?.length ?? 0;

    if ((idx + 1 - preLen) > (curLen)) {
      //下一章
      int tempCur = book.cur + 1;
      if (tempCur >= chapters.length) {
        //到最后一页
        book.index = -1;
      } else {
        book.cur += 1;
        prePage = curPage;
        if (nextPage.chapterName == "-1") {
          BotToast.showCustomLoading(toastBuilder: (_) => LoadingDialog());
          curPage = await loadChapter(book.cur);
          int preLen = prePage?.pageOffsets?.length ?? 0;
          int curLen = curPage?.pageOffsets?.length ?? 0;
          book.index = preLen + curLen - 1;
          BotToast.closeAllLoading();
        } else {
          curPage = nextPage;
        }
        nextPage = null;
        fillAllContent();
        pageController.jumpToPage(prePage?.pageOffsets?.length ?? 0);
        ReadPage temp = await loadChapter(book.cur + 1);
        if (book.cur == tempCur) {
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
        await HttpUtil(showLoading: chapters.isEmpty).http().get(url);

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
    //本地内容是否存在
    if (chapters[idx].hasContent != 2) {
      r.chapterContent = await compute(requestDataWithCompute, id);
      if (r.chapterContent.isNotEmpty) {
        var temp = [ChapterNode(r.chapterContent, id)];
        DbHelper.instance.udpChapter(temp);
        chapters[idx].hasContent = 2;
      }
    } else {
      r.chapterContent = await DbHelper.instance.getContent(id);
    }
    if (r.chapterContent.isEmpty) {
      r.chapterContent = "章节数据不存在,可手动重载或联系管理员";
      r.pageOffsets = [(r.chapterContent.length - 1).toString()];
      return r;
    }
    //本地是否有分页的缓存
    if (isPage) {
      var k = '${book.Id}pages' + r.chapterName;

      if (SpUtil.haveKey(k)) {
        r.pageOffsets = SpUtil.getStringList(k);
        SpUtil.remove(k);
      } else {
        r.pageOffsets = ReaderPageAgent()
            .getPageOffsets(r.chapterContent, contentH, contentW);
      }
    } else {
      r.pageOffsets = [r.chapterContent];
      if (SpUtil.haveKey('height' + id)) {
        r.height = SpUtil.getDouble('height' + id);
      } else {
        r.height = ReaderPageAgent().getPageHeight(r.chapterContent, contentW);
      }
      //章节内容不满一页 按一页算
      r.height = r.height >= Screen.height ? r.height : Screen.height;
    }
    return r;
  }

  //章节内容变动 刷新
  // freshPageContents(ReadPage readPage, {bool refresh = true}) async {
  //   switch (readPage.position) {
  //     case -1:
  //       if (prePage != null) {
  //         allContent.addAll(chapterContent(prePage));
  //         pageController.jumpToPage(
  //             prePage.pageOffsets.length + pageController.page.toInt());
  //         print("pre load ok ${pageController.page}");
  //       }
  //       break;
  //     case 0:
  //       if (curPage != null) {
  //         allContent.addAll(chapterContent(curPage));
  //         pageController.jumpToPage(0);
  //         print("cur load ok ${pageController.page}");
  //       }
  //       break;
  //     case 1:
  //       if (nextPage != null) {
  //         allContent.addAll(chapterContent(nextPage));
  //       }
  //       break;
  //   }
  //   //每次翻页刷新电池电量
  //   electricQuantity = (await Battery().batteryLevel) / 100;
  //   notifyListeners();
  // }

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
    fillAllContent(refresh: true);
    intiPageContent(book.cur, true);
  }

  toggleShowMenu() {
    showMenu = !showMenu;
    notifyListeners();
  }

  saveData() async {
    if (sSave) {
      SpUtil.putString(book.Id, "");
      if (isPage) {
        await DbHelper.instance
            .updBookProcess(book?.cur ?? 0, book?.index ?? 0, 0.0, book.Id);
        SpUtil.putStringList('${book.Id}pages${prePage?.chapterName ?? ' '}',
            prePage?.pageOffsets ?? []);
        SpUtil.putStringList('${book.Id}pages${curPage?.chapterName ?? ''}',
            curPage?.pageOffsets ?? []);
        SpUtil.putStringList('${book.Id}pages${nextPage?.chapterName ?? ''}',
            nextPage?.pageOffsets ?? []);
      } else {
        double position = allContentHeight - listController.offset;
        await DbHelper.instance.updBookProcess(
            book?.cur ?? 0, book?.index ?? 0, position, book.Id);
        var len = allPages.length;
        for (var i = 1; i <= 3; i++) {
          var id = chapters[len - i].id;
          var h = allPages[len - i].height;
          SpUtil.putDouble('height' + id, h);
        }
      }
      String userName = SpUtil.getString("username");
      if (userName.isNotEmpty) {
        HttpUtil()
            .http()
            .patch(Common.process + '/$userName/${book.Id}/${book?.cur ?? 0}');
      }
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
      width: Screen.width,
      height: Screen.height,
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
    return _everyPoet == null
        ? Center(
            child: Text('等待作者更新'),
          )
        : Container(
            width: Screen.width,
            height: Screen.height,
            decoration: BoxDecoration(
                image: DecorationImage(
                    image:
                        CachedNetworkImageProvider('${_everyPoet.share ?? ''}'),
                    fit: BoxFit.fitWidth)),
          );
    // return Ad();
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

      String content;

      for (var i = 0; i < sum; i++) {
        if (isPage) {
          int end = int.parse(r.pageOffsets[i]);
          content = cts.substring(0, end);
          cts = cts.substring(end, cts.length);

          while (cts.startsWith("\n")) {
            cts = cts.substring(1);
          }
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
                          pageHead(r, model),
                          pageMiddleContent(content, model),
                          pageFoot(model, i, r)
                        ],
                        crossAxisAlignment: CrossAxisAlignment.start,
                      ),
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : Container(
                      margin: EdgeInsets.only(
                          left: 17,
                          right: 13,
                          bottom: ReadSetting.listPageBottom),
                      alignment: Alignment.centerLeft,
                      child: Column(
                        children: [
                          Container(
                            child: Center(
                              child: Text(
                                chapters[book.cur].name,
                                style: TextStyle(
                                    fontFamily: SpUtil.getString("fontName",
                                        defValue: "Roboto"),
                                    color: model.dark
                                        ? Color(0x8FFFFFFF)
                                        : Colors.black,
                                    locale: Locale('zh_CN'),
                                    letterSpacing: ReadSetting.getLatterSpace(),
                                    fontSize: ReadSetting.getFontSize() + 3,
                                    height: ReadSetting.getLineHeight()),
                              ),
                            ),
                            height: ReadSetting.listPageChapterName,
                          ),
                          RichText(
                            textAlign: TextAlign.justify,
                            textScaleFactor: Screen.textScaleFactor,
                            text: TextSpan(children: [
                              TextSpan(
                                text: r.chapterContent,
                                style: TextStyle(
                                    fontFamily: SpUtil.getString("fontName",
                                        defValue: "Roboto"),
                                    color: model.dark
                                        ? Color(0x8FFFFFFF)
                                        : Colors.black,
                                    locale: Locale('zh_CN'),
                                    decorationStyle: TextDecorationStyle.wavy,
                                    letterSpacing: ReadSetting.getLatterSpace(),
                                    fontSize: ReadSetting.getFontSize(),
                                    height: ReadSetting.getLineHeight()),
                              )
                            ]),
                          ),
                        ],
                      )));
        }));
      }
    }

    return contents;
  }

  Widget pageFoot(var model, var i, var r) {
    return Container(
      height: 30,
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: <Widget>[
          BatteryView(
            electricQuantity: electricQuantity,
          ),
          SizedBox(
            width: 4,
          ),
          Text(
            '${DateUtil.formatDate(DateTime.now(), format: DateFormats.h_m)}',
            style: TextStyle(
              fontSize: 12 / Screen.textScaleFactor,
              color: model.dark ? Color(0x8FFFFFFF) : Colors.black54,
            ),
          ),
          Spacer(),

          // Expanded(child: Container()),
          Text(
            '第${i + 1}/${r.pageOffsets.length}页',
            style: TextStyle(
              fontSize: 12 / Screen.textScaleFactor,
              color: model.dark ? Color(0x8FFFFFFF) : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget pageMiddleContent(var content, var model) {
    return Expanded(
        child: Container(
            margin: EdgeInsets.only(left: 17, right: 13),
            alignment: Alignment.centerLeft,
            child: RichText(
              textAlign: TextAlign.justify,
              textScaleFactor: Screen.textScaleFactor,
              text: TextSpan(children: [
                TextSpan(
                  text: content,
                  style: TextStyle(
                      fontFamily:
                          SpUtil.getString("fontName", defValue: "Roboto"),
                      color: model.dark ? Color(0x8FFFFFFF) : Colors.black,
                      locale: Locale('zh_CN'),
                      decorationStyle: TextDecorationStyle.wavy,
                      letterSpacing: ReadSetting.getLatterSpace(),
                      fontSize: ReadSetting.getFontSize(),
                      height: ReadSetting.getLineHeight()),
                )
              ]),
            )));
  }

  Widget pageHead(var r, var model) {
    return Container(
      height: 30,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(left: 20),
      child: Text(
        r.chapterName,
        style: TextStyle(
          fontSize: 12 / Screen.textScaleFactor,
          color: model.dark ? Color(0x8FFFFFFF) : Colors.black54,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  clear() async {
    allContent = null;
    chapters = [];
    loadOk = false;
  }

  Future<void> reloadChapters() async {
    chapters = [];
    DbHelper.instance.clearChapters(book.Id);

    var url = Common.chaptersUrl + '/${book.Id}/0';
    Response response = await HttpUtil().http().get(url);

    List data = response.data['data'];
    if (data == null) {
      return;
    }

    chapters = data.map((c) => Chapter.fromJson(c)).toList();

    DbHelper.instance.addChapters(chapters, book.Id);
    notifyListeners();
  }

  Future<void> reloadCurrentPage() async {
    toggleShowMenu();
    var chapter = chapters[book.cur];
    var future = await HttpUtil(showLoading: true)
        .http()
        .get(Common.reload + '/${chapter.id}/reload');
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
    List<Chapter> temp = chapters;
    if (temp?.isEmpty ?? 0 == 0) {
      await getChapters();
    }
    List<ChapterNode> cpNodes = [];
    for (var i = start; i < temp.length; i++) {
      Chapter chapter = temp[i];
      var id = chapter.id;
      print("download chapter id is :$id");
      if (chapter.hasContent != 2) {
        String content = await compute(requestDataWithCompute, id);
        if (content.isNotEmpty) {
          cpNodes.add(ChapterNode(content, id));
        }
      }
      if (cpNodes.length % batchNum == 0) {
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
    String content = "";
    try {
      var url = Common.bookContentUrl + '/$id';
      var client = new HttpClient();
      // print('download $url');
      var request = await client.getUrl(Uri.parse(url));
      var response = await request.close();
      // print('download $url ok');
      var responseBody = await response.transform(utf8.decoder).join();
      var dataList = await parseJson(responseBody);
      content = dataList['data']['content'];
    } catch (E) {
      log(E);
    }
    return content;
  }

  @override
  Future<void> dispose() async {
    super.dispose();
  }

  Widget pageContent(ColorModel model, var content) {
    return Expanded(
        child: Container(
            margin: EdgeInsets.only(left: 17, right: 13),
            // alignment: i == (sum - 1)
            //     ? Alignment.topLeft
            //     : Alignment.centerLeft,
            child: RichText(
              textAlign: TextAlign.justify,
              textScaleFactor: Screen.textScaleFactor,
              text: TextSpan(children: [
                TextSpan(
                  text: content,
                  style: TextStyle(
                      fontFamily:
                          SpUtil.getString("fontName", defValue: "Roboto"),
                      color: model.dark ? Color(0x8FFFFFFF) : Colors.black,
                      locale: Locale('zh_CN'),
                      decorationStyle: TextDecorationStyle.wavy,
                      letterSpacing: ReadSetting.getLatterSpace(),
                      fontSize: ReadSetting.getFontSize(),
                      height: ReadSetting.getLineHeight()),
                )
              ]),
            )));
  }

  getEveryNote() async {
    if (_everyPoet != null) {
      return;
    }
    var url = "http://open.iciba.com/dsapi";
    var client = new HttpClient();

    var request = await client.getUrl(Uri.parse(url));
    var response = await request.close();

    var responseBody = await response.transform(utf8.decoder).join();
    var dataList = await parseJson(responseBody);

    _everyPoet = EveryPoet(dataList['note'], dataList['picture4'],
        dataList['content'], dataList['fenxiang_img']);
  }
}
