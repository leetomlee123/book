import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// System bar policy for the app.
///
/// **Only the active reader body** is immersive (no status / nav bars).
/// Everywhere else — shelf, detail, catalog, settings, after leaving the
/// reader — system bars must stay visible.
///
/// Nested pages opened *on top of* the reader (chapter list, font picker)
/// temporarily show bars, then restore immersive when they pop **if** the
/// reader is still underneath. Leaving the reader entirely always shows bars.
class SystemUiHelper {
  SystemUiHelper._();

  /// How many [ReadBook] sessions currently own the immersive mode.
  static int _readerDepth = 0;

  static bool get readerActive => _readerDepth > 0;

  /// Call when a reading page becomes the active immersive surface.
  static Future<void> enterReaderImmersive() async {
    _readerDepth++;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  /// Call when a reading page is disposed / permanently left.
  static Future<void> exitReaderImmersive() async {
    if (_readerDepth > 0) _readerDepth--;
    if (_readerDepth == 0) {
      await showSystemBars();
    } else {
      // Another reader instance still active (rare) — stay immersive.
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  /// Temporarily show bars while a page is on top of the reader
  /// (catalog, font picker, etc.). Safe to call outside the reader too.
  static Future<void> showSystemBars() async {
    // `manual` with all overlays is the most reliable way to undo
    // immersiveSticky on Android; edgeToEdge alone can leave bars hidden.
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    // Prefer edge-to-edge content under a transparent status bar.
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (Platform.isAndroid) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
      );
    }
  }

  /// After a temporary overlay page pops: re-hide bars if the reader is still
  /// underneath; otherwise keep bars visible.
  static Future<void> restoreAfterOverlay() async {
    if (_readerDepth > 0) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await showSystemBars();
    }
  }
}
