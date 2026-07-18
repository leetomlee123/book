import 'dart:io';

import 'package:book/main.dart';
import 'package:book/route/Routes.dart';
import 'package:book/service/TelAndSmsService.dart';
import 'package:fluro/fluro.dart';
import 'package:book/common/local_store.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class AppInit {
  static Future init() async {
    WidgetsFlutterBinding.ensureInitialized();
    GestureBinding.instance.resamplingEnabled = true;
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
    locator.registerSingleton(TelAndSmsService());
    final router = FluroRouter();
    Routes.configureRoutes(router);
    Routes.router = router;
    await DirectoryUtil.getInstance();
    // Version label for「我的」页 (no package_info_plus — keep in sync with pubspec).
    if (!SpUtil.haveKey('version') || SpUtil.getString('version').isEmpty) {
      SpUtil.putString('version', '1.0.0');
    }
    if (Platform.isAndroid) {
      SystemUiOverlayStyle systemUiOverlayStyle =
          SystemUiOverlayStyle(statusBarColor: Colors.transparent);
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }
  }

  static bool loginState() {
    return SpUtil.haveKey("auth") || SpUtil.haveKey("token");
  }
}
