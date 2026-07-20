import 'dart:io';
import 'dart:ui' as ui;

import 'package:book/common/pic_widget.dart';
import 'package:book/common/local_store.dart';
import 'package:book/common/reader_font_bootstrap.dart';
import 'package:book/data/db/reader_database.dart';
import 'package:book/main.dart';
import 'package:book/route/routes.dart';
import 'package:book/service/firebase_bootstrap.dart';
import 'package:book/service/tel_and_sms_service.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:book/common/common.dart';

class AppInit {
  static FlutterExceptionHandler? _prevFlutterError;
  static ui.ErrorCallback? _prevPlatformError;

  /// Swallow image-resource / cover-load noise from FlutterError + platform dumps.
  static void _installQuietImageErrorFilter() {
    _prevFlutterError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (_isImageNoise(details.exception, details.library, details.context)) {
        // Keep a one-line breadcrumb in debug only.
        assert(() {
          debugPrint(
            '[Cover] suppressed: ${details.exceptionAsString().split('\n').first}',
          );
          return true;
        }());
        return;
      }
      final prev = _prevFlutterError;
      if (prev != null) {
        prev(details);
      } else {
        FlutterError.presentError(details);
      }
    };

    _prevPlatformError = ui.PlatformDispatcher.instance.onError;
    ui.PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      if (PicWidget.isBenignCoverError(error) ||
          error.toString().contains('Invalid image data')) {
        assert(() {
          debugPrint(
            '[Cover] platform suppressed: ${error.toString().split('\n').first}',
          );
          return true;
        }());
        return true; // handled
      }
      final prev = _prevPlatformError;
      if (prev != null) return prev(error, stack);
      return false;
    };
  }

  static bool _isImageNoise(
    Object exception,
    String? library,
    DiagnosticsNode? context,
  ) {
    final lib = library ?? '';
    final ctx = context?.toString() ?? '';
    if (lib.contains('image resource') ||
        ctx.contains('image resource') ||
        ctx.contains('resolving an image') ||
        ctx.contains('while resolving an image')) {
      return true;
    }
    return PicWidget.isBenignCoverError(exception);
  }

  static Future init() async {
    WidgetsFlutterBinding.ensureInitialized();
    GestureBinding.instance.resamplingEnabled = true;
    // Firebase first so Crashlytics can wrap subsequent FlutterError handlers.
    await FirebaseBootstrap.init();
    // Cover CDN WebP/network failures are common; show placeholder, not red dump.
    // Installed *after* Firebase so image noise is filtered before Crashlytics.
    _installQuietImageErrorFilter();
    if (Platform.isIOS || Platform.isAndroid) {
      // Prefer photos on modern Android; fall back to storage where available.
      final status = await Permission.photos.request();
      if (!status.isGranted && !status.isLimited) {
        final storage = await Permission.storage.request();
        if (!storage.isGranted) {
          // Continue even if denied so app can still start.
        }
      }
    }

    await SpUtil.getInstance();
    // Extract bundled CJK TTF so Rust book_pager uses the same face as Flutter.
    await ReaderFontBootstrap.ensure();
    // Single-file reader.db — drop legacy multi-DB files (no migration).
    await ReaderDatabase.wipeLegacyDatabases();
    // Drop pre-reader.db SpUtil page-layout keys (`*pages*`).
    for (final key in SpUtil.getKeys().toList()) {
      if (key.contains('pages')) {
        SpUtil.remove(key);
      }
    }
    locator.registerSingleton(TelAndSmsService());
    final router = FluroRouter();
    Routes.configureRoutes(router);
    Routes.router = router;
    await DirectoryUtil.getInstance();
    // Version label for「我的」页 (no package_info_plus — keep in sync with pubspec).
    if (!SpUtil.haveKey(PrefsKeys.version) || SpUtil.getString(PrefsKeys.version).isEmpty) {
      SpUtil.putString(PrefsKeys.version, '1.0.0');
    }
    // Default: visible transparent status bar (edge-to-edge). Only the
    // reader switches to immersiveSticky to hide system bars.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (Platform.isAndroid) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
      );
    }
  }

  static bool loginState() {
    return SpUtil.haveKey(PrefsKeys.auth) || SpUtil.haveKey(PrefsKeys.token);
  }
}
