import 'dart:async';
import 'dart:ui' as ui;

import 'package:book/common/ReadSetting.dart';
import 'package:book/common/local_store.dart';
import 'package:book/entity/ReadPage.dart';
import 'package:book/store/Store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One flattened page tile in the vertical scroll window.
class _ScrollItem {
  final int chapterIndex;
  final int pageIndex;
  final String chapterName;
  final ReadPage readPage;
  final double height;

  const _ScrollItem({
    required this.chapterIndex,
    required this.pageIndex,
    required this.chapterName,
    required this.readPage,
    required this.height,
  });
}

/// Vertical continuous body reader (mode 3).
///
/// Open path loads cur±1 first, then attaches [ScrollController] with
/// [initialScrollOffset] so restore never races maxScrollExtent clamping.
class ScrollContentReader extends ConsumerStatefulWidget {
  const ScrollContentReader({super.key});

  @override
  ConsumerState<ScrollContentReader> createState() =>
      _ScrollContentReaderState();
}

class _ScrollContentReaderState extends ConsumerState<ScrollContentReader> {
  ScrollController? _controller;

  final Map<int, ReadPage> _chapters = {};
  List<_ScrollItem> _items = const [];
  List<double> _offsets = const [];

  int _windowStart = 0;
  int _windowEnd = -1;

  bool _bootstrapped = false;
  bool _loadingNeighbor = false;
  bool _disposed = false;
  bool _restoreDone = false;

  int _lastChapter = 0;
  int _lastPage = 0;

  DateTime? _lastProgressAt;
  static const _progressThrottle = Duration(milliseconds: 400);

  Offset? _downPos;
  int? _activePointer;
  static const double _tapSlop = 18;
  static const double _edgePad = 20;

  void _safeSetState(VoidCallback fn) {
    if (_disposed || !mounted) return;
    setState(fn);
  }

