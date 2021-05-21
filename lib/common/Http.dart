import 'dart:convert';

import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'LoadDialog.dart';

class HttpUtil {
  static Dio _dio;
  final bool showLoading;

  HttpUtil({this.showLoading = false});

  Dio http() {
    _dio = new Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        // Do something before request is sent
        if (showLoading) {
          BotToast.showCustomLoading(
              toastBuilder: (_) => LoadingDialog(),
              backgroundColor: Colors.transparent);
        }
        if (SpUtil.haveKey("auth")) {
          options.headers.addAll(({"auth": SpUtil.getString("auth")}));
        }
        return handler.next(options); //continue
        // If you want to resolve the request with some custom data，
        // you can resolve a `Response` object eg: `handler.resolve(response)`.
        // If you want to reject the request with a error message,
        // you can reject a `DioError` object eg: `handler.reject(dioError)`
      }, onResponse: (response, handler) {
        // Do something with response data
        if (showLoading) {
          BotToast.closeAllLoading();
        }
        return handler.next(response); // continue
        // If you want to reject the request with a error message,
        // you can reject a `DioError` object eg: `handler.reject(dioError)`
      }, onError: (DioError e, handler) {
        // Do something with response error
        if (showLoading) {
          BotToast.closeAllLoading();
        }
        formatError(e);
        return handler.next(e); //continue
        // If you want to resolve the request with some custom data，
        // you can resolve a `Response` object eg: `handler.resolve(response)`.
      }));
    return _dio;
  }

  /*
   * error统一处理
   */
  void formatError(DioError e) {
    if (showLoading) {
      BotToast.closeAllLoading();
    }
    if (e.type == DioErrorType.connectTimeout) {
      // It occurs when url is opened timeout.
      BotToast.showText(text: "连接超时");
    } else if (e.type == DioErrorType.sendTimeout) {
      // It occurs when url is sent timeout.
      BotToast.showText(text: "请求超时");
    } else if (e.type == DioErrorType.receiveTimeout) {
      //It occurs when receiving timeout
      BotToast.showText(text: "响应超时");
    } else if (e.type == DioErrorType.response) {
      // When the server response, but with a incorrect status, such as 404, 503...
      BotToast.showText(text: "出现异常");
    } else if (e.type == DioErrorType.cancel) {
      // When the request is cancelled, dio will throw a error with this type.
      BotToast.showText(text: "请求取消");
    } else {
      //DEFAULT Default error type, Some other Error. In this case, you can read the DioError.error if it is not null.
//      log(e.message);
      BotToast.showText(text: "未知错误");
    }
  }
}

// 必须是顶层函数
_parseAndDecode(String response) {
  return jsonDecode(response);
}

parseJson(String text) {
  return compute(_parseAndDecode, text);
}
