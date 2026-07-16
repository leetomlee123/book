import 'package:book/common/ReadSetting.dart';
import 'package:book/common/local_store.dart';
import 'package:book/entity/Book.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/ReadModel.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/book/ChapterView.dart';
import 'package:book/view/book/Menu.dart';
import 'package:book/view/book/PageContentRender.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  Widget? body;
  late ReadModel readModel;
  late ShelfModel shelfModel;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  ColorModel? colorModel;

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
      readModel.initPageContent(readModel.book!.cur, true);
    });

    WidgetsBinding.instance.addObserver(this);
    eventBus.on<OpenChapters>().listen((event) {
      _scaffoldKey.currentState?.openDrawer();
    });
    colorModel = Store.value<ColorModel>(context);
    readModel.book = this.widget.book;
    await readModel.getBookRecord();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    super.dispose();
    saveState();
    readModel.clear();
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    saveState();
  }

  saveState() async {
    readModel.saveData();
    if (readModel.sSave == true) {
      shelfModel.updReadBookProcess(
          UpdateBookProcess(readModel.book!.cur, readModel.book!.index));
    }
  }

  //拦截菜单和章节view
  bool popWithMenuAndChapterView() {
    if (readModel.showMenu || (_scaffoldKey.currentState?.isDrawerOpen ?? false)) {
      if (readModel.showMenu) {
        readModel.toggleShowMenu();
      }
      if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
        _scaffoldKey.currentState?.openEndDrawer();
      }
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) async {
          if (didPop) return;
          var popWithMenuAndChapterView2 = popWithMenuAndChapterView();
          if (!popWithMenuAndChapterView2) {
            return;
          }
          if (!Store.value<ShelfModel>(context)
              .exitsInBookShelfById(readModel.book!.Id)) {
            await confirmAddToShelf(context);
          }
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
        child: Scaffold(
            key: _scaffoldKey,
            drawer: Drawer(
              child: ChapterView(),
            ),
            body: Store.connect<ReadModel>(
                builder: (context, ReadModel model, child) {
              final paper = ReadSetting.paperColor(
                model.paperTheme == PaperTheme.night ||
                        SpUtil.getBool('dark', defValue: false)
                    ? PaperTheme.night
                    : model.paperTheme,
              );
              if (!model.loadOk) {
                return ColoredBox(
                  color: paper,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return Stack(
                children: [
                  // Opaque base follows current paper theme.
                  ColoredBox(
                    color: paper,
                    child: const SizedBox.expand(),
                  ),
                  GestureDetector(
                    child: RepaintBoundary(child: PageContentReader()),
                    onTapUp: (e) => readModel.tapPage(context, e),
                  ),
                  if (model.showMenu) Menu(),
                ],
              );
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
