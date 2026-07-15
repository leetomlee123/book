import 'dart:io';

import 'package:book/main.dart';
import 'package:book/route/Routes.dart';
import 'package:book/service/TelAndSmsService.dart';
import 'package:dio/dio.dart';
import 'package:fluro/fluro.dart';
import 'package:book/common/local_store.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'common/Http.dart';
import 'common/common.dart';
import 'entity/ParseContentConfig.dart';

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
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    getConfigFromServer();
    String version = packageInfo.version;
    SpUtil.putString("version", version);
    if (Platform.isAndroid) {
      SystemUiOverlayStyle systemUiOverlayStyle =
          SystemUiOverlayStyle(statusBarColor: Colors.transparent);
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }
  }

  static getConfigFromServer() async {
    Response res = await HttpUtil.instance.dio.get(Common.config);
    var d = await parseJson(res.data['data']);

    List rules = d['rules'];
    Map fonts = d['fonts'];

    List<ParseContentConfig> configs =
        rules.map((e) => ParseContentConfig.fromJson(e)).toList();
    SpUtil.putObjectList(Common.parse_html_config, configs);
    SpUtil.putObject(Common.fonts, fonts);
  }

  static bool loginState() {
    return SpUtil.haveKey("token");
  }
}
