import 'package:book/entity/read_page.dart';
import 'package:book/entity/text_line.dart';
import 'package:book/entity/text_page.dart';
import 'package:book/model/reader/text_paginator.dart';

/// In-page loading / error placeholders drawn as normal [ReadPage]s.
///
/// No BotToast overlay — the reader canvas paints these like chapter content.
class ReaderLoadingPresenter {
  ReaderLoadingPresenter({
    required this.paginator,
    required this.setLoadingHint,
    required this.setCurPage,
    required this.clearPictures,
    required this.markNeedsPaint,
    required this.notify,
  });

  final TextPaginator paginator;
  final void Function(String text) setLoadingHint;
  final void Function(ReadPage page) setCurPage;
  final void Function() clearPictures;
  final void Function() markNeedsPaint;
  final void Function() notify;

  /// Bumped on every show/hide so superseded paints are ignored.
  int _token = 0;

  /// Lightweight sync placeholder (no paginator / isolate) for open/clear races.
  static ReadPage syncPlaceholder(String hint) {
    final page = ReadPage.kong();
    page.chapterName = '加载中';
    page.chapterContent = hint;
    page.pages = [
      TextPage([TextLine.simple(hint)], 24),
    ];
    return page;
  }

  /// Build a single-page [ReadPage] with a readable error/hint message.
  Future<ReadPage> messagePage(String title, String message) async {
    final page = ReadPage.kong();
    page.chapterName = title;
    page.chapterContent = message;
    try {
      page.pages = await paginator.paginate(page);
    } catch (_) {
      page.pages = const [];
    }
    if (page.pages.isEmpty) {
      // Absolute fallback so drawContent never paints a blank canvas.
      page.pages = [
        TextPage([
          TextLine.simple(message, height: 24),
        ], 24),
      ];
    }
    return page;
  }

  /// Paint an in-page loading hint. Does not touch [Book.pageIndex].
  Future<void> show(String text) async {
    setLoadingHint(text);
    final token = ++_token;
    final page = await messagePage('加载中', text);
    if (token != _token) return; // superseded
    setCurPage(page);
    // Do NOT touch book.index — loading is a 1-page placeholder only.
    // Mutating index here used to wipe restored progress (DB idx → 0).
    clearPictures();
    markNeedsPaint();
    notify();
  }

  /// Content replacement (openChapterAt / chapter load) clears the hint page.
  /// Bump token so any in-flight [show] paint is ignored.
  void hide() {
    _token++;
  }
}
