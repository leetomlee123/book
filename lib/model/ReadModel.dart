import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:battery_plus/battery_plus.dart';
import 'package:book/common/DbHelper.dart';
import 'package:book/common/Http.dart';
import 'package:book/common/LoadDialog.dart';
import 'package:book/common/ReadSetting.dart';
import 'package:book/common/Screen.dart';
import 'package:book/common/common.dart';
import 'package:book/common/parse_html.dart';
import 'package:book/common/text_composition.dart';
import 'package:book/entity/Book.dart';
import 'package:book/entity/ChapterNode.dart';
import 'package:book/entity/ReadPage.dart';
import 'package:book/entity/TextPage.dart';
import 'package:book/entity/chapter.pb.dart';
import 'package:book/view/newBook/NovelPagePainter.dart';
import 'package:book/view/newBook/ReaderPageManager.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:book/common/local_store.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

enum Load { Loading, Done }
enum FlipType { LIST_VIEW, PAGE_VIEW_SMOOTH }

class ReadModel with ChangeNotifier {
  Color darkFont = Color(0x7FFFFFFF);
  NovelPagePainter? mPainter;
  TextComposition? textComposition;
  Map<String, ui.Picture> widgets = {};
  Stack? stackContent;
  Paint bgPaint = Paint();
  ui.Image? bgUI;
  GlobalKey? canvasKey;
  TextPainter textPainter =
      TextPainter(textDirection: TextDirection.ltr, maxLines: 1);

  /// 翻页动画类型
  int currentAnimationMode = ReaderPageManager.TYPE_ANIMATION_COVER_TURN;

  Book? book;
  List<ChapterProto> chapters = [];

  var currentPageValue = 0.0;
  String poet = "";

  bool isDark() => SpUtil.getBool("dark");

  var electricQuantity = 1.0;

  //本书记录
  // BookTag bookTag;
  ReadPage? prePage;
  ReadPage? curPage;
  ReadPage? nextPage;

  double percent = 0;

  //缓存批量提交大小
  int batchNum = 100;
  bool refresh = true;

  //显示上层 设置
  bool showMenu = false;

  //背景色索引
  String bgPath =
      SpUtil.getString(Common.bgIdx, defValue: ReadSetting.bgImg.first);

//章节翻页标志
  bool loadOk = false;

  //页面宽高

  bool jump = true;

  //阅读方式
  // bool isPage = false;
  // bool isPage = SpUtil.getBool("isPage", defValue: true);

  //点击上下页方式
  bool leftClickNext = SpUtil.getBool("leftClickNext", defValue: false);

  //页面上下文

//是否修改font
  bool? sSave;
  Load? load;

  //获取本书记录
  getBookRecord() async {
    electricQuantity = (await Battery().batteryLevel) / 100;
    showMenu = false;
    loadOk = false;
    sSave = true;
    notifyListeners();
    if (bgUI == null) await changeBgUI();
    final b = book;
    if (b == null) return;
    chapters = await DbHelper.instance.getChapters(b.Id);

    if (chapters.isNotEmpty) {
      getChapters();

      await initPageContent(b.cur, false);

      if (b.index == -1) {
        b.index = (curPage?.pageOffsets ?? 1) - 1;
      }
      loadOk = true;

      notifyListeners();
    } else {
      int cur = 0;
      String userName = SpUtil.getString("username");
      if (userName.isNotEmpty) {
        var url = Common.process + '/$userName/${b.Id}';
        Response response = await HttpUtil.instance.dio.get(url);
        String data = response.data['data'];
        if (data.isNotEmpty) {
          cur = int.parse(data);
        }
      }
      b.cur = cur;
      await getChapters(init: true);
      getChapters();
      await initPageContent(b.cur, false);
      b.index = 0;
      loadOk = true;
      notifyListeners();
    }
  }

  Future initPageContent(int idx, bool jump) async {
    BotToast.showCustomLoading(
        toastBuilder: (_) => LoadingDialog(),
        clickClose: true,
        backgroundColor: isDark() ? Colors.black : Colors.white);

    try {
      // await Future.wait([
      curPage = await loadChapter(idx);

      loadChapter(idx + 1).then((value) => {nextPage = value});

      loadChapter(idx - 1).then((value) => {prePage = value});

      if (jump) {
        book?.index = 0;
        final ro = canvasKey?.currentContext?.findRenderObject();
        if (ro != null) {
          ro.markNeedsPaint();
        }
      }
      notifyListeners();
    } catch (e) {}

    BotToast.closeAllLoading();
  }

