import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Screen {
  static MediaQueryData get _mediaQuery =>
      MediaQueryData.fromView(WidgetsBinding.instance.platformDispatcher.views.first);

  static double get width {
    return _mediaQuery.size.width;
  }

  static double get height {
    return _mediaQuery.size.height;
  }

  static double get scale {
    return _mediaQuery.devicePixelRatio;
  }

  static double get textScaleFactor {
    return _mediaQuery.textScaler.scale(1.0);
  }

  static double get navigationBarHeight {
    return _mediaQuery.padding.top + kToolbarHeight;
  }

  static double get topSafeHeight {
    return _mediaQuery.padding.top;
  }

  static double get bottomSafeHeight {
    return _mediaQuery.padding.bottom;
  }

  static updateStatusBarStyle(SystemUiOverlayStyle style) {
    SystemChrome.setSystemUIOverlayStyle(style);
  }
}
