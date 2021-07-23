import 'dart:convert';

import 'package:book/common/AuthInterceptor.dart';
import 'package:book/common/ErrorInterceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class HttpUtil {
  // 工厂模式
  factory HttpUtil() => _getInstance();

  static HttpUtil get instance => _getInstance();
  static HttpUtil _instance;
  Dio dio;
  BaseOptions options;

  HttpUtil._internal() {
    dio = Dio()
      ..options = BaseOptions(
          // baseUrl: Common.domain,
          connectTimeout: 10000,
          receiveTimeout: 1000 * 60 * 60 * 24)

      //网络状态拦截
      ..interceptors.add(AuthInterceptor())
      // ..interceptors.add(HttpLog())
      ..interceptors.add(ErrorInterceptor());
  }

  static HttpUtil _getInstance() {
    if (_instance == null) {
      _instance = new HttpUtil._internal();
    }
    return _instance;
  }
}

// 必须是顶层函数
_parseAndDecode(String response) {
  return jsonDecode(response);
}

parseJson(String text) {
  return compute(_parseAndDecode, text);
}
