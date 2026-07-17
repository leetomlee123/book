import 'dart:async';

import 'package:book/common/ReadSetting.dart';
import 'package:book/common/local_store.dart';
import 'package:book/entity/Book.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ReadModel.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/book/ChapterView.dart';
import 'package:book/view/book/Menu.dart';
import 'package:book/view/book/PageContentRender.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReadBook extends ConsumerStatefulWidget {
  final Book book;
  final bool reading;

  ReadBook(this.book, {this.reading = false});

  @override
  ConsumerState<ReadBook> createState() => _ReadBookState();
}

class _ReadBookState extends ConsumerState<ReadBook>
    with WidgetsBindingObserver {
  late ReadModel readModel;
  late ShelfModel shelfModel;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription? _refreshSub;
  StreamSubscription? _chaptersSub;

  @override
  void initState() {
    super.initState();
    // ref is available in ConsumerState.initState
    setUp();
  }

  Future<void> setUp() async {
    readModel = ref.read(readModelProvider);
    shelfModel = ref.read(shelfModelProvider);
    _refreshSub = eventBus.on<ReadRefresh>().listen((event) {
      final b = readModel.book;
      if (b == null) return;
      readModel.reSetPages();
      readModel.initPageContent(b.cur, true);
    });

    WidgetsBinding.instance.addObserver(this);
    _chaptersSub = eventBus.on<OpenChapters>().listen((event) {
      _scaffoldKey.currentState?.openDrawer();
    });
    readModel.book = widget.book;
    try {
      await readModel.getBookRecord();
    } catch (e, st) {
      // ignore: avoid_print
      print('getBookRecord failed: $e\n$st');
      if (!readModel.loadOk) {
        await readModel.failOpen(e);
      }
    }
    if (!mounted) return;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _refreshSub?.cancel();
    _chaptersSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    saveState();
    readModel.clear();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    saveState();
  }

  void saveState() {
    final b = readModel.book;
    if (b == null) return;
    readModel.saveData();
    if (readModel.sSave == true) {
      shelfModel.updReadBookProcess(UpdateBookProcess(b.cur, b.index));
    }
  }

  bool popWithMenuAndChapterView() {
    if (readModel.showMenu ||
        (_scaffoldKey.currentState?.isDrawerOpen ?? false)) {
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
    final model = ref.watch(readModelProvider);
    final paper = ReadSetting.paperColor(
      model.paperTheme == PaperTheme.night ||
              SpUtil.getBool('dark', defValue: false)
          ? PaperTheme.night
          : model.paperTheme,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        if (!popWithMenuAndChapterView()) return;
        final bookId = readModel.book?.Id;
        if (bookId != null &&
            !ref.read(shelfModelProvider).exitsInBookShelfById(bookId)) {
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
        body: !model.loadOk
            ? ColoredBox(
                color: paper,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      model.loadingHint.isEmpty
                          ? '正在加载目录…'
                          : model.loadingHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: ReadSetting.inkColor(
                          model.paperTheme == PaperTheme.night ||
                                  SpUtil.getBool('dark', defValue: false)
                              ? PaperTheme.night
                              : model.paperTheme,
                        ).withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ),
              )
            : Stack(
                children: [
                  ColoredBox(
                    color: paper,
                    child: const SizedBox.expand(),
                  ),
                  GestureDetector(
                    child: const RepaintBoundary(child: PageContentReader()),
                    onTapUp: (e) => readModel.tapPage(context, e),
                  ),
                  if (model.showMenu) Menu(),
                ],
              ),
      ),
    );
  }

  Future<void> confirmAddToShelf(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("提示"),
        content: Text('是否加入本书'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ref.read(shelfModelProvider).modifyShelf(widget.book);
            },
            child: Text('确定'),
          ),
          TextButton(
            onPressed: () async {
              readModel.sSave = false;
              await ref
                  .read(shelfModelProvider)
                  .delLocalCache([widget.book.Id]);
              Navigator.pop(dialogContext);
            },
            child: Text('取消'),
          ),
        ],
      ),
    );
  }
}