  colorModelSwitch() async {
    await changeBgUI();
    widgets.clear();

    final ro = canvasKey?.currentContext?.findRenderObject();
    if (ro != null) {
      ro.markNeedsPaint();
    }
  }

  switchBgColor(i) async {
    bgPath = i;
    SpUtil.putString(Common.bgIdx, i);
    await colorModelSwitch();
    notifyListeners();
  }

  Future<List<ChapterProto>?> reqChapters(var bid, var skip, bool init) async {
    var url;
    final b = book;
    if (init) {
      url =
          Common.chaptersUrl + '/$bid/0/${(b?.cur ?? 0) == 0 ? 15 : ((b?.cur ?? 0) + 1)}';
    } else {
      url = Common.chaptersUrl + '/$bid/$skip/1000000';
    }
    Response response = await HttpUtil.instance.dio.get(url);
    try {
      String data = response.data['data'];
      if (data.isEmpty) return null;

      var x = base64Decode(data);
      ChaptersProto cps = ChaptersProto.fromBuffer(x);
      return cps.chaptersProto.toList();
    } catch (e) {}
    return null;
  }

  Future getChapters({bool init = false}) async {
    final b = book;
    if (b == null) return;
    List<ChapterProto>? list =
        await reqChapters(b.Id, chapters.length, init);
    if (list == null) return;
    chapters.addAll(list);
    if (SpUtil.containsKey(b.Id)) {
      DbHelper.instance.addChapters(list, b.Id);
    }
    notifyListeners();
  }

  Future<ReadPage?> loadChapter(int idx) async {
    ReadPage r = ReadPage.kong();
    if (idx < 0) {
      r.chapterName = "1";
      // r.height = Screen.height;
      r.chapterContent = "Fall In Love At First Sight ,Miss.Zhang";
      return r;
    } else if (idx == chapters.length) {
      r.chapterName = "-1";
      // r.height = Screen.height;
      r.chapterContent = "没有更多内容,等待作者更新";
      return null;
    }
    var chapter = chapters[idx];
    r.chapterName = chapter.chapterName;
    String chapterId = chapter.chapterId;

    //本地内容是否存在
    try {
      r.chapterContent = await DbHelper.instance.getContent(chapterId);
    } catch (e) {
      r.chapterContent = "";
    }

    if (r.chapterContent.isEmpty) {
      r.chapterContent = await getChapterContent(chapterId, idx: idx);
      if (r.chapterContent.isNotEmpty) {
        var temp = [ChapterNode(r.chapterContent, chapterId)];
        await DbHelper.instance.udpChapter(temp);
        chapters[idx].hasContent = "2";
      } else {
        r.chapterContent = "章节数据不存在,可手动重载或联系管理员";
        return r;
      }
    }

    //本地是否有分页的缓存
    final b = book;
    var k = '${b?.Id ?? ''}pages' + r.chapterName;
    if (SpUtil.haveKey(k)) {
      final objs = SpUtil.getObjectList(k);
      List<TextPage> list =
          (objs ?? []).map((e) => TextPage.fromJson(e)).toList();
      r.pages = list;
      SpUtil.remove(k);
    } else {
      // Rust pagination runs in a background isolate; Dart fallback yields once.
      r.pages = await TextComposition.parseContentAsync(r);
    }

    return r;
  }

  /*
   * 页面配置修改
   */
  updPage() async {
    widgets.clear();
    var keys = SpUtil.getKeys();
    for (var key in keys) {
      if (key.contains("pages")) {
        SpUtil.remove(key);
      }
    }
    await initPageContent(book?.cur ?? 0, true);
    final ro = canvasKey?.currentContext?.findRenderObject();
    if (ro != null) {
      ro.markNeedsPaint();
    }
  }

  /*菜单控制 */
  toggleShowMenu() {
    showMenu = !showMenu;
    notifyListeners();
  }

  /*状态保存 */
  saveData() async {
    if (sSave == true) {
      final b = book;
      if (b == null) return;
      if (!SpUtil.containsKey(b.Id)) {
        SpUtil.putString(b.Id, "");
        DbHelper.instance.addChapters(chapters, b.Id);
      }
      SpUtil.putObjectList('${b.Id}pages${prePage?.chapterName ?? ' '}',
          prePage?.pages ?? []);
      SpUtil.putObjectList(
          '${b.Id}pages${curPage?.chapterName ?? ''}', curPage?.pages ?? []);
      SpUtil.putObjectList('${b.Id}pages${nextPage?.chapterName ?? ''}',
          nextPage?.pages ?? []);
      String userName = SpUtil.getString("username");
      if (userName.isNotEmpty) {
        HttpUtil.instance.dio
            .patch(Common.process + '/$userName/${b.Id}/${b.cur}');
      }
    }
  }

