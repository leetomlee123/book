import 'dart:convert';

import 'package:book/common/AuthInterceptor.dart';
import 'package:book/common/ErrorInterceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class HttpUtil {
  // 工厂模式
  factory HttpUtil() => _getInstance();

  static HttpUtil get instance => _getInstance();
  static HttpUtil? _instance;
  late Dio dio;
  late BaseOptions options;

  HttpUtil._internal() {
    dio = Dio()
      ..options = BaseOptions(
          // baseUrl: Common.domain,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(hours: 24))

      //网络状态拦截
      ..interceptors.add(AuthInterceptor())
      // ..interceptors.add(HttpLog())
      ..interceptors.add(ErrorInterceptor());
  }

  static HttpUtil _getInstance() {
    return _instance ??= HttpUtil._internal();
  }
}

// 必须是顶层函数
dynamic _parseAndDecode(String response) {
  return jsonDecode(response);
}

Future<dynamic> parseJson(String text) {
  return compute(_parseAndDecode, text);
}
