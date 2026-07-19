import 'dart:async';

import 'package:book/common/read_setting.dart';
import 'package:book/common/local_store.dart';
import 'package:book/entity/book.dart';
import 'package:book/event/event.dart';
import 'package:book/model/read_model.dart';
import 'package:book/model/shelf_model.dart';
import 'package:book/store/providers.dart';
import 'package:book/view/book/chapter_view.dart';
import 'package:book/view/book/reader_menu.dart';
import 'package:book/view/book/page_content_reader.dart';
import 'package:book/view/book/scroll_content_reader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:book/common/common.dart';

class ReadBook extends ConsumerStatefulWidget {
  final Book book;
  final bool reading;

  const ReadBook(this.book, {super.key, this.reading = false});

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
    // Sync seed: paper color + loading page before first frame (avoids flash).
    readModel = ref.read(readModelProvider);
    shelfModel = ref.read(shelfModelProvider);
    readModel.prepareOpen(widget.book);
    setUp();
  }

  Future<void> setUp() async {
    _refreshSub = eventBus.on<ReadRefresh>().listen((event) {
      final b = readModel.book;
      if (b == null) return;
      readModel.resetPages();
      readModel.initPageContent(b.chapterIndex, true);
    });

    WidgetsBinding.instance.addObserver(this);
    _chaptersSub = eventBus.on<OpenChapters>().listen((event) {
      _openChapterCatalog();
    });
    // Enter immersive BEFORE content load so scroll metrics (boxH / padding)
    // settle once — avoids restore jump then insets change (742→766) race.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Let the engine apply inset change before pagination measures Screen.
    await Future<void>.delayed(const Duration(milliseconds: 16));
    if (!mounted) return;
    try {
      await readModel.hydrateReadingSession();
    } catch (e, st) {
      // ignore: avoid_print
      print('hydrateReadingSession failed: $e\n$st');
      if (!readModel.sessionReady) {
        await readModel.failOpen(e);
      }
    }
  }

  @override
  void dispose() {
    _refreshSub?.cancel();
    _chaptersSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    // Flush progress (cancels debounce, snapshots cur/index) before clear().
    saveState(flush: true);
    readModel.clear();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Avoid writing on every resumed tick; persist when leaving foreground.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      saveState(flush: true);
    }
  }

  void saveState({bool flush = false}) {
    final b = readModel.book;
    if (b == null) return;
    // Snapshot after child ScrollContentReader.dispose has applied visible page
    // (children dispose first). For lifecycle pause, scroll listener throttle
    // + ScrollEnd should already have written cur/index.
    final id = b.id;
    final cur = b.chapterIndex;
    final idx = b.pageIndex;
    final name = (cur >= 0 && cur < readModel.chapters.length)
        ? readModel.chapters[cur].title
        : b.readingChapter;
    final allowProgressSave = readModel.allowProgressSave == true;
    final Future<void> done =
        flush ? readModel.flushProgressSave() : readModel.saveData();
    unawaited(done.then((_) {
      if (!allowProgressSave) return;
      shelfModel.updReadBookProcess(
        UpdateBookProcess(id, cur, idx, chapterName: name),
      );
    }));
  }

  bool popWithMenuAndChapterView() {
    if (readModel.showMenu) {
      readModel.toggleShowMenu();
      return false;
    }
    // Chapter catalog is a full-screen route; system back pops it first.
    return true;
  }

  void _openChapterCatalog() {
    if (!mounted) return;
    // Close reader menu if open so catalog is unobstructed.
    if (readModel.showMenu) {
      readModel.toggleShowMenu();
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ChapterView(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isScroll = ref.watch(readModelProvider.select((m) => m.isScrollMode));
    final showMenu = ref.watch(readModelProvider.select((m) => m.showMenu));
    final sessionReady = ref.watch(readModelProvider.select((m) => m.sessionReady));
    final paperTheme =
        ref.watch(readModelProvider.select((m) => m.paperTheme));
    final paper = ReadSetting.paperColor(
      paperTheme == PaperTheme.night ||
              SpUtil.getBool(PrefsKeys.dark, defValue: false)
          ? PaperTheme.night
          : paperTheme,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        if (!popWithMenuAndChapterView()) return;
        final bookId = readModel.book?.id;
        if (bookId != null &&
            !ref.read(shelfModelProvider).isOnShelf(bookId)) {
          await confirmAddToShelf(context);
        }
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: paper,
        // Full-screen chapter catalog is pushed as a route (not a Drawer).
        // Loading states are painted as normal page content (no overlay text).
        body: Stack(
          children: [
            // Instant paper fill under the canvas (matches reader theme).
            ColoredBox(
              color: paper,
              child: const SizedBox.expand(),
            ),
            // Page-turn canvas vs vertical scroll list.
            RepaintBoundary(
              child: isScroll
                  ? const ScrollContentReader()
                  : const PageContentReader(),
            ),
            if (sessionReady && showMenu) const ReaderMenu(),
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
              readModel.allowProgressSave = false;
              await ref
                  .read(shelfModelProvider)
                  .delLocalCache([widget.book.id]);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: Text('取消'),
          ),
        ],
      ),
    );
  }
}
