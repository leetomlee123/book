import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:book/common/app_log.dart';
import 'package:book/entity/TextLine.dart';
import 'package:book/entity/TextPage.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

typedef _PaginateNative = Pointer<Utf8> Function(Pointer<Utf8> input);
typedef _PaginateDart = Pointer<Utf8> Function(Pointer<Utf8> input);
typedef _FreeNative = Void Function(Pointer<Utf8> ptr);
typedef _FreeDart = void Function(Pointer<Utf8> ptr);
typedef _AbiVersionNative = Int32 Function();
typedef _AbiVersionDart = int Function();

/// Minimum native ABI we accept. Older packaged `.so` files (pre-Android font
/// load) panic with `no default font found` and abort the process — refuse them.
const int _minAbiVersion = 2;

/// FFI bridge to the Rust `book_pager` library.
///
/// Safe to call from any isolate: each isolate loads the dynamic library once.
/// Prefer [paginateAsync] from the UI isolate so long chapters do not jank frames.
class BookPager {
  BookPager._();

  static _PaginateDart? _paginate;
  static _FreeDart? _free;
  static bool _initAttempted = false;
  static String? lastError;

  static bool get isAvailable {
    _ensureInit();
    return _paginate != null;
  }

  static void _ensureInit() {
    if (_initAttempted) return;
    _initAttempted = true;
    try {
      final lib = _open();
      // Reject pre-v2 libs: they crash the whole process on Android when
      // cosmic-text has no system fonts loaded (fontdb skips Android).
      int abi = 0;
      try {
        final abiFn = lib.lookupFunction<_AbiVersionNative, _AbiVersionDart>(
          'book_pager_abi_version',
        );
        abi = abiFn();
      } catch (_) {
        abi = 0;
      }
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
      _free =
          lib.lookupFunction<_FreeNative, _FreeDart>('book_pager_free_string');
    } catch (e, st) {
      lastError = '$e';
      // Missing ABI is expected on emulators until jniLibs/<abi>/ is built.
      // TextComposition falls back to Dart TextPainter — not a hard failure.
      final msg = '$e';
      final missing = msg.contains('not found') ||
          msg.contains('Failed to load dynamic library');
      if (missing) {
        AppLog.i(
          'BookPager',
          'native lib not packaged for this ABI; using Dart pager '
          '(build with build_book_pager.bat --android for arm64+x86_64)',
        );
      } else {
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
    String fontFamily = 'Roboto',
  }) {
    _ensureInit();
    final paginateFn = _paginate;
    final freeFn = _free;
    if (paginateFn == null || freeFn == null) {
      throw StateError(
          'BookPager native library not loaded: ${lastError ?? "unknown"}');
    }

    final input = <String, dynamic>{
      'text': text,
      'font_size': fontSize,
      'line_height': lineHeight,
      'paragraph': paragraph,
      'box_width': boxWidth,
      'box_height': boxHeight,
      'padding_horizontal': paddingHorizontal,
      'padding_vertical': paddingVertical,
      'should_justify_height': shouldJustifyHeight,
      'font_path': fontPath,
      'font_family': fontFamily,
    };

    final inputPtr = jsonEncode(input).toNativeUtf8();
    Pointer<Utf8>? outPtr;
    try {
      outPtr = paginateFn(inputPtr);
      if (outPtr == nullptr) {
        throw StateError('BookPager returned null');
      }
      final out = outPtr.toDartString();
      final decoded = jsonDecode(out);
      if (decoded is Map && decoded.containsKey('error')) {
        throw StateError('BookPager error: ${decoded['error']}');
      }
      if (decoded is! List) {
        throw StateError('BookPager: expected list, got ${decoded.runtimeType}');
      }
      return decoded.map<TextPage>((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final lines = (m['lines'] as List? ?? []).map((l) {
          final lm = Map<String, dynamic>.from(l as Map);
          return TextLine(
            lm['text'] as String? ?? '',
            (lm['dx'] as num?)?.toDouble() ?? 0,
            (lm['dy'] as num?)?.toDouble() ?? 0,
            (lm['letter_spacing'] as num?)?.toDouble() ?? 0,
          );
        }).toList();
        return TextPage(
          lines,
          (m['height'] as num?)?.toDouble() ?? 0,
        );
      }).toList();
    } finally {
      malloc.free(inputPtr);
      if (outPtr != null && outPtr != nullptr) {
        freeFn(outPtr);
      }
    }
  }

  /// Paginate on a **background isolate** so the UI isolate stays responsive.
  ///
  /// Each worker isolate loads `libbook_pager` itself (static state is
  /// per-isolate). Prefer this from UI code for full chapters.
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
    String fontFamily = 'Roboto',
  }) {
    // Short / empty text: avoid isolate spawn overhead.
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
      ));
    }

    final payload = <String, dynamic>{
      'text': text,
      'font_size': fontSize,
      'line_height': lineHeight,
      'paragraph': paragraph,
      'box_width': boxWidth,
      'box_height': boxHeight,
      'padding_horizontal': paddingHorizontal,
      'padding_vertical': paddingVertical,
      'should_justify_height': shouldJustifyHeight,
      'font_path': fontPath,
      'font_family': fontFamily,
    };
    return Isolate.run(() => _paginateFromPayload(payload));
  }

  /// Top-level-friendly entry for [Isolate.run] / [compute].
  static List<TextPage> _paginateFromPayload(Map<String, dynamic> p) {
    return paginate(
      text: p['text'] as String? ?? '',
      fontSize: (p['font_size'] as num?)?.toDouble() ?? 26,
      lineHeight: (p['line_height'] as num?)?.toDouble() ?? 1.8,
      paragraph: (p['paragraph'] as num?)?.toDouble() ?? 10,
      boxWidth: (p['box_width'] as num?)?.toDouble() ?? 360,
      boxHeight: (p['box_height'] as num?)?.toDouble() ?? 640,
      paddingHorizontal: (p['padding_horizontal'] as num?)?.toDouble() ?? 20,
      paddingVertical: (p['padding_vertical'] as num?)?.toDouble() ?? 0,
      shouldJustifyHeight: p['should_justify_height'] as bool? ?? true,
      fontPath: p['font_path'] as String? ?? '',
      fontFamily: p['font_family'] as String? ?? 'Roboto',
    );
  }
}
