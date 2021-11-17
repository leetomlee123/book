import 'package:book/entity/Book.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/ReadModel.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/book/ChapterView.dart';
import 'package:book/view/book/Menu.dart';
import 'package:book/view/book/PageContentRender.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_statusbar_manager/flutter_statusbar_manager.dart';
// import 'package:flutter_statusbar_manager/flutter_statusbar_manager.dart';

class ReadBook extends StatefulWidget {
  final Book book;
  final bool reading;

  ReadBook(this.book, {this.reading = false});

  @override
  State<StatefulWidget> createState() {
    return _ReadBookState();
  }
}

class _ReadBookState extends State<ReadBook> with WidgetsBindingObserver {
  Widget body;
  ReadModel readModel;
  ShelfModel shelfModel;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  ColorModel colorModel;

  @override
  void initState() {
    setUp();
    super.initState();
  }

  setUp() async {
    readModel = Store.value<ReadModel>(context);
    shelfModel = Store.value<ShelfModel>(context);
    eventBus.on<ReadRefresh>().listen((event) {
      readModel.reSetPages();
      readModel.initPageContent(readModel.book.cur, true);
    });

    WidgetsBinding.instance.addObserver(this);
    // eventBus.on<ZEvent>().listen((event) {
    //   move(event.off);
    // });
    eventBus.on<OpenChapters>().listen((event) {
      _scaffoldKey?.currentState?.openDrawer();
    });
    colorModel = Store.value<ColorModel>(context);
    readModel.book = this.widget.book;
    await readModel.getBookRecord();
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual);

    FlutterStatusbarManager.setFullscreen(true);
    // SystemChrome.setEnabledSystemUIOverlays([]);
    // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlay.top);
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() async {
    super.dispose();
    saveState();
    readModel.clear();
    WidgetsBinding.instance.removeObserver(this);
    FlutterStatusbarManager.setFullscreen(false);
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    saveState();
  }

  saveState() async {
    readModel.saveData();
    if (readModel.sSave) {
      shelfModel.updReadBookProcess(
          UpdateBookProcess(readModel.book.cur, readModel.book.index));
    }
  }

  //拦截菜单和章节view
  bool popWithMenuAndChapterView() {
    if (readModel.showMenu || _scaffoldKey.currentState.isDrawerOpen) {
      if (readModel.showMenu) {
        readModel.toggleShowMenu();
      }
      if (_scaffoldKey.currentState.isDrawerOpen) {
        _scaffoldKey.currentState.openEndDrawer();
      }
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          var popWithMenuAndChapterView2 = popWithMenuAndChapterView();
          if (!popWithMenuAndChapterView2) {
            return false;
          }
          if (!Store.value<ShelfModel>(context)
              .exitsInBookShelfById(readModel.book.Id)) {
            await confirmAddToShelf(context);
          }
          return true;
        },
        child: Scaffold(
            key: _scaffoldKey,
            drawer: Drawer(
              child: ChapterView(),
            ),
            body: Store.connect<ReadModel>(
                builder: (context, ReadModel model, child) {
              return model.loadOk
                  ? Stack(
                      children: [
                        GestureDetector(
                          child: RepaintBoundary(child: PageContentReader()),
                          onTapUp: (e) => readModel.tapPage(context, e),
                        ),

                        // NovelRoteView(model),

                        Offstage(
                          child: Menu(),
                          offstage: !model.showMenu,
                        ),
                      ],
                    )
                  : Container();
            })));
  }

  Future confirmAddToShelf(BuildContext context) async {
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text("提示"),
              content: Text('是否加入本书'),
              actions: <Widget>[
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Store.value<ShelfModel>(context)
                          .modifyShelf(this.widget.book);
                    },
                    child: Text('确定')),
                TextButton(
                    onPressed: () async {
                      readModel.sSave = false;

                      await Store.value<ShelfModel>(context)
                          .delLocalCache([this.widget.book.Id]);
                      Navigator.pop(context);
                    },
                    child: Text('取消')),
              ],
            ));
  }
}
