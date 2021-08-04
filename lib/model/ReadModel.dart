import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

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
import 'package:book/entity/ChapterNode.dart';
import 'package:book/entity/ReadPage.dart';
import 'package:book/entity/TextPage.dart';
import 'package:book/entity/chapter.pb.dart';
import 'package:book/event/event.dart';
import 'package:book/view/newBook/ReaderPageManager.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

enum Load { Loading, Done }
enum FlipType { LIST_VIEW, PAGE_VIEW_SMOOTH }

class ReadModel with ChangeNotifier {
  Color darkFont = Color(0x9FFFFFFF);
  TextComposition textComposition;
  Map<String, ui.Picture> widgets = Map();
  Stack stackContent;
  Paint bgPaint = Paint();
  ui.Image bgUI;

  TextPainter textPainter =
      TextPainter(textDirection: TextDirection.ltr, maxLines: 1);

  /// 翻页动画类型
  int currentAnimationMode = ReaderPageManager.TYPE_ANIMATION_COVER_TURN;

  Book book;
  List<ChapterProto> chapters = [];

  var currentPageValue = 0.0;
  String poet = "";

  var electricQuantity = 1.0;

  //本书记录
  // BookTag bookTag;
  ReadPage prePage;
  ReadPage curPage;
  ReadPage nextPage;

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
  bool sSave;
  Load load;

  //获取本书记录
  getBookRecord() async {
    electricQuantity = (await Battery().batteryLevel) / 100;
    showMenu = false;
    loadOk = false;
    sSave = true;
    widgets.clear();
    notifyListeners();
    if (bgUI == null) await changeBgUI();
    chapters = await DbHelper.instance.getChapters(book.Id);

    if (chapters?.isNotEmpty ?? false) {
      getChapters();

      await initPageContent(book.cur, false);

      if (book.index == -1) {
        book.index = curPage.pageOffsets - 1;
      }
      loadOk = true;

      notifyListeners();
    } else {
      int cur = 0;
      String userName = SpUtil.getString("username");
      if (userName.isNotEmpty) {
        var url = Common.process + '/$userName/${book.Id}';
        Response response = await HttpUtil.instance.dio.get(url);
        String data = response.data['data'];
        if (data.isNotEmpty) {
          cur = int.parse(data);
        }
      }
      book.cur = cur;
      await getChapters(init: true);
      getChapters();
      await initPageContent(book?.cur ?? 0, false);
      book.index = 0;
      loadOk = true;
      notifyListeners();
    }
  }

  Future initPageContent(int idx, bool jump) async {
    BotToast.showCustomLoading(
        toastBuilder: (_) => LoadingDialog(),
        clickClose: true,
        backgroundColor: Colors.transparent);

    try {
      // await Future.wait([
      curPage = await loadChapter(idx);

      loadChapter(idx + 1).then((value) => {nextPage = value});

      loadChapter(idx - 1).then((value) => {prePage = value});

      if (jump) {
        book.index = 0;
        eventBus.fire(ZEvent(1));
      }
      notifyListeners();
    } catch (e) {
      print(e);
    }

    BotToast.closeAllLoading();
  }

  colorModelSwitch() async {
    await changeBgUI();
    widgets.clear();
    eventBus.fire(ZEvent(1));
  }

  switchBgColor(i) async {
    bgPath = i;
    SpUtil.putString(Common.bgIdx, i);
    await colorModelSwitch();
    notifyListeners();
  }

