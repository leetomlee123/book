import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:battery/battery.dart';
import 'package:book/common/DbHelper.dart';
import 'package:book/common/Http.dart';
import 'package:book/common/LoadDialog.dart';
import 'package:book/common/ReadSetting.dart';
import 'package:book/common/Screen.dart';
import 'package:book/common/common.dart';
import 'package:book/common/parse_html.dart';
import 'package:book/common/text_composition.dart';
import 'package:book/entity/Book.dart';
import 'package:book/entity/Chapter.dart';
import 'package:book/entity/ChapterNode.dart';
import 'package:book/entity/EveryPoet.dart';
import 'package:book/entity/ReadPage.dart';
import 'package:book/entity/TextPage.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/book/NoMorePage.dart';
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
enum FlipType { LIST_VIEW, PAGE_VIEW_SMOOTH }

class ReadModel with ChangeNotifier {
  Color darkFont = Color(0x5FFFFFFF);
  TextComposition textComposition;

  Book book;
  List<Chapter> chapters = [];
 
  var currentPageValue = 0.0;
  String poet = "";
  var topSafeHeight = .0;
  var electricQuantity = 1.0;

  // double allContentHeight = 0;
  List<Color> skins = Colors.accents;
  List<ReadPage> readPages = [];
  List<double> ladderH = [];

  //readPages 中 curPage 实际位置
  int cursor = 1;

  //本书记录
  // BookTag bookTag;
  ReadPage prePage;
  ReadPage curPage;
  ReadPage nextPage;
  List<Widget> allContent = [];
  double percent = 0;

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
  // bool isPage = false;
  bool isPage = SpUtil.getBool("isPage", defValue: true);

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
    cursor = 1;
    readPages = [];
    ladderH = [];
    getEveyPoet();

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

      await initPageContent(book.cur, false);
      // if (isPage) {

      if (isPage) {
        if (book.index == -1) {
          //最后一页
          book.index =
              (prePage?.pageOffsets ?? 0) + (curPage?.pageOffsets ?? 0) - 1;
        }
        pageController = PageController(initialPage: book.index);
      } else {
        if (book.cur == chapters.length - 1) {
          //最后一页
          book.position = ladderH[cursor];
        }
        calcPercent();
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
      await initPageContent(book?.cur ?? 0, false);
      if (isPage) {
        int idx = (cur == 0) ? 0 : (prePage?.pageOffsets ?? 0);
        book.index = idx;
        pageController = PageController(initialPage: idx);
      } else {
        double z1 = book.cur == 0 ? 0 : (prePage?.height ?? 0);
        calcPercent();
        listController = ScrollController(initialScrollOffset: z1);
      }
      loadOk = true;
    }
    // listen();

