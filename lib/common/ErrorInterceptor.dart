import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioError e, ErrorInterceptorHandler handler) {
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