  Future<List<ChapterProto>> reqChapters(var bid, var skip, bool init) async {
    var url;
    if (init) {
      url =
          Common.chaptersUrl + '/$bid/0/${book.cur == 0 ? 15 : (book.cur + 1)}';
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
    List<ChapterProto> list =
        await reqChapters(book.Id, chapters?.length ?? 0, init);
    if (list == null) return;
    chapters.addAll(list);
    //书的最后一章
    if (book.CId == "-1") {
      book.cur = chapters.length - 1;
    }
    if (SpUtil.containsKey(book.Id)) {
      DbHelper.instance.addChapters(list, book.Id);
    }
    notifyListeners();
  }

  Future<ReadPage> loadChapter(int idx) async {
    ReadPage r = new ReadPage.kong();
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
    var chapter = chapters[idx];
    r.chapterName = chapter.chapterName;
    String chapterId = chapter.chapterId;

    //本地内容是否存在
    r.chapterContent = await DbHelper.instance.getContent(chapterId);

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
    var k = '${book.Id}pages' + r.chapterName;
    if (SpUtil.haveKey(k)) {
      List<TextPage> list =
          SpUtil.getObjectList(k).map((e) => TextPage.fromJson(e)).toList();
      r.pages = list;
      SpUtil.remove(k);
    } else {
      r.pages = TextComposition.parseContent(r);
      //   ReceivePort receivePort = ReceivePort();
      //   //创建并生成与当前Isolate共享相同代码的Isolate
      //   var _isolate = await FlutterIsolate.spawn(
      //       TextComposition.dataLoader, receivePort.sendPort);
      //   // 流的第一个元素
      //   SendPort sendPort = await receivePort.first;
      //   // 流的第一个元素被收到后监听会关闭，所以需要新打开一个ReceivePort以接收传入的消息

      //   ReceivePort response = ReceivePort();

      //   double w = Screen.width;
      //   double h = Screen.height - 62 - Screen.bottomSafeHeight;
      //   String fontFamily = SpUtil.getString("fontName", defValue: "Roboto");
      //   double fontSize = ReadSetting.getFontSize();
      //   double height = ReadSetting.getLineHeight();

      //   double dis = ReadSetting.getPageDis().toDouble();
      //   double paragraph = ReadSetting.getParagraph() *
      //       ReadSetting.getFontSize() *
      //       ReadSetting.getLineHeight();
      //   sendPort.send([
      //     response.sendPort,
      //     jsonEncode(r),
      //     w,
      //     h,
      //     fontFamily,
      //     fontSize,
      //     height,
      //     dis,
      //     paragraph
      //   ]);

      //   await for (var msg in response) {
      //     // 获取端口发送来的数据③
      //     String jsonResult = msg[0];

      //     _isolate?.kill();
      //     List result = jsonDecode(jsonResult);
      //     r.pages = result.map((e) => TextPage.fromJson(e)).toList();
      //     break;
      //   }
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
    await initPageContent(book.cur, true);
    eventBus.fire(ZEvent(2));
  }

  /*菜单控制 */
  toggleShowMenu() {
    showMenu = !showMenu;
    notifyListeners();
  }

  /*状态保存 */
  saveData() async {
    if (sSave) {
      if (!SpUtil.containsKey(book.Id)) {
        SpUtil.putString(book.Id, "");
        DbHelper.instance.addChapters(chapters, book.Id);
      }
      SpUtil.putObjectList('${book.Id}pages${prePage?.chapterName ?? ' '}',
          prePage?.pages ?? []);
      SpUtil.putObjectList(
          '${book.Id}pages${curPage?.chapterName ?? ''}', curPage?.pages ?? []);
      SpUtil.putObjectList('${book.Id}pages${nextPage?.chapterName ?? ''}',
          nextPage?.pages ?? []);
      String userName = SpUtil.getString("username");
      if (userName.isNotEmpty) {
        HttpUtil.instance.dio
            .patch(Common.process + '/$userName/${book.Id}/${book?.cur ?? 0}');
      }
    }
  }

  /*页面点击事件 */
  void tapPage(BuildContext context, TapDownDetails details) {
    var wid = ScreenUtil.getScreenW(context);
    var hSpace = Screen.height / 4;
    var space = wid / 3;
    var curWid = details.globalPosition.dx;
    var curH = details.globalPosition.dy;

    if ((curWid > 0 && curWid < space)) {
      if (leftClickNext) {
        changeCoverPage(1);
        return;
      }
      changeCoverPage(-1);
    } else if ((curWid > space) &&
        (curWid < 2 * space) &&
        (curH < hSpace * 3)) {
      toggleShowMenu();
    } else if ((curWid > space * 2)) {
      if (leftClickNext) {
        changeCoverPage(1);
        return;
      }
      changeCoverPage(1);
    }
  }

  ui.Picture getPage({bool firstInit = false}) {
    var key = book.cur.toString() + book.index.toString();

    if (widgets.containsKey(key)) {
      return widgets[key];
    }
    var widget = cur();
    widgets.putIfAbsent(key, () => widget);
    if (firstInit) {
      Future.delayed(Duration(milliseconds: 200), () => preLoadWidget());
    }
    return widget;
  }

  void preLoadWidget() {
    if (prePage == null) return;
    var preIdx = book.index - 1;
    var preKey;
    if (preIdx < 0) {
      preKey = (book.cur - 1).toString() + (prePage.pageOffsets - 1).toString();
    } else {
      preKey = book.cur.toString() + preIdx.toString();
    }
    if (!widgets.containsKey(preKey)) {
      if (prePage?.pages == null) return;
      widgets.putIfAbsent(preKey, () => pre());
    }

    var nextIdx = book.index + 1;
    var nextKey;
    if (nextIdx >= curPage.pageOffsets) {
      nextKey = (book.cur + 1).toString() + 0.toString();
    } else {
      nextKey = book.cur.toString() + nextIdx.toString();
    }
    if (!widgets.containsKey(nextKey)) {
      if (nextPage?.pages == null) return;
      widgets.putIfAbsent(preKey, () => next());
    }
  }

  ui.Picture pre() {
    if (prePage == null) return null;

    var i = book.index - 1;
    if (i < 0) {
      return drawContent(prePage, prePage.pageOffsets - 1);
    }
    return drawContent(curPage, i);
  }

  ui.Picture cur() {
    return drawContent(curPage, book.index);
  }

  ui.Picture next() {
    var i = book.index + 1;
    if (i >= curPage.pageOffsets) {
      return drawContent(nextPage, 0);
    }
    return drawContent(curPage, i);
  }

  Future<ui.Image> getAssetImage(String asset, {int width, int height}) async {
    ByteData data = await rootBundle.load(asset);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width, targetHeight: height);
    ui.FrameInfo fi = await codec.getNextFrame();
    return fi.image;
  }

  ui.Picture drawContent(ReadPage readPage, int i) {
    ui.PictureRecorder pageRecorder = new ui.PictureRecorder();
    Canvas pageCanvas = new Canvas(
        pageRecorder, Rect.fromLTWH(0, 0, Screen.width, Screen.height));
    final bool isDark = SpUtil.getBool("dark", defValue: false);
    var contentPadding = ReadSetting.getPageDis().toDouble();
    Paint selfPaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.butt
      ..strokeWidth = 30.0;
    pageCanvas.drawImage(bgUI, Offset(0, 0), selfPaint);
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
    textPainter.paint(pageCanvas, Offset(contentPadding, 15));
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
      if (line.letterSpacing != null &&
          (line.letterSpacing < -0.1 || line.letterSpacing > 0.1)) {
        textPainter.text = TextSpan(
          text: line.text,
          style: style.copyWith(letterSpacing: line?.letterSpacing),
        );
      } else {
        textPainter.text = TextSpan(text: line.text, style: style);
      }
      final offset = Offset(line.dx, line.dy + 30);
      textPainter.layout();
      textPainter.paint(pageCanvas, offset);
    }
    //画电池
    double batteryPaddingLeft = contentPadding - 5;
    double mStrokeWidth = 1.0;
    double mPaintStrokeWidth = 1.5;
    Paint mPaint = Paint()..strokeWidth = mPaintStrokeWidth;
    var bottomH = Screen.height - 25;
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
    mPaint.color = isDark ? Colors.white54 : Colors.black54;
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
    mPaint.color = isDark ? Colors.white38 : Colors.black38;
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
        pageCanvas, Offset(Screen.width - contentPadding - 35, bottomTextH));
    return pageRecorder.endRecording();
  }

  clear() async {
    chapters = [];
    loadOk = false;
    book = null;
    widgets.clear();
    curPage = null;
    prePage = null;
    nextPage = null;
  }

  Future<void> reloadChapters() async {
    chapters = [];
    DbHelper.instance.clearChapters(book.Id);

    chapters = await reqChapters(book.Id, 0, false);
    if (chapters == null) return;

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
    var content = await getChapterContent(chapter.chapterId, idx: book.cur);
    BotToast.closeAllLoading();
    if (content.isNotEmpty) {
      var temp = [ChapterNode(content, chapter.chapterId)];
      await DbHelper.instance.udpChapter(temp);
      chapters[book.cur].hasContent = "2";

      curPage = await loadChapter(book.cur);
      notifyListeners();
      widgets.clear();
      eventBus.fire(ZEvent(1));
      // await fillAllContent();
    }
  }

  reSetPages() {
    prePage = null;
    curPage = null;
    nextPage = null;
  }

  downloadAll(int start) async {
    List<ChapterProto> temp = chapters;
    if (temp?.isEmpty ?? 0 == 0) {
      await getChapters();
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

  Future<String> getChapterContent(String id, {int idx}) async {
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

    //   var future = await HttpUtil.instance.dio.get(url);
    //   poet = future.data['data']['content'];
    // }
  }

  switchClickNextPage() {
    leftClickNext = !leftClickNext;
    SpUtil.putBool("leftClickNext", leftClickNext);
    notifyListeners();
  }

  Future<void> changeCoverPage(var offsetDifference) async {
    int idx = book?.index ?? 0;
    // if (idx == -1) {
    //   return;
    // }
    int curLen = (curPage?.pageOffsets ?? 0);
    if (idx == curLen - 1 && offsetDifference > 0) {
      electricQuantity = (await Battery().batteryLevel) / 100;
      int tempCur = book.cur + 1;
      if (tempCur >= chapters.length) {
        //到最后一页
        // book.index = -1;
        BotToast.showText(text: "最后一页");
        return;
      } else {
        book.cur += 1;
        prePage = curPage;
        if ((nextPage?.chapterName ?? "") == "-1") {
          BotToast.showCustomLoading(
              toastBuilder: (_) => LoadingDialog(),
              clickClose: true,
              backgroundColor: Colors.transparent);
          curPage = await loadChapter(book.cur);

          BotToast.closeAllLoading();
        } else {
          curPage = nextPage;
        }
        book.index = 0;
        notifyListeners();
        Future.delayed(Duration(milliseconds: 500), () {
          loadChapter(book.cur + 1).then((value) => nextPage = value);
        });

        return;
      }
    }
    if (idx == 0 && offsetDifference < 0) {
      electricQuantity = (await Battery().batteryLevel) / 100;
      int tempCur = book.cur - 1;
      if (tempCur < 0) {
        BotToast.showText(text: "第一页");

        return;
      }
      nextPage = curPage;
      curPage = prePage;
      book.cur -= 1;

      book.index = curPage.pageOffsets - 1;
      notifyListeners();
      Future.delayed(Duration(milliseconds: 500), () {
        loadChapter(book.cur - 1).then((value) => prePage = value);
      });

      return;
    }
    offsetDifference > 0 ? book.index += 1 : book.index -= 1;
    notifyListeners();
  }

  bool isCanGoNext() {
    if (book.cur >= (chapters.length - 1) &&
        book.index >= (curPage.pageOffsets - 1)) return false;
    return true;
  }

  bool isCanGoPre() {
    if (book.cur <= 0 && book.index <= 0) return false;
    return true;
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