  /*页面点击事件 */
  void tapPage(BuildContext context, TapUpDetails details) {
    var wid = MediaQuery.of(context).size.width;
    var hSpace = Screen.height / 4;
    var space = wid / 3;
    var curWid = details.globalPosition.dx;
    var curH = details.globalPosition.dy;
    var location = details.localPosition;
    if ((curWid > space) && (curWid < 2 * space) && (curH < hSpace * 3)) {
      toggleShowMenu();
    } else if ((curWid > space * 2)) {
      if (leftClickNext) {
        clickPage(1, location);
        return;
      }
      clickPage(1, location);
    } else if ((curWid > 0 && curWid < space)) {
      if (leftClickNext) {
        clickPage(1, location);
        return;
      }
      clickPage(-1, location);
    }
  }

  void clickPage(int f, Offset detail) {
    TouchEvent currentTouchEvent = TouchEvent(TouchEvent.ACTION_DOWN, detail);

    mPainter?.setCurrentTouchEvent(currentTouchEvent);

    var offset = Offset(
        f > 0
            ? (detail.dx - Screen.width / 15 - 5)
            : (detail.dx + Screen.width / 15 + 5),
        0);
    currentTouchEvent = TouchEvent(TouchEvent.ACTION_MOVE, offset);

    mPainter?.setCurrentTouchEvent(currentTouchEvent);

    currentTouchEvent = TouchEvent(TouchEvent.ACTION_CANCEL, offset);

    mPainter?.setCurrentTouchEvent(currentTouchEvent);
    final ro = canvasKey?.currentContext?.findRenderObject();
    if (ro != null) {
      ro.markNeedsPaint();
    }
  }

  ui.Picture? getPage({bool firstInit = false}) {
    final b = book;
    if (b == null) return null;
    var key = b.Id.toString() + b.cur.toString() + b.index.toString();

    if (widgets.containsKey(key)) {
      return widgets[key];
    }
    var widget = cur();
    if (widget != null) {
      widgets.putIfAbsent(key, () => widget);
    }
    if (firstInit) {
      Future.delayed(Duration(milliseconds: 200), () => preLoadWidget());
    }
    return widget;
  }

  void preLoadWidget() {
    final b = book;
    if (prePage == null || b == null) return;
    var preIdx = b.index - 1;
    late String preKey;
    if (preIdx < 0) {
      preKey = b.Id.toString() +
          (b.cur - 1).toString() +
          (prePage!.pageOffsets - 1).toString();
    } else {
      preKey = b.Id.toString() + b.cur.toString() + preIdx.toString();
    }
    if (!widgets.containsKey(preKey)) {
      if (prePage?.pages == null) return;
      final p = pre();
      if (p != null) {
        widgets.putIfAbsent(preKey, () => p);
      }
    }

    var nextIdx = b.index + 1;
    late String nextKey;
    if (nextIdx >= (curPage?.pageOffsets ?? 0)) {
      nextKey = b.Id.toString() + (b.cur + 1).toString() + 0.toString();
    } else {
      nextKey = b.Id.toString() + b.cur.toString() + nextIdx.toString();
    }
    if (!widgets.containsKey(nextKey)) {
      if (nextPage?.pages == null) return;
      final n = next();
      if (n != null) {
        widgets.putIfAbsent(preKey, () => n);
      }
    }
  }

  ui.Picture? pre() {
    final b = book;
    if (prePage == null || b == null) return null;
    var i = b.index - 1;
    var key = b.Id.toString() + b.cur.toString() + i.toString();

    if (widgets.containsKey(key)) {
      return widgets[key];
    } else {
      final pic = i < 0
          ? drawContent(prePage!, prePage!.pageOffsets - 1)
          : drawContent(curPage!, i);
      return widgets.putIfAbsent(key, () => pic);
    }
  }

