import 'package:book/common/app_log.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final url = err.requestOptions.uri.toString();
    AppLog.e('Http', '${err.type.name} $url', error: err.message ?? err.error);

    if (err.type == DioExceptionType.connectionTimeout) {
      // It occurs when url is opened timeout.
      BotToast.showText(text: "连接超时");
    } else if (err.type == DioExceptionType.sendTimeout) {
      // It occurs when url is sent timeout.
      BotToast.showText(text: "请求超时");
    } else if (err.type == DioExceptionType.receiveTimeout) {
      //It occurs when receiving timeout
      BotToast.showText(text: "响应超时");
    } else if (err.type == DioExceptionType.badResponse) {
      // When the server response, but with a incorrect status, such as 404, 503...
      BotToast.showText(text: "出现异常");
    } else if (err.type == DioExceptionType.cancel) {
      // When the request is cancelled, dio will throw a error with this type.
      BotToast.showText(text: "请求取消");
    } else {
      //DEFAULT Default error type, Some other Error. In this case, you can read the DioException.error if it is not null.
      BotToast.showText(text: "未知错误");
    }
    handler.next(err);
  }
}
