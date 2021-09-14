import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (SpUtil.haveKey("auth")) {
      options.headers.addAll(({"auth": SpUtil.getString("auth")}));
    }
    options.headers.addAll(({"user-agent":"Mozilla/5.0 (Linux; Android 11; KB2000) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.131 Mobile Safari/537.36"}));
    return handler.next(options);
  }
}
