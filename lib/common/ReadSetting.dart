import 'package:book/common/Screen.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';

class ReadSetting {
  static List<String> bgImg = [
    "QR_bg_1.jpg",
    "QR_bg_2.jpg",
    "QR_bg_3.jpg",
    "QR_bg_5.jpg",
    "QR_bg_7.png",
    "QR_bg_8.png",
    "QR_bg_4.jpg",
  ];
  static String bgsKey = "BGSKEY";
  static String fontSizeKey = "FONT_SIZE";
  static String latterHeight = "LINE_HEIGHT";
  static String latterLead = "LATTER_LEAD";
  static String latterSpace = "LATTER_SPACE";
  static String paragraph = "paragraph";
  static String pageDis = "pageDis";

  static double listPageChapterName = 200;
  static double listPageBottom = Screen.height / 2;
  static String temp_w = "temp_w";
  static String temp_h = "temp_h";
  static Color textLowColor =
      SpUtil.getBool("dark") ? Colors.white10 : Colors.grey.shade50;

  static String poet = '世人为荣利缠缚，动曰尘世苦海，不知云白山青，川行石立，花迎鸟笑，谷答樵讴，世亦不尘、海亦不苦、彼自尘苦其心尔';
  static String lawWarn =
      '''鉴于本服务以非人工检索方式提供无线搜索、根据您输入的关键字自动生成到第三方网页的链接，本服务会提供与其他任何互联网网站或资源的链接。由于清阅小说无法控制这些网站或资源的内容，您了解并同意：无论此类网站或资源是否可供利用，清阅小说不予负责；清阅小说亦对存在或源于此类网站或资源之任何内容、广告、产品或其他资料不予保证或负责。因您使用或依赖任何此类网站或资源发布的或经由此类网站或资源获得的任何内容、商品或服务所产生的任何损害或损失，清阅小说不负任何直接或间接责任。

因本服务搜索结果根据您键入的关键字自动搜索获得并生成，不代表清阅小说赞成被搜索链接到的第三方网页上的内容或立场。

任何通过使用本服务而搜索链接到的第三方网页均系第三方提供或制作，您可能从该第三方网页上获得资讯及享用服务，清阅小说无法对其合法性负责，亦不承担任何法律责任。

您应对使用无线搜索引擎的结果自行承担风险。清阅小说不做任何形式的保证：不保证搜索结果满足您的要求，不保证搜索服务不中断，不保证搜索结果的安全性、准确性、及时性、合法性。因网络状况、通讯故障、第三方网站等任何原因而导致您不能正常使用本服务的，清阅小说不承担任何法律责任。

您应该了解并知晓，清阅小说作为移动互联网的先行者，拥有先进的无线数据应用技术和智能搜索系统，为手机等无线端用户提供了移动互联网的最佳搜索体验。清阅小说使用行业内成熟的搜索引擎技术，同时充分考虑用户手机端上网特征，由于电脑端网页的复杂、多样与标准的不同，用户无法通过手机正常浏览电脑端网页，为了提供更好的用户体验，用户在搜索点击后，我们网页会提供转码，这就是网页实时转换技术，将页面转换为适于手机用户访问的页面，从而为用户提供可用、高效的搜索服务。由于搜索引擎对数据即时性和客观性的要求，和复杂的数据变更以及本身的技术问题，在转码的过程中可能会出现原网站的部门数据异常而导致部分数据错误，若您想获取完整的原网站完整有效的内容，您应选择去原网站浏览，介于此类技术问题，清阅小说一直在不断的完善搜索技术，以提高数据的准确性。

您使用本服务即视为您已阅读并同意受本声明内容的相关约束。清阅小说有权在根据具体情况进行修改本声明条款。对此，我们不会有专门通知，但，您可以在相关页面中查阅最新的条款。条款变更后，如果您继续使用本服务，即视为您已接受修改后的条款。如果您不接受，应当停止使用本服务。

本声明内容同时包括《清阅小说软件服务协议》，《版权保护投诉指引》及清阅小说可能不断发布本服务的相关声明、协议、业务规则等内容。上述内容一经正式发布，即为本声明不可分割的组成部分，您同样应当遵守。上述内容与本声明内容存在冲突的，以本声明为准。您对前述任何业务规则、声明内容的接受，即视为您对本声明内容全部的接受。

本声明的成立、生效、履行、解释及纠纷解决，适用中华人民共和国大陆地区法律（不包括冲突法）。

若您和清阅小说之间发生任何纠纷或争议，首先应友好协商解决；协商不成的，您同意将纠纷或争议提交清阅小说所在地的人民法院处理。''';

  static double getFontSize() {
    return SpUtil.getDouble(fontSizeKey, defValue: 26);
  }

  static double getLineHeight() {
    return SpUtil.getDouble(latterHeight, defValue: 1.8);
  }

  static void setLineHeight(double lineHeight) {
    SpUtil.putDouble(latterHeight, lineHeight);
  }

  static void addLineHeight() {
    SpUtil.putDouble(latterHeight, getLineHeight() + .1);
  }

  static void subLineHeight() {
    SpUtil.putDouble(latterHeight, getLineHeight() - .1);
  }

  static void addLatterSpace() {
    SpUtil.putDouble(latterSpace, getLatterSpace() + 1);
  }

  static void subLatterSpace() {
    SpUtil.putDouble(latterSpace, getLatterSpace() - 1);
  }

  static double getLatterSpace() {
    return SpUtil.getDouble(latterSpace, defValue: 3.0);
  }

  static void setLatterSpace(double v) {
    SpUtil.putDouble(latterSpace, v);
  }

  static void addParagraph() {
    SpUtil.putDouble(paragraph, getParagraph() + .1);
  }

  static void subParagraph() {
    SpUtil.putDouble(paragraph, getParagraph() - .1);
  }

  static double getParagraph() {
    return SpUtil.getDouble(paragraph, defValue: .8);
  }

  static void setParagraph(double v) {
    SpUtil.putDouble(paragraph, v);
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

  static void setPageDis(int s) {
    SpUtil.putInt(pageDis, s);
  }

  static int getPageDis() {
    return SpUtil.getInt(pageDis, defValue: 20);
  }

  static void calcPageDis(int s) {
    SpUtil.putInt(pageDis, getPageDis() + s);
  }

  static double getTempH() {
    return SpUtil.getDouble(temp_h, defValue: 0);
  }

  static void setTempH(double h) {
    SpUtil.putDouble(temp_h, h);
  }

  static double getTempW() {
    return SpUtil.getDouble(temp_w, defValue: 0);
  }

  static void setTempW(double w) {
    SpUtil.putDouble(temp_w, w);
  }
}
