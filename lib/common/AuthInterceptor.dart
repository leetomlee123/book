import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (SpUtil.haveKey("auth")) {
      options.headers.addAll(({"auth": SpUtil.getString("auth")}));
    }
    return handler.next(options);
  }
}
