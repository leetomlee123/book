import 'package:book/common/book_pager.dart';
import 'package:book/common/text_composition.dart';
import 'package:book/entity/read_page.dart';
import 'package:book/entity/text_page.dart';

/// Outcome of a chapter pagination run (ABI v3).
class PaginateOutcome {
  final List<TextPage> pages;
  final bool complete;
  final int nextChar;
  final String engine;
  final int jobId;
  final String? fallbackReason;

  const PaginateOutcome({
    required this.pages,
    this.complete = true,
    this.nextChar = 0,
    this.engine = 'dart',
    this.jobId = 0,
    this.fallbackReason,
  });
}

/// 统一分页入口：metrics 采集 + Rust/Dart 分页 + cancel/progress.
///
/// 从 [TextComposition] 静态 API 薄封装，便于 ReadModel 与测试注入。
class TextPaginator {
  TextPaginator();

  int _nextJobId = 1;
  int _activeJobId = 0;

  /// Currently active native job (0 = none).
  int get activeJobId => _activeJobId;

  /// Cancel any in-flight native pagination job.
  void cancelActive() {
    final id = _activeJobId;
    if (id == 0) return;
    BookPager.cancel(id);
    _activeJobId = 0;
  }

  Future<List<TextPage>> paginate(
    ReadPage readPage, {
    bool shouldJustifyHeight = false,
  }) {
    return TextComposition.parseContentAsync(
      readPage,
      shouldJustifyHeight: shouldJustifyHeight,
    );
  }

  List<TextPage> paginateSync(
    ReadPage readPage, {
    bool shouldJustifyHeight = false,
  }) {
    return TextComposition.parseContent(
      readPage,
      shouldJustifyHeight: shouldJustifyHeight,
    );
  }

  /// First-page-first progressive pagination.
  ///
  /// When native ABI3 is available and [fontPath] is set:
  /// 1. Returns/notifies after page 1 (`first_page_only`)
  /// 2. Continues in background chunks via [onProgress]
  /// 3. Honors [cancelActive] between chunks
  ///
  /// Falls back to full Dart/Rust one-shot when progressive path is unavailable.
  Future<PaginateOutcome> paginateProgressive(
    ReadPage readPage, {
    bool shouldJustifyHeight = false,
    void Function(List<TextPage> pages, bool complete)? onProgress,
    bool firstPageFirst = true,
    /// When true (default for explicit user actions like font change), cancel
    /// any in-flight progressive job. Neighbor preloads pass false so they
    /// do not abort the chapter currently being laid out.
    bool cancelPrevious = true,
  }) async {
    if (cancelPrevious) {
      cancelActive();
    }
    final jobId = _nextJobId++;
    // Track latest job for cancelActive(); concurrent neighbor jobs keep their
    // own jobId and only stop if explicitly cancelled or superseded.
    _activeJobId = jobId;

    final p = layoutParams(shouldJustifyHeight: shouldJustifyHeight);
    final fontSize = p['fontSize'] as double;
    final lineHeight = p['lineHeight'] as double;
    final paragraph = p['paragraph'] as double;
    final padH = p['padH'] as double;
    final boxW = p['boxW'] as double;
    final boxH = p['boxH'] as double;
    final fontFamily = p['fontFamily'] as String;
    final fontPath = p['fontPath'] as String? ?? '';
    final text = readPage.chapterContent;

    final canNative = BookPager.isAvailable && fontPath.isNotEmpty;

    // Short text or no native: one-shot.
    if (!canNative || text.length < 2000 || !firstPageFirst) {
      try {
        final pages = await paginate(
          readPage,
          shouldJustifyHeight: shouldJustifyHeight,
        );
        if (_activeJobId != jobId) {
          return PaginateOutcome(
            pages: const [],
            complete: false,
            jobId: jobId,
            engine: 'cancelled',
            fallbackReason: 'cancelled',
          );
        }
        onProgress?.call(pages, true);
        return PaginateOutcome(
          pages: pages,
          complete: true,
          nextChar: text.length,
          engine: canNative ? 'rust' : 'dart',
          jobId: jobId,
          fallbackReason: canNative ? null : (BookPager.lastError ?? 'dart'),
        );
      } finally {
        if (_activeJobId == jobId) _activeJobId = 0;
      }
    }

    final all = <TextPage>[];
    var startChar = 0;
    var complete = false;
    String? reason;

    try {
      // Page 1 first.
      final first = await BookPager.paginateRangeAsync(
        text: text,
        fontSize: fontSize,
        lineHeight: lineHeight,
        paragraph: paragraph,
        boxWidth: boxW,
        boxHeight: boxH,
        paddingHorizontal: padH,
        paddingVertical: 0,
        shouldJustifyHeight: shouldJustifyHeight,
        fontPath: fontPath,
        fontFamily: fontFamily,
        jobId: jobId,
        firstPageOnly: true,
        startChar: 0,
      );
      if (_activeJobId != jobId) {
        return const PaginateOutcome(
          pages: [],
          complete: false,
          engine: 'cancelled',
          fallbackReason: 'cancelled',
        );
      }
      all.addAll(first.pages);
      startChar = first.nextChar;
      complete = first.complete;
      onProgress?.call(List<TextPage>.from(all), complete);

      // Continue in chunks of pages until done or cancelled.
      while (!complete && _activeJobId == jobId) {
        final chunk = await BookPager.paginateRangeAsync(
          text: text,
          fontSize: fontSize,
          lineHeight: lineHeight,
          paragraph: paragraph,
          boxWidth: boxW,
          boxHeight: boxH,
          paddingHorizontal: padH,
          paddingVertical: 0,
          shouldJustifyHeight: shouldJustifyHeight,
          fontPath: fontPath,
          fontFamily: fontFamily,
          jobId: jobId,
          firstPageOnly: false,
          startChar: startChar,
          maxPages: 8,
        );
        if (_activeJobId != jobId) {
          return PaginateOutcome(
            pages: List<TextPage>.from(all),
            complete: false,
            nextChar: startChar,
            engine: 'rust',
            jobId: jobId,
            fallbackReason: 'cancelled',
          );
        }
        // Re-index pages so pageIndex is continuous.
        final base = all.length;
        for (var i = 0; i < chunk.pages.length; i++) {
          final pg = chunk.pages[i];
          all.add(TextPage(
            pg.lines,
            pg.height,
            pageIndex: base + i,
            charStart: pg.charStart,
            charEnd: pg.charEnd,
          ));
        }
        startChar = chunk.nextChar;
        complete = chunk.complete;
        // Guard against zero-progress loops.
        if (chunk.pages.isEmpty && !complete) {
          reason = 'zero_progress';
          break;
        }
        onProgress?.call(List<TextPage>.from(all), complete);
      }

      if (!complete && reason == null && all.isEmpty) {
        // Hard fallback.
        final pages = await paginate(
          readPage,
          shouldJustifyHeight: shouldJustifyHeight,
        );
        onProgress?.call(pages, true);
        return PaginateOutcome(
          pages: pages,
          complete: true,
          engine: 'dart',
          jobId: jobId,
          fallbackReason: 'rust_empty',
        );
      }

      return PaginateOutcome(
        pages: all,
        complete: complete,
        nextChar: startChar,
        engine: 'rust',
        jobId: jobId,
        fallbackReason: reason,
      );
    } catch (e) {
      // Native progressive failed → full fallback.
      final pages = await paginate(
        readPage,
        shouldJustifyHeight: shouldJustifyHeight,
      );
      if (_activeJobId == jobId) {
        onProgress?.call(pages, true);
      }
      return PaginateOutcome(
        pages: pages,
        complete: true,
        engine: 'dart',
        jobId: jobId,
        fallbackReason: 'rust_exception:$e',
      );
    } finally {
      if (_activeJobId == jobId) _activeJobId = 0;
    }
  }

