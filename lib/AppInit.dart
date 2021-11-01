import 'dart:io';

import 'package:book/main.dart';
import 'package:book/route/Routes.dart';
import 'package:book/service/TelAndSmsService.dart';
import 'package:dio/dio.dart';
import 'package:fluro/fluro.dart';
import 'package:flustars/flustars.dart';
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
      if (!await Permission.storage.request().isGranted) {
        return;
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
}