  ui.Picture? cur() {
    final b = book;
    if (b == null || curPage == null) return null;
    var key = b.Id.toString() + b.cur.toString() + b.index.toString();

    if (widgets.containsKey(key)) {
      return widgets[key];
    } else {
      Future.delayed(Duration(milliseconds: 200), () => preLoadWidget());
      final pic = drawContent(curPage!, b.index);
      return widgets.putIfAbsent(key, () => pic);
    }
  }

  ui.Picture? next() {
    final b = book;
    if (b == null || curPage == null) return null;
    var i = b.index + 1;

    var key = b.Id.toString() + b.cur.toString() + i.toString();

    if (widgets.containsKey(key)) {
      return widgets[key];
    } else {
      if (nextPage == null) {
        loadChapter(b.cur + 1).then((value) => {nextPage = value});
      }
      final pic = i >= curPage!.pageOffsets
          ? drawContent(nextPage!, 0)
          : drawContent(curPage!, i);
      return widgets.putIfAbsent(key, () => pic);
    }
  }

  Future<ui.Image> getAssetImage(String asset, {int? width, int? height}) async {
    ByteData data = await rootBundle.load(asset);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width, targetHeight: height);
    ui.FrameInfo fi = await codec.getNextFrame();
    return fi.image;
  }

  ui.Picture drawContent(ReadPage readPage, int i) {
    ui.PictureRecorder pageRecorder = ui.PictureRecorder();

    final bool isDark = SpUtil.getBool("dark", defValue: false);
    var contentPadding = ReadSetting.getPageDis().toDouble();
    Canvas pageCanvas = Canvas(
        pageRecorder, Rect.fromLTWH(0, 0, Screen.width, Screen.height));
    Paint selfPaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.butt
      ..strokeWidth = 30.0;
    final bg = bgUI;
    if (bg != null) {
      pageCanvas.drawImage(bg, Offset(0, 0), selfPaint);
    }

    //章节
    textPainter.text = TextSpan(
        text: "${readPage.chapterName}",
        style: TextStyle(
          fontSize: 12 / Screen.textScaleFactor,
          color: isDark ? darkFont : Colors.black54,
          fontFamily: SpUtil.getString("fontName", defValue: "Roboto"),
        ));
    textPainter.layout();
    //章节高30 画在中间
    textPainter.paint(pageCanvas,
        Offset(contentPadding, 15 + SpUtil.getDouble(Common.top_safe_height)));
    //正文
    TextStyle style = TextStyle(
        color: SpUtil.getBool('dark') ? darkFont : Colors.black,
        locale: Locale('zh_CN'),
        fontFamily: SpUtil.getString("fontName", defValue: "Roboto"),
        fontSize: ReadSetting.getFontSize(),
        // letterSpacing: ReadSetting.getLatterSpace(),
        height: ReadSetting.getLineHeight());

    final TextPage page = readPage.pages[i];
    final lineCount = page.lines.length;
    for (var i = 0; i < lineCount; i++) {
      final line = page.lines[i];
      final ls = line.letterSpacing;
      if (ls != null && (ls < -0.1 || ls > 0.1)) {
        textPainter.text = TextSpan(
          text: line.text,
          style: style.copyWith(letterSpacing: ls),
        );
      } else {
        textPainter.text = TextSpan(text: line.text, style: style);
      }
      final offset = Offset(
          line.dx, line.dy + 45 + SpUtil.getDouble(Common.top_safe_height));
      textPainter.layout();
      textPainter.paint(pageCanvas, offset);
    }
    //画电池
    double batteryPaddingLeft = contentPadding - 5;
    double mStrokeWidth = 1.0;
    double mPaintStrokeWidth = 1.5;
    Paint mPaint = Paint()..strokeWidth = mPaintStrokeWidth;
    var bottomH = Screen.height - 25 - Screen.bottomSafeHeight;
    var bottomTextH = bottomH - 2;
    //电池头部位置
    Size size = Size(22, 10);
    double batteryHeadLeft = 0;
    double batteryHeadTop = size.height / 4 + bottomH;
    double batteryHeadRight = size.width / 15;
    double batteryHeadBottom = batteryHeadTop + (size.height / 2);

    //电池框位置
    double batteryLeft = batteryHeadRight + mStrokeWidth;
    double batteryTop = bottomH;
    double batteryRight = size.width;
    double batteryBottom = size.height + bottomH;

    //电量位置
    double electricQuantityTotalWidth =
        size.width - batteryHeadRight - 5 * mStrokeWidth; //电池减去边框减去头部剩下的宽度
    double electricQuantityLeft = batteryHeadRight +
        2 * mStrokeWidth +
        electricQuantityTotalWidth * (1 - electricQuantity);
    double electricQuantityTop = mStrokeWidth * 2 + bottomH;
    double electricQuantityRight = size.width - 2 * mStrokeWidth;
    double electricQuantityBottom = size.height - 2 * mStrokeWidth + bottomH;

    mPaint.style = PaintingStyle.fill;
    mPaint.color = isDark ? darkFont : Colors.black54;
    // mPaint.color = Color(0x80ffffff);
    //画电池头部
    pageCanvas.drawRRect(
        RRect.fromLTRBR(
            batteryHeadLeft + batteryPaddingLeft,
            batteryHeadTop,
            batteryHeadRight + batteryPaddingLeft,
            batteryHeadBottom,
            Radius.circular(mStrokeWidth)),
        mPaint);
    mPaint.style = PaintingStyle.stroke;
    //画电池框
    pageCanvas.drawRRect(
        RRect.fromLTRBR(
            batteryLeft + batteryPaddingLeft,
            batteryTop,
            batteryRight + batteryPaddingLeft,
            batteryBottom,
            Radius.circular(mStrokeWidth)),
        mPaint);
    mPaint.style = PaintingStyle.fill;
    mPaint.color = isDark ? darkFont : Colors.black38;
    //画电池电量
    pageCanvas.drawRRect(
        RRect.fromLTRBR(
            electricQuantityLeft + batteryPaddingLeft + .5,
            electricQuantityTop,
            electricQuantityRight + batteryPaddingLeft + .5,
            electricQuantityBottom,
            Radius.circular(mStrokeWidth)),
        mPaint);
    //时间
    textPainter.text = TextSpan(
      text: '${DateUtil.formatDate(DateTime.now(), format: DateFormats.h_m)}',
      style: TextStyle(
        fontFamily: SpUtil.getString("fontName", defValue: "Roboto"),
        fontSize: 12 / Screen.textScaleFactor,
        color: SpUtil.getBool('dark') ? darkFont : Colors.black54,
      ),
    );
    textPainter.layout();
    textPainter.paint(
        pageCanvas, Offset(contentPadding + size.width + 1, bottomTextH));
    //页码
    textPainter.text = TextSpan(
        text: "第${i + 1}/${readPage.pages.length}页",
        style: TextStyle(
          fontSize: 12 / Screen.textScaleFactor,
          fontFamily: SpUtil.getString("fontName", defValue: "Roboto"),
          color: isDark ? darkFont : Colors.black54,
        ));
    textPainter.layout();
    textPainter.paint(
        pageCanvas, Offset(Screen.width - contentPadding - 40, bottomTextH));
    return pageRecorder.endRecording();
  }

  clear() async {
    chapters = [];
    loadOk = false;
    book = null;
    curPage = null;
    prePage = null;
    nextPage = null;
  }

  Future<void> reloadChapters() async {
    final b = book;
    if (b == null) return;
    chapters = [];
    DbHelper.instance.clearChapters(b.Id);

    chapters = await reqChapters(b.Id, 0, false) ?? [];
    if (chapters.isEmpty) return;

    DbHelper.instance.addChapters(chapters, b.Id);
    notifyListeners();
  }

  Future<void> reloadCurrentPage() async {
    final b = book;
    if (b == null) return;
    toggleShowMenu();
    var chapter = chapters[b.cur];
    BotToast.showCustomLoading(
        toastBuilder: (_) => LoadingDialog(),
        clickClose: true,
        backgroundColor: Colors.white);
    var id = chapters[b.cur].chapterId;
    var url = Common.bookContentUrl + '/$id';
    var responseBody = await HttpUtil.instance.dio.get(url);

    var data = responseBody.data['data'];
    var link = data['link'];

    var content = "";
    try {
      content = await ParseHtml().content(link);
      var formData = FormData.fromMap({"id": id, "content": content});
      HttpUtil.instance.dio.patch(Common.bookContentUpload, data: formData);
    } catch (e) {
      content = "章节内容加载失败,请重试.......\n$link";
    }

    BotToast.closeAllLoading();
    if (content.isNotEmpty) {
      var temp = [ChapterNode(content, chapter.chapterId)];
      await DbHelper.instance.udpChapter(temp);
      chapters[b.cur].hasContent = "2";

      curPage = await loadChapter(b.cur);
      notifyListeners();
      final ro = canvasKey?.currentContext?.findRenderObject();
      if (ro != null) {
        ro.markNeedsPaint();
      }
    }
  }

  reSetPages() {
    prePage = null;
    curPage = null;
    nextPage = null;
  }

  downloadAll(int start) async {
    List<ChapterProto> temp = chapters;
    if (temp.isEmpty) {
      await getChapters();
      temp = chapters;
    }
    List<ChapterNode> cpNodes = [];
    for (var i = start; i < temp.length; i++) {
      ChapterProto chapter = temp[i];
      var id = chapter.chapterId;
      if (chapter.hasContent != "2") {
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

  Future<String> getChapterContent(String id, {int? idx}) async {
    var url = Common.bookContentUrl + '/$id';
    var responseBody = await HttpUtil.instance.dio.get(url);

    var data = responseBody.data['data'];
    var link = data['link'];

    var content = data['content'].toString();
    if (content.isNotEmpty &&
        !content.contains("DEMOONE") &&
        !content.contains("请重新刷新页面")) {
      return content;
    }
    try {
      content = await ParseHtml().content(link);
      var formData = FormData.fromMap({"id": id, "content": content});
      HttpUtil.instance.dio.patch(Common.bookContentUpload, data: formData);
    } catch (e) {
      content = "章节内容加载失败,请重试.......\n$link";
    }
    return content;
  }

  switchClickNextPage() {
    leftClickNext = !leftClickNext;
    SpUtil.putBool("leftClickNext", leftClickNext);
    notifyListeners();
  }

  void changeCoverPage(var offsetDifference) {
    final b = book;
    if (b == null) return;
    int idx = b.index;

    int curLen = (curPage?.pageOffsets ?? 0);
    if (idx == curLen - 1 && offsetDifference > 0) {
      Future.delayed(
          Duration(milliseconds: 500),
          () => {
                Battery()
                    .batteryLevel
                    .then((value) => electricQuantity = value / 100)
              });
      int tempCur = b.cur + 1;
      if (tempCur >= chapters.length) {
        //到最后一页
        // book.index = -1;
        BotToast.showText(text: "最后一页");
        return;
      } else {
        b.cur += 1;
        prePage = curPage;
        if ((nextPage?.chapterName ?? "") == "-1") {
          BotToast.showCustomLoading(
              toastBuilder: (_) => LoadingDialog(),
              clickClose: true,
              backgroundColor: Colors.white);

          loadChapter(b.cur).then((value) => curPage = value);

          BotToast.closeAllLoading();
        } else {
          curPage = nextPage;
        }
        b.index = 0;
        nextPage = null;
        // notifyListeners();
        Future.delayed(Duration(milliseconds: 500), () {
          loadChapter(b.cur + 1).then((value) => nextPage = value);
        });

        return;
      }
    }
    if (idx == 0 && offsetDifference < 0) {
      Future.delayed(
          Duration(milliseconds: 500),
          () => {
                Battery()
                    .batteryLevel
                    .then((value) => electricQuantity = value / 100)
              });
      int tempCur = b.cur - 1;
      if (tempCur < 0) {
        BotToast.showText(text: "第一页");

        return;
      }
      nextPage = curPage;
      curPage = prePage;
      b.cur -= 1;

      b.index = (curPage?.pageOffsets ?? 1) - 1;
      notifyListeners();
      prePage = null;
      Future.delayed(Duration(milliseconds: 500), () {
        loadChapter(b.cur - 1).then((value) => prePage = value);
      });

      return;
    }
    offsetDifference > 0 ? b.index += 1 : b.index -= 1;
    // notifyListeners();
  }

  bool isCanGoNext() {
    final b = book;
    if (b == null) return false;
    print(b.index);
    if (b.cur >= (chapters.length - 1)) {
      if (b.index >= ((curPage?.pageOffsets ?? 1) - 1)) {
        return false;
      }
    }

    return next() != null;
  }

  bool isCanGoPre() {
    final b = book;
    if (b == null) return false;
    if (b.cur <= 0 && b.index <= 0) {
      return false;
    }
    return pre() != null;
  }

  changeBgUI() async {
    if (SpUtil.getBool("dark")) {
      bgUI = await getAssetImage("images/${ReadSetting.bgImg.last}",
          width: Screen.width.ceil(), height: Screen.height.ceil());
    } else {
      bgUI = await getAssetImage("images/$bgPath",
          width: Screen.width.ceil(), height: Screen.height.ceil());
    }
  }
}