  Map<String, dynamic> layoutParams({bool shouldJustifyHeight = false}) {
    return TextComposition.layoutParams(
      shouldJustifyHeight: shouldJustifyHeight,
    );
  }

  /// Stable layout fingerprint for page-cache invalidation.
  ///
  /// Box sizes are rounded to integers to avoid thrashing on minor system-UI
  /// height jitter; font metrics keep one decimal place.
  String layoutFingerprint({
    required Map<String, dynamic> layoutParams,
    required int contentLen,
    String contentSig = '',
  }) {
    String n(Object? v, {int decimals = 0}) {
      final d = (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0;
      if (decimals <= 0) return d.round().toString();
      final f = d.toStringAsFixed(decimals);
      // Trim trailing zeros without locale issues.
      return f.replaceFirst(RegExp(r'\.?0+$'), '');
    }

    final fontSize = n(layoutParams['fontSize'], decimals: 1);
    final lineHeight = n(layoutParams['lineHeight'], decimals: 2);
    final paragraph = n(layoutParams['paragraph'], decimals: 1);
    final padH = n(layoutParams['padH'], decimals: 1);
    final boxW = n(layoutParams['boxW']);
    final boxH = n(layoutParams['boxH']);
    final fontFamily = '${layoutParams['fontFamily'] ?? ''}';
    final fontPath = '${layoutParams['fontPath'] ?? ''}';
    final justify = layoutParams['shouldJustifyHeight'] == true ? '1' : '0';
    final abi = '${layoutParams['abi'] ?? bookPagerAbiVersion}';
    final align = '${layoutParams['textAlign'] ?? 'justify'}';
    return 'abi$abi|$fontSize|$lineHeight|$paragraph|$padH|$boxW|$boxH|'
        '$fontFamily|$fontPath|$justify|$align|$contentLen|$contentSig';
  }

  /// Cheap content signature so same-length different bodies don't share cache.
  String contentSignature(String content) {
    if (content.isEmpty) return '0';
    // FNV-1a 32-bit over a sample of head/mid/tail bytes.
    var hash = 0x811c9dc5;
    void mix(int unit) {
      hash ^= unit & 0xff;
      hash = (hash * 0x01000193) & 0xffffffff;
    }

    final len = content.length;
    final step = len <= 256 ? 1 : (len ~/ 128);
    for (var i = 0; i < len; i += step) {
      mix(content.codeUnitAt(i));
    }
    mix(len & 0xff);
    mix((len >> 8) & 0xff);
    mix((len >> 16) & 0xff);
    return hash.toRadixString(16);
  }
}