    notifyListeners();
  }

  void notifyOffset() {
    try {
      if (load == Load.Done) {
        if (listController.offset > ladderH[cursor]) {
          print('预加载下一章');
          getEveyPoet();
          loadNextChapter();
        } else if (listController.offset < ladderH[cursor - 1]) {
          print("load pre");
          if (cursor > 0) {
            cursor -= 1;
            book.cur -= 1;
          }
        }
      }
    } catch (e) {
      print(e);
      load = Load.Done;
    }
  }

  void calcPercent() {
    percent = (((book.cur) / (chapters.length)) * 100).toDouble();
  }

  loadPreChapter() async {
    load = Load.Loading;
    int tempCur = book.cur - 1;
    if (tempCur < 0) {
      return;
    } else {
      book.cur -= 1;
      nextPage = curPage;
      curPage = prePage;
      print("notify before offset ${listController.offset}");
      ReadPage temp = await loadChapter(book.cur - 1);
      if (tempCur == book.cur) {
        if (temp != null) {
          prePage = temp;
          // allContentHeight += (temp?.height ?? 0);
          allContent.insertAll(0, chapterContent(temp));
          var newOffset = (temp?.height ?? 0) + listController.offset;
          ScrollPosition position = listController.position;
          position.correctPixels(newOffset);
          // ScrollPosition newPosition = position.copyWith(
          //     pixels: newOffset, maxScrollExtent: allContentHeight);
          // listController.detach(position);
          // listController.attach(newPosition);
        }
        //每次翻页刷新电池电量
        electricQuantity = (await Battery().batteryLevel) / 100;
      }
    }
    load = Load.Done;
    notifyListeners();
  }

  loadNextChapter() async {
    load = Load.Loading;
    if (readPages.length - 2 > cursor) {
      print("已存在");
      cursor += 1;
      book.cur += 1;
      load = Load.Done;
      return;
    }
    //下一章
    int tempCur = book.cur + 1;
    if (tempCur >= chapters.length) {
      //到最后一页
      book.index = -1;
    } else {
      book.cur += 1;
      cursor += 1;

      // if (nextPage.chapterName == "-1") {
      //   BotToast.showCustomLoading(toastBuilder: (_) => LoadingDialog());
      //   curPage = await loadChapter(book.cur);
      //   BotToast.closeAllLoading();
      // }

      ReadPage temp = await loadChapter(book.cur + 1);
      if (book.cur == tempCur) {
        if (temp != null) {
          addReadPage(temp);
          allContent.addAll(chapterContent(temp));
        }
        //每次翻页刷新电池电量
        electricQuantity = (await Battery().batteryLevel) / 100;
      }
    }
    load = Load.Done;
    calcPercent();
    notifyListeners();
  }

  checkCur() {
    if (book.cur < 0) {
      book.cur = 0;
    }
    if (book.cur > chapters.length - 1) {
      book.cur = chapters.length - 1;
    }
  }

  Future initPageContent(int idx, bool jump) async {
    BotToast.showCustomLoading(
        toastBuilder: (_) => LoadingDialog(),
        clickClose: true,
        backgroundColor: Colors.transparent);

    try {
      await Future.wait([
        loadChapter(idx - 1).then((value) => {prePage = value}),
        loadChapter(idx).then((value) => {curPage = value}),
        loadChapter(idx + 1).then((value) => {nextPage = value}),
      ]);
      if (!isPage) {
        readPages = [];
        ladderH = [];
        cursor = 1;
        addReadPage(prePage);
        addReadPage(curPage);
        addReadPage(nextPage);
      }
      await fillAllContent(refresh: jump);

      if (!isPage && listController != null) {
        calcPercent();
      }
      if (jump) {
        eventBus.fire(ZEvent(isPage, 0.0));
      }
    } catch (e) {
      print(e);
    }

    BotToast.closeAllLoading();
  }

  colorModelSwitch() async {
    var model = Store.value<ColorModel>(context);
    var color = model.dark ? darkFont : Colors.black;
    if ((prePage?.textComposition ?? null) != null) {
      prePage.textComposition.style =
          prePage.textComposition.style.copyWith(color: color);
    }
    if ((curPage?.textComposition ?? null) != null) {
      curPage.textComposition.style =
          curPage.textComposition.style.copyWith(color: color);
    }
    if ((nextPage?.textComposition ?? null) != null) {
      nextPage.textComposition.style =
          nextPage.textComposition.style.copyWith(color: color);
    }

    fillAllContent();
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
    int preLen = prePage?.pageOffsets ?? 0;
    int curLen = curPage?.pageOffsets ?? 0;
    if ((idx + 1 - preLen) > (curLen)) {
      //下一章
      int tempCur = book.cur + 1;
      if (tempCur >= chapters.length) {
        //到最后一页
        book.index = -1;
      } else {
        book.cur += 1;
        prePage = curPage;
        if ((nextPage?.chapterName ?? "") == "-1") {
          BotToast.showCustomLoading(
              toastBuilder: (_) => LoadingDialog(),
              clickClose: true,
              backgroundColor: Colors.transparent);
          curPage = await loadChapter(book.cur);
          int preLen = prePage?.pageOffsets ?? 0;
          int curLen = curPage?.pageOffsets ?? 0;
          book.index = preLen + curLen - 1;
          BotToast.closeAllLoading();
        } else {
          curPage = nextPage;
        }
        nextPage = null;
        fillAllContent();
        pageController.jumpToPage(prePage?.pageOffsets ?? 0);
        ReadPage temp = await loadChapter(book.cur + 1);
        if (book.cur == tempCur) {
          nextPage = temp;
          fillAllContent();
        }
      }
    } else if (idx < preLen) {
      //上一章
      int tempCur = book.cur - 1;
      if (tempCur < 0) {
        return;
      } else {
        book.cur -= 1;
        nextPage = curPage;
        curPage = prePage;
        prePage = null;
        fillAllContent();
        var p = curPage?.pageOffsets ?? 0;
        pageController.jumpToPage(p > 0 ? p - 1 : 0);
        ReadPage temp = await loadChapter(book.cur - 1);
        if (tempCur == book.cur) {
          prePage = temp;
          fillAllContent();
          int ix = (prePage?.pageOffsets ?? 0) + idx;
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
      // r.height = Screen.height;
      r.chapterContent = "Fall In Love At First Sight ,Miss.Zhang";
      return r;
    } else if (idx == chapters.length) {
      r.chapterName = "-1";
      // r.height = Screen.height;
      r.chapterContent = "没有更多内容,等待作者更新";
      return r;
    }

    r.chapterName = chapters[idx].name;
    String id = chapters[idx].id;
    //本地内容是否存在
    if (chapters[idx].hasContent != 2) {
      // r.chapterContent = await compute(requestDataWithCompute, id);
      r.chapterContent = await getChapterContent(id, idx: idx);
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
      return r;
    }
    var model = Store.value<ColorModel>(context);

    //本地是否有分页的缓存
    if (isPage) {
      var k = '${book.Id}pages' + r.chapterName;
      if (SpUtil.haveKey(k)) {
        r.textComposition =
            TextComposition.parContent(r, model.dark ? darkFont : Colors.black);
        List<TextPage> list =
            SpUtil.getObjectList(k).map((e) => TextPage.fromJson(e)).toList();
        r.textComposition.pages = list;
        SpUtil.remove(k);
      } else {
        if ((r?.textComposition?.pages ?? null) != null) {
          r.textComposition = TextComposition.parContent(
              r, model.dark ? darkFont : Colors.black);
        } else {
          r.textComposition = TextComposition.parContent(
              r, model.dark ? darkFont : Colors.black,
              parse: true);
        }
      }
    } else {
      String k = '${book.Id}height' + r.chapterName;
      if (SpUtil.haveKey(k)) {
        r.height = SpUtil.getDouble(k);
        SpUtil.remove(k);
      } else {
        r.textComposition = TextComposition.parContent(
            r, model.dark ? darkFont : Colors.black,
            justRender: true, parse: true);
        //章节内容不满一页 按一页算
        r.height = (r.textComposition?.pages?.first?.height ?? 0) +
            ReadSetting.listPageBottom;
        r.height = r.height >= Screen.height ? r.height : Screen.height;
      }
    }
    return r;
  }

  modifyFont() async {
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
    await fillAllContent(refresh: true);
    initPageContent(book.cur, true);
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
        SpUtil.putObjectList('${book.Id}pages${prePage?.chapterName ?? ' '}',
            prePage?.textComposition?.pages ?? []);
        SpUtil.putObjectList('${book.Id}pages${curPage?.chapterName ?? ''}',
            curPage?.textComposition?.pages ?? []);
        SpUtil.putObjectList('${book.Id}pages${nextPage?.chapterName ?? ''}',
            nextPage?.textComposition?.pages ?? []);
      } else {
        double p1 = ladderH[cursor + 1] - listController.offset;
        p1 = (readPages[cursor - 1].height +
                readPages[cursor].height +
                readPages[cursor + 1].height) -
            p1;
        await DbHelper.instance
            .updBookProcess(book?.cur ?? 0, book?.index ?? 0, p1, book.Id);
        SpUtil.putDouble(
            '${book.Id}height${readPages[cursor - 1]?.chapterName ?? ''}',
            readPages[cursor - 1]?.height ?? 0.0);
        SpUtil.putDouble(
            '${book.Id}height${readPages[cursor]?.chapterName ?? ''}',
            readPages[cursor]?.height ?? 0.0);
        SpUtil.putDouble(
            '${book.Id}height${readPages[cursor + 1]?.chapterName ?? ''}',
            readPages[cursor + 1]?.height ?? 0.0);
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
    var hSpace = Screen.height / 4;
    var space = wid / 3;
    var curWid = details.globalPosition.dx;
    var curH = details.globalPosition.dy;

    if (isPage && (curWid > 0 && curWid < space)) {
      pageController.previousPage(
          duration: Duration(microseconds: 1), curve: Curves.ease);
    } else if ((curWid > space) &&
        (curWid < 2 * space) &&
        (curH < hSpace * 3)) {
      toggleShowMenu();
    } else if (isPage && (curWid > space * 2)) {
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

  Widget firstPage() {
    return Container(
      width: Screen.width,
      height: Screen.height,
      padding: const EdgeInsets.only(top: 100),
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
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                book?.Desc ?? '',
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



  List<Widget> chapterContent(ReadPage r) {
    List<Widget> contents = [];

    if (r.chapterName == "-1" || r.chapterName == "1") {
      contents.add(GestureDetector(
        child: r.chapterName == "1" ? firstPage() : NoMorePage(),
        behavior: HitTestBehavior.opaque,
        onTapDown: (TapDownDetails details) {
          tapPage(context, details);
        },
      ));
    } else {
      int sum = r.pageOffsets;
      for (int i = 0; i < sum; i++) {
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
                          SizedBox(height: 2),
                          pageHead(r, model),
                          r.textComposition.getPageWidget(i),
                          pageFoot(model, i, r)
                        ],
                        crossAxisAlignment: CrossAxisAlignment.start,
                      ),
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : Padding(
                      padding:
                          EdgeInsets.only(bottom: ReadSetting.listPageBottom),
                      child: r.textComposition.getPageWidget(),
                    ));
        }));
      }
    }

    return contents;
  }

  Widget pageFoot(var model, var i, var r) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
              color: model.dark ? darkFont : Colors.black54,
            ),
          ),
          Spacer(),
          Text(
            '第${i + 1}/${r.pageOffsets}页',
            style: TextStyle(
              fontSize: 12 / Screen.textScaleFactor,
              color: model.dark ? darkFont : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget pageMiddleContent(var content, var model, bool top) {
    return Expanded(
        child: Container(
            margin: const EdgeInsets.only(left: 17, right: 13),
            alignment: top ? Alignment.topLeft : Alignment.centerLeft,
            child: RichText(
              textAlign: TextAlign.justify,
              textScaleFactor: Screen.textScaleFactor,
              text: TextSpan(children: [
                TextSpan(
                  text: content,
                  style: TextStyle(
                      fontFamily:
                          SpUtil.getString("fontName", defValue: "Roboto"),
                      color: model.dark ? darkFont : Colors.black,
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
      padding: const EdgeInsets.only(left: 20),
      child: Text(
        r.chapterName,
        style: TextStyle(
          fontSize: 12 / Screen.textScaleFactor,
          color: model.dark ? darkFont : Colors.black54,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  clear() async {
    allContent = null;
    chapters = [];
    loadOk = false;
    book = null;
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
    BotToast.showCustomLoading(
        toastBuilder: (_) => LoadingDialog(),
        clickClose: true,
        backgroundColor: Colors.transparent);
    var content = await getChapterContent(chapter.id, idx: book.cur);
    BotToast.closeAllLoading();
    if (content.isNotEmpty) {
      var temp = [ChapterNode(content, chapter.id)];
      await DbHelper.instance.udpChapter(temp);
      chapters[book.cur].hasContent = 2;
      if (isPage) {
        curPage = await loadChapter(book.cur);
        await fillAllContent();
      } else {
        var temp = await loadChapter(book.cur);
        readPages.removeAt(cursor);
        ladderH.removeAt(cursor);
        readPages.insert(cursor, temp);

        ladderH.insert(cursor, ladderH[cursor - 1] + temp.height);
        allContent.removeAt(cursor);
        allContent.insertAll(cursor, chapterContent(temp));
        notifyListeners();
      }
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
      if (chapter.hasContent != 2) {
        // String content = await compute(requestDataWithCompute, id);
        String content = await getChapterContent(id);
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

  Future<String> getChapterContent(String id, {int idx}) async {
    var url = Common.bookContentUrl + '/$id';
    var responseBody = await HttpUtil().http().get(url);

    var data = responseBody.data['data'];
    var link = data['link'];
    if (chapters.isNotEmpty && idx != null) {
      chapters[idx].link = link;
    }
    var content = data['content'].toString();
    if (content.isNotEmpty &&
        !content.contains("DEMOONE") &&
        !content.contains("请重新刷新页面")) {
      return content;
    }
    try {
      content = await ParseHtml.content(link);
      var formData = FormData.fromMap({"id": id, "content": content});
      HttpUtil().http().patch(Common.bookContentUpload, data: formData);
    } catch (e) {
      content = "章节内容加载失败,请重试.......\n$link";
    }
    return content;
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
      print(e);
    }
    return content;
  }

  @override
  Future<void> dispose() async {
    super.dispose();
  }


  getEveyPoet() async {
    // if (!isPage) {
    //   var url = "https://v2.jinrishici.com/one.json";

    //   var future = await HttpUtil().http().get(url);
    //   poet = future.data['data']['content'];
    // }
  }

  Future<void> switchFlipType(FlipType flipType) async {
    switch (flipType) {
      case FlipType.LIST_VIEW:
        isPage = false;
        readPages = [];
        cursor = 1;
        ladderH = [];
        calcPercent();
        SpUtil.putBool("isPage", false);
        SpUtil.getKeys().forEach((v) => {
              if (v.contains("height") || v.contains("pages"))
                {SpUtil.remove(v)}
            });
        if (listController == null) {
          await initPageContent(book.cur, false);
          listController = ScrollController(
              initialScrollOffset: ladderH[cursor - 1],
              keepScrollOffset: false);
          notifyListeners();
        } else {
          await initPageContent(book.cur, true);
        }

        break;
      case FlipType.PAGE_VIEW_SMOOTH:
        isPage = true;
        SpUtil.putBool("isPage", true);
        SpUtil.getKeys().forEach((v) => {
              if (v.contains("height") || v.contains("pages"))
                {SpUtil.remove(v)}
            });
        initPageContent(book.cur, true);
        pageController = PageController(
            keepPage: false, initialPage: curPage?.pageOffsets ?? 0);
        notifyListeners();
        break;
      default:
        break;
    }
  }

  double getLadderHeight(int idx) {
    int len = readPages.length;
    if (idx < 0) {
      return readPages[len + idx].height;
    } else {
      return readPages[idx].height;
    }
  }

  void addReadPage(ReadPage r) {
    int len = ladderH.length;
    if (len == 0) {
      ladderH.add(r?.height ?? Screen.height / 2);
    } else {
      ladderH.add(ladderH[len - 1] + r.height);
    }
    readPages.add(r);
  }

  Color randomColor() {
    var rng = Random();

    return skins[rng.nextInt(skins.length)];
  }
}
