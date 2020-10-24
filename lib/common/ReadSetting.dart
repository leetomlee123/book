import 'package:flustars/flustars.dart';

class ReadSetting {
  static String fontSizeKey = "FONT_SIZE";
  static String latterHeight = "LATTER_HEIGHT";
  static String latterSpace = "LATTER_SPACE";
  static String poet = '世人为荣利缠缚，动曰尘世苦海，不知云白山青，川行石立，花迎鸟笑，谷答樵讴，世亦不尘、海亦不苦、彼自尘苦其心尔';

  static double getFontSize() {
    return SpUtil.getDouble(fontSizeKey, defValue: 30);
  }

  static double getLatterHeight() {
    return SpUtil.getDouble(latterHeight, defValue: 30);
  }

  static double getLatterSpace() {
    return SpUtil.getDouble(latterSpace, defValue: 10);
  }

  static void setFontSize(double fontSize) {
    SpUtil.putDouble(fontSizeKey, fontSize);
  }

  static void calcFontSize(double size) {
    setFontSize(getFontSize() + size);
  }
}
