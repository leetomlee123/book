import 'package:book/common/text_composition.dart';
import 'package:book/entity/Book.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/ReadModel.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/book/ChapterView.dart';
import 'package:book/view/book/Menu.dart';
import 'package:book/view/book/cover_read_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_statusbar_manager/flutter_statusbar_manager.dart';

class ReadBook extends StatefulWidget {
  final Book book;
  final bool reading;

  ReadBook(this.book, {this.reading = false});

  @override
  State<StatefulWidget> createState() {
    return _ReadBookState();
  }
}

class _ReadBookState extends State<ReadBook>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  Widget body;
  ReadModel readModel;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  ColorModel colorModel;
  TextComposition textComposition;

  @override
  void initState() {
    setUp();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  setUp() async {
    readModel = Store.value<ReadModel>(context);
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
    readModel.getBookRecord();
    FlutterStatusbarManager.setFullscreen(true);
  }

  @override
  void dispose() async {
    super.dispose();
    readModel?.pageController?.dispose();
    readModel?.listController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    FlutterStatusbarManager.setFullscreen(false);
    //    if (SpUtil.getBool("dark")) {
    //   await FlutterStatusbarManager.setStyle(StatusBarStyle.LIGHT_CONTENT);
    // } else {
    //   await FlutterStatusbarManager.setStyle(StatusBarStyle.DARK_CONTENT);
    // }
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    readModel.saveData();
  }

  @override
  Future<void> deactivate() async {
    super.deactivate();

    await readModel.saveData();
    readModel.clear();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
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
              return Stack(
                children: [
                  Visibility(
                    child: RepaintBoundary(child: NovelRoteView()),
                    visible: model.loadOk,
                    replacement: Container(),
                  ),
                  Visibility(
                    child: Menu(),
                    visible: model.showMenu,
                    replacement: Container(),
                  ),
                ],
              );
            })));
  }

  Future confirmAddToShelf(BuildContext context) async {
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
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
                    onPressed: () {
                      readModel.sSave = false;

                      Store.value<ShelfModel>(context)
                          .delLocalCache([this.widget.book.Id]);
                      Navigator.pop(context);
                    },
                    child: Text('取消')),
              ],
            ));
  }

  void move(int off) {
    var widgetsBinding = WidgetsBinding.instance;

    widgetsBinding.addPostFrameCallback((callback) {
      readModel.pageController.jumpToPage(off);
    });
  }
// void move(bool isPage, double offset) {
//   var widgetsBinding = WidgetsBinding.instance;
//
//   widgetsBinding.addPostFrameCallback((callback) {
//     if (isPage) {
//       readModel.pageController.jumpToPage(1);
//     } else {
//       if (offset == 0.0) {
//         readModel.listController
//             .jumpTo((readModel.ladderH[readModel.cursor - 1]));
//       } else {
//         readModel.listController.jumpTo(offset);
//       }
//     }
//   });
// }
}
