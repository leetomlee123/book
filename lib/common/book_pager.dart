import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:book/common/app_log.dart';
import 'package:book/entity/text_line.dart';
import 'package:book/entity/text_page.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

typedef _PaginateNative = Pointer<Utf8> Function(Pointer<Utf8> input);
typedef _PaginateDart = Pointer<Utf8> Function(Pointer<Utf8> input);
typedef _FreeNative = Void Function(Pointer<Utf8> ptr);
typedef _FreeDart = void Function(Pointer<Utf8> ptr);
typedef _AbiVersionNative = Int32 Function();
typedef _AbiVersionDart = int Function();
typedef _CancelNative = Void Function(Uint64 jobId);
typedef _CancelDart = void Function(int jobId);

/// Minimum native ABI we accept.
///
/// ABI 3: semantic lines (top/height/justify/target_width), required font_path,
/// PaginateResult envelope, cancel/range.
const int bookPagerAbiVersion = 3;
const int _minAbiVersion = 3;

/// Result of a native (or mapped) paginate call.
class PaginateResult {
  final List<TextPage> pages;
  final bool complete;
  final int nextChar;
  final String engine;
  final int abi;

  const PaginateResult({
    required this.pages,
    this.complete = true,
    this.nextChar = 0,
    this.engine = 'rust',
    this.abi = bookPagerAbiVersion,
  });
}

/// FFI bridge to the Rust `book_pager` library (ABI v3).
///
/// Rust decides line breaks + justify **intent**. Flutter paints with Skia.
class BookPager {
  BookPager._();

  static _PaginateDart? _paginate;
  static _PaginateDart? _paginateRange;
  static _FreeDart? _free;
  static _CancelDart? _cancel;
  static bool _initAttempted = false;
  static String? lastError;
  static int loadedAbi = 0;

  static bool get isAvailable {
    _ensureInit();
    return _paginate != null;
  }

  static void _ensureInit() {
    if (_initAttempted) return;
    _initAttempted = true;
    try {
      final lib = _open();
      int abi = 0;
      try {
        final abiFn = lib.lookupFunction<_AbiVersionNative, _AbiVersionDart>(
          'book_pager_abi_version',
        );
        abi = abiFn();
      } catch (_) {
        abi = 0;
      }
      loadedAbi = abi;
      if (abi < _minAbiVersion) {
        lastError =
            'native book_pager ABI $abi < $_minAbiVersion (rebuild with build_book_pager.bat --android)';
        AppLog.w(
          'BookPager',
          'skipping outdated native lib (abi=$abi); using Dart pager',
        );
        _paginate = null;
        _free = null;
        return;
      }
      _paginate = lib
          .lookupFunction<_PaginateNative, _PaginateDart>('book_pager_paginate');
      try {
        _paginateRange = lib.lookupFunction<_PaginateNative, _PaginateDart>(
          'book_pager_paginate_range',
        );
      } catch (_) {
        _paginateRange = _paginate;
      }
      _free =
          lib.lookupFunction<_FreeNative, _FreeDart>('book_pager_free_string');
      try {
        _cancel =
            lib.lookupFunction<_CancelNative, _CancelDart>('book_pager_cancel');
      } catch (_) {
        _cancel = null;
      }
      debugPrint('[PagerEngine] loaded libbook_pager abi=$abi OK');
      AppLog.i('BookPager', 'loaded native book_pager abi=$abi');
    } catch (e, st) {
      lastError = '$e';
      final msg = '$e';
      final missing = msg.contains('not found') ||
          msg.contains('Failed to load dynamic library');
      if (missing) {
        debugPrint(
          '[PagerEngine] native lib missing for this ABI → DART pager '
          '(build with build_book_pager.bat --android)',
        );
        AppLog.i(
          'BookPager',
          'native lib not packaged for this ABI; using Dart pager',
        );
      } else {
        debugPrint('[PagerEngine] native load failed → DART pager: $e');
        AppLog.w('BookPager', 'failed to load native lib', error: e);
        debugPrint('BookPager: failed to load native lib: $e\n$st');
      }
      _paginate = null;
      _free = null;
    }
  }

