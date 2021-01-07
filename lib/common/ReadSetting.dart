import 'package:flustars/flustars.dart';

class ReadSetting {
  static String fontSizeKey = "FONT_SIZE";
  static String latterHeight = "LINE_HEIGHT";
  static String latterLead = "LATTER_LEAD";
  static String latterSpace = "LATTER_SPACE";
  static String poet = '世人为荣利缠缚，动曰尘世苦海，不知云白山青，川行石立，花迎鸟笑，谷答樵讴，世亦不尘、海亦不苦、彼自尘苦其心尔';

  static double getFontSize() {
    return SpUtil.getDouble(fontSizeKey, defValue: 26);
  }

  static double getLineHeight() {
    return SpUtil.getDouble(latterHeight, defValue: 1.6);
  }

  static void setLineHeight(double lineHeight) {
    
    SpUtil.putDouble(latterHeight,  lineHeight);
  }

  static double getLatterSpace() {
    return SpUtil.getDouble(latterSpace, defValue: 1.0);
  }

  static double getLatterLead() {
    return SpUtil.getDouble(latterLead, defValue: 1);
  }

  static void setFontSize(double fontSize) {
    SpUtil.putDouble(fontSizeKey, fontSize);
  }

  static void calcFontSize(double size) {
    setFontSize(getFontSize() + size);
  }
}
