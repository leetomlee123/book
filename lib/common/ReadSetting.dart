import 'package:flustars/flustars.dart';

class ReadSetting {
  static String fontSizeKey = "FONT_SIZE";
  static String latterHeight = "LATTER_HEIGHT";
  static String latterSpace = "LATTER_SPACE";

  static double getFontSize() {
    return SpUtil.getDouble(fontSizeKey, defValue: 32.0);
  }

  static double getLatterHeight() {
    return SpUtil.getDouble(latterHeight, defValue: 1.5);
  }

  static double getLatterSpace() {
    return SpUtil.getDouble(latterSpace, defValue: 1.25);
  }

  static void setFontSize(double fontSize) {
    SpUtil.putDouble(fontSizeKey, fontSize);
  }

  static void calcFontSize(double size) {
    setFontSize(getFontSize() + size);
  }
}