  static DynamicLibrary _open() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libbook_pager.so');
    }
    if (Platform.isWindows) {
      final candidates = <String>[
        p.join(Directory.current.path, 'native', 'target', 'release',
            'book_pager.dll'),
        p.join(Directory.current.path, 'native', 'target', 'debug',
            'book_pager.dll'),
        p.join(Directory.current.path, 'native', 'book_pager', 'target',
            'release', 'book_pager.dll'),
        p.join(Directory.current.path, 'native', 'book_pager', 'target',
            'debug', 'book_pager.dll'),
        'book_pager.dll',
      ];
      for (final c in candidates) {
        try {
          return DynamicLibrary.open(c);
        } catch (_) {}
      }
      return DynamicLibrary.open('book_pager.dll');
    }
    if (Platform.isLinux) {
      return DynamicLibrary.open('libbook_pager.so');
    }
    if (Platform.isMacOS || Platform.isIOS) {
      return DynamicLibrary.open('libbook_pager.dylib');
    }
    throw UnsupportedError('BookPager: unsupported platform');
  }

  /// Cancel a native job (no-op if unsupported / jobId==0).
  static void cancel(int jobId) {
    if (jobId == 0) return;
    _ensureInit();
    _cancel?.call(jobId);
  }

  static Map<String, dynamic> _inputMap({
    required String text,
    required double fontSize,
    required double lineHeight,
    required double paragraph,
    required double boxWidth,
    required double boxHeight,
    required double paddingHorizontal,
    double paddingVertical = 0,
    bool shouldJustifyHeight = false,
    String fontPath = '',
    String fontFamily = 'HarmonyOSSansSC',
    String textAlign = 'justify',
    double baseLetterSpacing = 0,
    int jobId = 0,
    bool firstPageOnly = false,
    int startChar = 0,
    int maxPages = 0,
  }) {
    return <String, dynamic>{
      'text': text,
      'font_size': fontSize,
      'line_height': lineHeight,
      'paragraph': paragraph,
      'paragraph_spacing': paragraph,
      'box_width': boxWidth,
      'box_height': boxHeight,
      'page_width': boxWidth,
      'page_height': boxHeight,
      'padding_horizontal': paddingHorizontal,
      'padding_left': paddingHorizontal,
      'padding_right': paddingHorizontal,
      'padding_vertical': paddingVertical,
      'should_justify_height': shouldJustifyHeight,
      'font_path': fontPath,
      'font_family': fontFamily,
      'text_align': textAlign,
      'base_letter_spacing': baseLetterSpacing,
      'job_id': jobId,
      'first_page_only': firstPageOnly,
      'start_char': startChar,
      'max_pages': maxPages,
    };
  }

  static TextLine _lineFromMap(Map<String, dynamic> lm) {
    return TextLine(
      lm['text'] as String? ?? '',
      top: (lm['top'] as num?)?.toDouble() ??
          (lm['dy'] as num?)?.toDouble() ??
          0,
      height: (lm['height'] as num?)?.toDouble() ?? 0,
      justify: lm['justify'] as bool? ?? false,
      isLastLine: lm['is_last_line'] as bool? ??
          lm['isLastLine'] as bool? ??
          false,
      isParagraphEnd: lm['is_paragraph_end'] as bool? ??
          lm['isParagraphEnd'] as bool? ??
          false,
      targetWidth: (lm['target_width'] as num?)?.toDouble() ??
          (lm['targetWidth'] as num?)?.toDouble() ??
          0,
      // ABI3: prefer paint-time spacing; ignore rust letter_spacing if present.
      letterSpacing: null,
    );
  }

  static TextPage _pageFromMap(Map<String, dynamic> m, {int fallbackIndex = 0}) {
    final lines = (m['lines'] as List? ?? [])
        .map((l) => _lineFromMap(Map<String, dynamic>.from(l as Map)))
        .toList();
    return TextPage(
      lines,
      (m['height'] as num?)?.toDouble() ?? 0,
      pageIndex: m['page_index'] as int? ??
          m['pageIndex'] as int? ??
          fallbackIndex,
      charStart: m['char_start'] as int? ?? m['charStart'] as int? ?? 0,
      charEnd: m['char_end'] as int? ?? m['charEnd'] as int? ?? 0,
    );
  }

  static PaginateResult _decodeResult(String out) {
    final decoded = jsonDecode(out);
    if (decoded is Map && decoded.containsKey('error')) {
      throw StateError('BookPager error: ${decoded['error']}');
    }
    // ABI3 envelope
    if (decoded is Map && decoded['pages'] is List) {
      final pages = <TextPage>[];
      final list = decoded['pages'] as List;
      for (var i = 0; i < list.length; i++) {
        pages.add(
          _pageFromMap(Map<String, dynamic>.from(list[i] as Map),
              fallbackIndex: i),
        );
      }
      return PaginateResult(
        pages: pages,
        complete: decoded['complete'] as bool? ?? true,
        nextChar: decoded['next_char'] as int? ??
            decoded['nextChar'] as int? ??
            0,
        engine: decoded['engine'] as String? ?? 'rust',
        abi: decoded['abi'] as int? ?? loadedAbi,
      );
    }
    // Legacy bare list (should not happen with ABI3)
    if (decoded is List) {
      final pages = <TextPage>[];
      for (var i = 0; i < decoded.length; i++) {
        pages.add(
          _pageFromMap(Map<String, dynamic>.from(decoded[i] as Map),
              fallbackIndex: i),
        );
      }
      return PaginateResult(pages: pages, complete: true, engine: 'rust');
    }
    throw StateError('BookPager: unexpected payload ${decoded.runtimeType}');
  }

  static PaginateResult paginateResult({
    required String text,
    required double fontSize,
    required double lineHeight,
    required double paragraph,
    required double boxWidth,
    required double boxHeight,
    required double paddingHorizontal,
    double paddingVertical = 0,
    bool shouldJustifyHeight = false,
    String fontPath = '',
    String fontFamily = 'HarmonyOSSansSC',
    String textAlign = 'justify',
    double baseLetterSpacing = 0,
    int jobId = 0,
    bool firstPageOnly = false,
    int startChar = 0,
    int maxPages = 0,
    bool useRange = false,
  }) {
    _ensureInit();
    final paginateFn = useRange ? (_paginateRange ?? _paginate) : _paginate;
    final freeFn = _free;
    if (paginateFn == null || freeFn == null) {
      throw StateError(
          'BookPager native library not loaded: ${lastError ?? "unknown"}');
    }
    if (fontPath.isEmpty) {
      throw StateError('BookPager ABI3 requires font_path');
    }

    final input = _inputMap(
      text: text,
      fontSize: fontSize,
      lineHeight: lineHeight,
      paragraph: paragraph,
      boxWidth: boxWidth,
      boxHeight: boxHeight,
      paddingHorizontal: paddingHorizontal,
      paddingVertical: paddingVertical,
      shouldJustifyHeight: shouldJustifyHeight,
      fontPath: fontPath,
      fontFamily: fontFamily,
      textAlign: textAlign,
      baseLetterSpacing: baseLetterSpacing,
      jobId: jobId,
      firstPageOnly: firstPageOnly,
      startChar: startChar,
      maxPages: maxPages,
    );

    final inputPtr = jsonEncode(input).toNativeUtf8();
    Pointer<Utf8>? outPtr;
    try {
      outPtr = paginateFn(inputPtr);
      if (outPtr == nullptr) {
        throw StateError('BookPager returned null');
      }
      return _decodeResult(outPtr.toDartString());
    } finally {
      malloc.free(inputPtr);
      if (outPtr != null && outPtr != nullptr) {
        freeFn(outPtr);
      }
    }
  }

  /// Layout [text] into pages on the **current** isolate (sync / may block).
  static List<TextPage> paginate({
    required String text,
    required double fontSize,
    required double lineHeight,
    required double paragraph,
    required double boxWidth,
    required double boxHeight,
    required double paddingHorizontal,
    double paddingVertical = 0,
    bool shouldJustifyHeight = true,
    String fontPath = '',
    String fontFamily = 'HarmonyOSSansSC',
    int jobId = 0,
  }) {
    return paginateResult(
      text: text,
      fontSize: fontSize,
      lineHeight: lineHeight,
      paragraph: paragraph,
      boxWidth: boxWidth,
      boxHeight: boxHeight,
      paddingHorizontal: paddingHorizontal,
      paddingVertical: paddingVertical,
      shouldJustifyHeight: shouldJustifyHeight,
      fontPath: fontPath,
      fontFamily: fontFamily,
      jobId: jobId,
    ).pages;
  }

  /// Paginate on a **background isolate** so the UI isolate stays responsive.
  static Future<List<TextPage>> paginateAsync({
    required String text,
    required double fontSize,
    required double lineHeight,
    required double paragraph,
    required double boxWidth,
    required double boxHeight,
    required double paddingHorizontal,
    double paddingVertical = 0,
    bool shouldJustifyHeight = true,
    String fontPath = '',
    String fontFamily = 'HarmonyOSSansSC',
    int jobId = 0,
  }) {
    if (text.length < 800) {
      return Future.value(paginate(
        text: text,
        fontSize: fontSize,
        lineHeight: lineHeight,
        paragraph: paragraph,
        boxWidth: boxWidth,
        boxHeight: boxHeight,
        paddingHorizontal: paddingHorizontal,
        paddingVertical: paddingVertical,
        shouldJustifyHeight: shouldJustifyHeight,
        fontPath: fontPath,
        fontFamily: fontFamily,
        jobId: jobId,
      ));
    }

    final payload = _inputMap(
      text: text,
      fontSize: fontSize,
      lineHeight: lineHeight,
      paragraph: paragraph,
      boxWidth: boxWidth,
      boxHeight: boxHeight,
      paddingHorizontal: paddingHorizontal,
      paddingVertical: paddingVertical,
      shouldJustifyHeight: shouldJustifyHeight,
      fontPath: fontPath,
      fontFamily: fontFamily,
      jobId: jobId,
    );
    return Isolate.run(() => _paginateFromPayload(payload));
  }

  /// First-page-first + optional continuation (still one shot for now;
  /// caller may loop with [startChar] / [firstPageOnly]).
  static Future<PaginateResult> paginateRangeAsync({
    required String text,
    required double fontSize,
    required double lineHeight,
    required double paragraph,
    required double boxWidth,
    required double boxHeight,
    required double paddingHorizontal,
    double paddingVertical = 0,
    bool shouldJustifyHeight = true,
    String fontPath = '',
    String fontFamily = 'HarmonyOSSansSC',
    int jobId = 0,
    bool firstPageOnly = false,
    int startChar = 0,
    int maxPages = 0,
  }) {
    final payload = _inputMap(
      text: text,
      fontSize: fontSize,
      lineHeight: lineHeight,
      paragraph: paragraph,
      boxWidth: boxWidth,
      boxHeight: boxHeight,
      paddingHorizontal: paddingHorizontal,
      paddingVertical: paddingVertical,
      shouldJustifyHeight: shouldJustifyHeight,
      fontPath: fontPath,
      fontFamily: fontFamily,
      jobId: jobId,
      firstPageOnly: firstPageOnly,
      startChar: startChar,
      maxPages: maxPages,
    );
    return Isolate.run(() => _paginateResultFromPayload(payload));
  }

  static List<TextPage> _paginateFromPayload(Map<String, dynamic> p) {
    return _paginateResultFromPayload(p).pages;
  }

  static PaginateResult _paginateResultFromPayload(Map<String, dynamic> p) {
    return paginateResult(
      text: p['text'] as String? ?? '',
      fontSize: (p['font_size'] as num?)?.toDouble() ?? 26,
      lineHeight: (p['line_height'] as num?)?.toDouble() ?? 1.8,
      paragraph: (p['paragraph'] as num?)?.toDouble() ??
          (p['paragraph_spacing'] as num?)?.toDouble() ??
          10,
      boxWidth: (p['box_width'] as num?)?.toDouble() ??
          (p['page_width'] as num?)?.toDouble() ??
          360,
      boxHeight: (p['box_height'] as num?)?.toDouble() ??
          (p['page_height'] as num?)?.toDouble() ??
          640,
      paddingHorizontal: (p['padding_horizontal'] as num?)?.toDouble() ?? 20,
      paddingVertical: (p['padding_vertical'] as num?)?.toDouble() ?? 0,
      shouldJustifyHeight: p['should_justify_height'] as bool? ?? false,
      fontPath: p['font_path'] as String? ?? '',
      fontFamily: p['font_family'] as String? ?? 'HarmonyOSSansSC',
      textAlign: p['text_align'] as String? ?? 'justify',
      baseLetterSpacing: (p['base_letter_spacing'] as num?)?.toDouble() ?? 0,
      jobId: p['job_id'] as int? ?? 0,
      firstPageOnly: p['first_page_only'] as bool? ?? false,
      startChar: p['start_char'] as int? ?? 0,
      maxPages: p['max_pages'] as int? ?? 0,
      useRange: true,
    );
  }
}