  void _log(String msg) {
    if (kDebugMode) debugPrint('[ScrollRestore] $msg');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _disposed = true;
    try {
      final model = ref.read(readModelProvider);
      model.applyScrollProgress(_lastChapter, _lastPage);
      model.scheduleProgressSave(delay: Duration.zero);
      _log('dispose save cur=$_lastChapter page=$_lastPage');
    } catch (_) {}
    _controller?.removeListener(_onScroll);
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (_disposed || !mounted || _bootstrapped) return;
    final model = ref.read(readModelProvider);
    final b = model.book;
    if (b == null || !model.contentReady) {
      _log(
        'bootstrap wait contentReady=${model.contentReady} '
        'loadOk=${model.loadOk} chapters=${model.chapters.length} '
        'curPage=${model.curPage?.chapterName}',
      );
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!_disposed && mounted && !_bootstrapped) _bootstrap();
      });
      return;
    }

    _bootstrapped = true;
    final bookId = b.Id;
    final cur =
        b.cur.clamp(0, model.chapters.isEmpty ? 0 : model.chapters.length - 1);
    final pageIdx = b.index < 0 ? 0 : b.index;
    _lastChapter = cur;
    _lastPage = pageIdx;
    _restoreDone = false;
    _log(
      'bootstrap target cur=$cur page=$pageIdx chapters=${model.chapters.length}',
    );

    final live = model.curPage;
    if (live != null &&
        live.pages.isNotEmpty &&
        live.chapterName != '加载中' &&
        live.chapterName != '-1' &&
        cur < model.chapters.length &&
        live.chapterName == model.chapters[cur].chapterName) {
      _chapters[cur] = live;
      _log('seeded live cur pages=${live.pages.length}');
    }
    if (!_chapters.containsKey(cur)) {
      await _ensureChapter(cur);
    }
    if (_disposed || !mounted || model.book?.Id != bookId) return;

    // Load neighbors BEFORE first paint so initialScrollOffset is absolute
    // against a stable window (no jumpTo / maxScrollExtent race).
    if (cur > 0) {
      await _ensureChapter(cur - 1);
      if (_disposed || !mounted || model.book?.Id != bookId) return;
    }
    if (cur + 1 < model.chapters.length) {
      await _ensureChapter(cur + 1);
      if (_disposed || !mounted || model.book?.Id != bookId) return;
    }

    _rebuildItems();
    if (_items.isEmpty) {
      _log('bootstrap empty items — reset for retry');
      _bootstrapped = false;
      _chapters.clear();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_disposed && mounted && !_bootstrapped) _bootstrap();
      });
      return;
    }

    final target = _indexOf(cur, pageIdx);
    final initial = _scrollOffsetForItem(target);
    _attachController(initial);
    _lastChapter = cur;
    _lastPage = pageIdx;
    _restoreDone = true;
    try {
      model.applyScrollProgress(cur, pageIdx);
    } catch (_) {}

    _log(
      'bootstrap ready items=${_items.length} '
      'window=$_windowStart..$_windowEnd item=$target initial=$initial',
    );
    _safeSetState(() {});
  }

  void _attachController(double initialOffset) {
    _controller?.removeListener(_onScroll);
    _controller?.dispose();
    _controller = ScrollController(
      initialScrollOffset: initialOffset < 0 ? 0 : initialOffset,
    )..addListener(_onScroll);
  }

  Future<void> _ensureChapter(int idx) async {
    if (_disposed || _chapters.containsKey(idx)) return;
    final model = ref.read(readModelProvider);
    _log('ensureChapter idx=$idx …');
    final page = await model.loadScrollChapter(idx);
    if (_disposed || !mounted) return;
    if (page != null && page.pages.isNotEmpty) {
      _chapters[idx] = page;
      _log('ensureChapter idx=$idx pages=${page.pages.length}');
    } else {
      _log('ensureChapter idx=$idx FAILED page=${page?.chapterName}');
    }
  }

  Future<void> _loadMore({required bool forward}) async {
    if (_disposed || _loadingNeighbor || !_restoreDone) return;
    _loadingNeighbor = true;
    final holdChapter = _lastChapter;
    final holdPage = _lastPage;
    try {
      final model = ref.read(readModelProvider);
      if (forward) {
        final next = _windowEnd + 1;
        if (next >= model.chapters.length) return;
        await _ensureChapter(next);
        if (_disposed || !mounted) return;
        final drop = next - 2;
        if (drop >= 0 && drop != holdChapter && _chapters.containsKey(drop)) {
          _chapters.remove(drop);
        }
      } else {
        final prev = _windowStart - 1;
        if (prev < 0) return;
        await _ensureChapter(prev);
        if (_disposed || !mounted) return;
        final drop = prev + 3;
        if (drop != holdChapter && _chapters.containsKey(drop)) {
          _chapters.remove(drop);
        }
      }
      _rebuildItems();
      final t = _indexOf(holdChapter, holdPage);
      final initial = _scrollOffsetForItem(t);
      _attachController(initial);
      _lastChapter = holdChapter;
      _lastPage = holdPage;
      try {
        model.applyScrollProgress(holdChapter, holdPage);
      } catch (_) {}
      _log(
        'loadMore forward=$forward re-anchor cur=$holdChapter page=$holdPage '
        'item=$t initial=$initial items=${_items.length}',
      );
      _safeSetState(() {});
    } finally {
      _loadingNeighbor = false;
    }
  }

  void _rebuildItems() {
    final model = ref.read(readModelProvider);
    if (_chapters.isEmpty) {
      _items = const [];
      _offsets = const [];
      _windowStart = 0;
      _windowEnd = -1;
      return;
    }
    final keys = _chapters.keys.toList()..sort();
    _windowStart = keys.first;
    _windowEnd = keys.last;
    final out = <_ScrollItem>[];
    for (final c in keys) {
      final rp = _chapters[c]!;
      for (var p = 0; p < rp.pages.length; p++) {
        out.add(_ScrollItem(
          chapterIndex: c,
          pageIndex: p,
          chapterName: rp.chapterName,
          readPage: rp,
          height: model.scrollPageHeight(rp, p),
        ));
      }
    }
    _items = out;
    final offsets = List<double>.filled(_items.length, 0);
    var acc = 0.0;
    for (var i = 0; i < _items.length; i++) {
      offsets[i] = acc;
      acc += _items[i].height;
    }
    _offsets = offsets;
  }

  int _indexOf(int chapter, int page) {
    for (var i = 0; i < _items.length; i++) {
      final it = _items[i];
      if (it.chapterIndex == chapter && it.pageIndex == page) return i;
    }
    var first = -1;
    var last = -1;
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].chapterIndex == chapter) {
        if (first < 0) first = i;
        last = i;
      }
    }
    if (first >= 0) {
      return first + page.clamp(0, last - first);
    }
    return 0;
  }

  double _scrollOffsetForItem(int index) {
    if (_items.isEmpty) return 0;
    final i = index.clamp(0, _items.length - 1);
    return _edgePad + _offsets[i];
  }

  int _itemAtOffset(double scrollOffset) {
    if (_items.isEmpty) return 0;
    final contentY =
        (scrollOffset - _edgePad + 0.5).clamp(0.0, double.infinity);
    var lo = 0;
    var hi = _items.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (_offsets[mid] <= contentY) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  void _onScroll() {
    final c = _controller;
    if (_loadingNeighbor ||
        !_restoreDone ||
        c == null ||
        !c.hasClients ||
        _items.isEmpty) {
      return;
    }
    _maybeLoadNeighbors();
    final now = DateTime.now();
    final last = _lastProgressAt;
    if (last == null || now.difference(last) >= _progressThrottle) {
      _lastProgressAt = now;
      _applyVisibleProgress();
    }
  }

  void _maybeLoadNeighbors() {
    final c = _controller;
    if (_loadingNeighbor ||
        !_restoreDone ||
        c == null ||
        !c.hasClients ||
        _items.isEmpty) {
      return;
    }
    final pos = c.position;
    final model = ref.read(readModelProvider);
    if (pos.maxScrollExtent - pos.pixels < 800 &&
        _windowEnd + 1 < model.chapters.length) {
      unawaited(_loadMore(forward: true));
    } else if (pos.pixels < 800 && _windowStart > 0) {
      unawaited(_loadMore(forward: false));
    }
  }

  void _applyVisibleProgress({bool force = false}) {
    final c = _controller;
    if (_items.isEmpty || !_restoreDone) return;
    if (_loadingNeighbor) return;

    final offset =
        (!_disposed && c != null && c.hasClients) ? c.offset : 0.0;
    final i = _itemAtOffset(offset);
    if (i < 0 || i >= _items.length) return;
    final it = _items[i];
    if (!force &&
        (it.chapterIndex - _lastChapter).abs() > 1 &&
        _lastProgressAt != null &&
        DateTime.now().difference(_lastProgressAt!) <
            const Duration(seconds: 2)) {
      _log(
        'skip progress jump $_lastChapter:$_lastPage → '
        '${it.chapterIndex}:${it.pageIndex}',
      );
      return;
    }
    _lastChapter = it.chapterIndex;
    _lastPage = it.pageIndex;
    try {
      final model = ref.read(readModelProvider);
      model.applyScrollProgress(it.chapterIndex, it.pageIndex);
      if (force) model.scheduleProgressSave(delay: Duration.zero);
    } catch (_) {}
  }

  void _onPointerDown(PointerDownEvent e) {
    _activePointer = e.pointer;
    _downPos = e.localPosition;
  }

  void _onPointerUp(PointerUpEvent e) {
    if (e.pointer != _activePointer) return;
    final down = _downPos;
    _activePointer = null;
    _downPos = null;
    if (down == null) return;
    if ((e.localPosition - down).distance > _tapSlop) return;
    final size = MediaQuery.sizeOf(context);
    final x = e.localPosition.dx;
    final y = e.localPosition.dy;
    if (x > size.width / 3 && x < 2 * size.width / 3 && y < size.height * 0.75) {
      ref.read(readModelProvider).toggleShowMenu();
    }
  }

  void _onPointerCancel(PointerCancelEvent e) {
    if (e.pointer != _activePointer) return;
    _activePointer = null;
    _downPos = null;
  }

  @override
  Widget build(BuildContext context) {
    final paperTheme = ref.watch(
      readModelProvider.select((m) => m.paperTheme),
    );
    final loadingHint = ref.watch(
      readModelProvider.select((m) => m.loadingHint),
    );
    final contentReady = ref.watch(
      readModelProvider.select((m) => m.contentReady),
    );
    final dark = paperTheme == PaperTheme.night ||
        SpUtil.getBool('dark', defValue: false);
    final paper = ReadSetting.paperColor(
      dark ? PaperTheme.night : paperTheme,
    );
    final meta = ReadSetting.metaColor(
      dark ? PaperTheme.night : paperTheme,
    );

    if (contentReady && !_bootstrapped && !_disposed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed && mounted && !_bootstrapped) _bootstrap();
      });
    }

    final c = _controller;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: ColoredBox(
        color: paper,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n is ScrollEndNotification && _restoreDone) {
              _applyVisibleProgress(force: true);
              _maybeLoadNeighbors();
            }
            return false;
          },
          child: (_items.isEmpty || c == null)
              ? Center(
                  child: Text(
                    loadingHint.isNotEmpty ? loadingHint : '正在加载…',
                    style: TextStyle(color: meta, fontSize: 15),
                  ),
                )
              : ListView.builder(
                  controller: c,
                  padding: const EdgeInsets.only(
                    top: _edgePad,
                    bottom: _edgePad,
                  ),
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  itemCount: _items.length,
                  itemExtentBuilder: (index, _) {
                    if (index < 0 || index >= _items.length) return null;
                    return _items[index].height;
                  },
                  itemBuilder: (context, index) {
                    return _ScrollPageTile(item: _items[index]);
                  },
                ),
        ),
      ),
    );
  }
}

class _ScrollPageTile extends ConsumerWidget {
  final _ScrollItem item;
  const _ScrollPageTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.read(readModelProvider);
    final pic = model.scrollPagePicture(
      item.chapterIndex,
      item.pageIndex,
      item.readPage,
    );
    return SizedBox(
      height: item.height,
      width: double.infinity,
      child: pic == null
          ? const SizedBox.shrink()
          : CustomPaint(
              painter: _PicturePainter(pic),
              isComplex: true,
              willChange: false,
              child: const SizedBox.expand(),
            ),
    );
  }
}

class _PicturePainter extends CustomPainter {
  final ui.Picture picture;
  _PicturePainter(this.picture);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPicture(picture);
  }

  @override
  bool shouldRepaint(covariant _PicturePainter oldDelegate) =>
      oldDelegate.picture != picture;
}
