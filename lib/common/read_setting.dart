import 'package:book/common/screen.dart';
import 'package:book/common/app_colors.dart';
import 'package:book/common/common.dart';
import 'package:book/common/local_store.dart';
import 'package:flutter/material.dart';

/// Solid paper theme for the reader canvas (WeChat Reading style).
enum PaperTheme { white, cream, green, night }

class ReadSetting {
  /// Legacy texture backgrounds (optional advanced skins).
  static List<String> bgImg = [
    "QR_bg_1.jpg",
    "QR_bg_2.jpg",
    "QR_bg_3.jpg",
    "QR_bg_5.jpg",
    "QR_bg_7.png",
    "QR_bg_8.png",
    "QR_bg_4.jpg",
  ];

  static bool isDark() => SpUtil.getBool(PrefsKeys.dark);
  static String bgsKey = "BGSKEY";
  static String fontSizeKey = "FONT_SIZE";
  static String latterHeight = "LINE_HEIGHT";
  static String latterLead = "LATTER_LEAD";
  static String latterSpace = "LATTER_SPACE";
  static String paragraph = "paragraph";
  static String pageDis = "pageDis";
  static String paperKey = "paper_theme";
  static String useSolidPaperKey = "use_solid_paper";
  static String fontMigratedKey = "font_size_migrated_v19";
  static String fontNameKey = "fontName";
  static String fontPathKey = "fontPath";

  /// Product solid papers (preferred over texture images).
  static const List<PaperTheme> solidPapers = [
    PaperTheme.white,
    PaperTheme.cream,
    PaperTheme.green,
    PaperTheme.night,
  ];

  static String paperLabel(PaperTheme t) {
    switch (t) {
      case PaperTheme.white:
        return '白';
      case PaperTheme.cream:
        return '米';
      case PaperTheme.green:
        return '绿';
      case PaperTheme.night:
        return '夜';
    }
  }

  static Color paperColor(PaperTheme t) {
    switch (t) {
      case PaperTheme.white:
        return AppColors.paperWhite;
      case PaperTheme.cream:
        return AppColors.paperCream;
      case PaperTheme.green:
        return AppColors.paperGreen;
      case PaperTheme.night:
        return AppColors.paperNight;
    }
  }

  static Color inkColor(PaperTheme t) {
    switch (t) {
      case PaperTheme.white:
      case PaperTheme.cream:
        return AppColors.inkOnLight;
      case PaperTheme.green:
        return AppColors.inkOnGreen;
      case PaperTheme.night:
        return AppColors.inkOnNight;
    }
  }

  static Color metaColor(PaperTheme t) {
    switch (t) {
      case PaperTheme.night:
        return const Color(0x66FFFFFF);
      case PaperTheme.green:
        return AppColors.inkOnGreen.withValues(alpha: 0.55);
      default:
        return AppColors.textSecondary;
    }
  }

  static PaperTheme getPaperTheme() {
    final name = SpUtil.getString(paperKey, defValue: 'cream');
    return PaperTheme.values.firstWhere(
      (e) => e.name == name,
      orElse: () => PaperTheme.cream,
    );
  }

  static void setPaperTheme(PaperTheme t) {
    SpUtil.putString(paperKey, t.name);
    // Keep global dark flag aligned with night paper.
    if (t == PaperTheme.night) {
      SpUtil.putBool(PrefsKeys.dark, true);
    } else if (SpUtil.getBool(PrefsKeys.dark) && t != PaperTheme.night) {
      // Leaving night paper turns off global dark for reader consistency.
      SpUtil.putBool(PrefsKeys.dark, false);
    }
  }

  /// Prefer solid paper fill over legacy texture images.
  static bool useSolidPaper() =>
      SpUtil.getBool(useSolidPaperKey, defValue: true);

  static void setUseSolidPaper(bool v) => SpUtil.putBool(useSolidPaperKey, v);

  /// One-shot: old default 26 → calm 19.
  static void migrateFontDefaultsIfNeeded() {
    if (SpUtil.getBool(fontMigratedKey, defValue: false)) return;
    final stored = SpUtil.getDouble(fontSizeKey, defValue: 26);
    if (stored == 26) {
      SpUtil.putDouble(fontSizeKey, 19);
    }
    final lh = SpUtil.getDouble(latterHeight, defValue: 1.8);
    if (lh == 1.8) {
      SpUtil.putDouble(latterHeight, 1.7);
    }
    SpUtil.putBool(fontMigratedKey, true);
  }

  static double listPageChapterName = 200;
  static double listPageBottom = Screen.height / 2;
  static String temp_w = "temp_w";
  static String temp_h = "temp_h";
  static Color textLowColor =
      SpUtil.getBool(PrefsKeys.dark) ? Colors.white10 : Colors.grey.shade50;

  static String poet =
      '爱看书是一款开源的网络小说阅读器，支持本地书源、书架管理与多种翻页方式。阅读进度与书架数据保存在本机。';
  static String lawWarn =
      '''书源由用户自行导入，仅供学习交流。请勿导入或使用侵犯他人版权的书源。由此产生的法律责任由用户自行承担。应用不附带、不自动下载任何第三方书源列表。

鉴于本服务以非人工检索方式提供无线搜索、根据您输入的关键字自动生成到第三方网页的链接，本服务会提供与其他任何互联网网站或资源的链接。由于爱看书无法控制这些网站或资源的内容，您了解并同意：无论此类网站或资源是否可供利用，爱看书不予负责；爱看书亦对存在或源于此类网站或资源之任何内容、广告、产品或其他资料不予保证或负责。因您使用或依赖任何此类网站或资源发布的或经由此类网站或资源获得的任何内容、商品或服务所产生的任何损害或损失，爱看书不负任何直接或间接责任。

因本服务搜索结果根据您键入的关键字自动搜索获得并生成，不代表爱看书赞成被搜索链接到的第三方网页上的内容或立场。

任何通过使用本服务而搜索链接到的第三方网页均系第三方提供或制作，您可能从该第三方网页上获得资讯及享用服务，爱看书无法对其合法性负责，亦不承担任何法律责任。

您应对使用无线搜索引擎的结果自行承担风险。爱看书不做任何形式的保证：不保证搜索结果满足您的要求，不保证搜索服务不中断，不保证搜索结果的安全性、准确性、及时性、合法性。因网络状况、通讯故障、第三方网站等任何原因而导致您不能正常使用本服务的，爱看书不承担任何法律责任。

您应该了解并知晓，爱看书作为移动互联网的先行者，拥有先进的无线数据应用技术和智能搜索系统，为手机等无线端用户提供了移动互联网的最佳搜索体验。爱看书使用行业内成熟的搜索引擎技术，同时充分考虑用户手机端上网特征，由于电脑端网页的复杂、多样与标准的不同，用户无法通过手机正常浏览电脑端网页，为了提供更好的用户体验，用户在搜索点击后，我们网页会提供转码，这就是网页实时转换技术，将页面转换为适于手机用户访问的页面，从而为用户提供可用、高效的搜索服务。由于搜索引擎对数据即时性和客观性的要求，和复杂的数据变更以及本身的技术问题，在转码的过程中可能会出现原网站的部门数据异常而导致部分数据错误，若您想获取完整的原网站完整有效的内容，您应选择去原网站浏览，介于此类技术问题，爱看书一直在不断的完善搜索技术，以提高数据的准确性。

您使用本服务即视为您已阅读并同意受本声明内容的相关约束。爱看书有权在根据具体情况进行修改本声明条款。对此，我们不会有专门通知，但，您可以在相关页面中查阅最新的条款。条款变更后，如果您继续使用本服务，即视为您已接受修改后的条款。如果您不接受，应当停止使用本服务。

本声明内容同时包括《爱看书软件服务协议》，《版权保护投诉指引》及爱看书可能不断发布本服务的相关声明、协议、业务规则等内容。上述内容一经正式发布，即为本声明不可分割的组成部分，您同样应当遵守。上述内容与本声明内容存在冲突的，以本声明为准。您对前述任何业务规则、声明内容的接受，即视为您对本声明内容全部的接受。

本声明的成立、生效、履行、解释及纠纷解决，适用中华人民共和国大陆地区法律（不包括冲突法）。

若您和爱看书之间发生任何纠纷或争议，首先应友好协商解决；协商不成的，您同意将纠纷或争议提交爱看书所在地的人民法院处理。''';

  static double getFontSize() {
    migrateFontDefaultsIfNeeded();
    return SpUtil.getDouble(fontSizeKey, defValue: 19);
  }

  // ---- Font family / path (reader pagination + paint) ----

  /// Bundled CJK face used when the user has not picked a custom font.
  /// Keep in sync with `pubspec.yaml` fonts entry and assets/fonts/*.
  static const String defaultFontFamily = 'HarmonyOSSansSC';
  static const String defaultFontAsset =
      'assets/fonts/HarmonyOS_Sans_SC_Regular.ttf';

  /// Absolute path of the extracted default TTF (filled by bootstrap).
  /// Separate from user-selected [fontPathKey] so switching fonts cannot
  /// permanently hide the bundled face.
  static String _bundledFontPath = '';

  static void setBundledFontPath(String path) {
    _bundledFontPath = path;
  }

  /// Extracted bundled TTF only (may be empty before bootstrap).
  static String get bundledFontPath => _bundledFontPath;

  static String getFontFamily() {
    final name = SpUtil.getString(fontNameKey, defValue: '');
    // Empty / legacy unset → bundled default. Explicit "Roboto" stays Roboto
    // so 设置 → 系统默认 still works.
    if (name.isEmpty) return defaultFontFamily;
    return name;
  }

  static void setFontFamily(String name) {
    SpUtil.putString(
      fontNameKey,
      name.isEmpty ? defaultFontFamily : name,
    );
  }

  /// Path used by Rust book_pager + paint.
  /// 1) User / selected face path in SpUtil when set
  /// 2) Else bundled face when current family is the default
  /// 3) Else empty (Dart/system)
  static String getFontPath() {
    final custom = SpUtil.getString(fontPathKey, defValue: '');
    if (custom.isNotEmpty) return custom;
    final family = getFontFamily();
    if (family == defaultFontFamily || family.isEmpty) {
      return _bundledFontPath;
    }
    return '';
  }

  static void setFontPath(String path) {
    SpUtil.putString(fontPathKey, path);
  }

  /// Clear the selected path (e.g. switching to system Roboto).
  static void clearFontPath() {
    SpUtil.putString(fontPathKey, '');
  }

  /// Page-turn / scroll mode: 0 无动画 / 1 仿真 / 2 覆盖 / 3 滚动.
  /// See [ReaderPageManager] TYPE_* constants.
  static int getPageTurnMode() =>
      SpUtil.getInt(PrefsKeys.pageTurnMode, defValue: 0);

  static void setPageTurnMode(int mode) {
    SpUtil.putInt(PrefsKeys.pageTurnMode, mode.clamp(0, 3));
  }

  static double getLineHeight() {
    migrateFontDefaultsIfNeeded();
    return SpUtil.getDouble(latterHeight, defValue: 1.7);
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

  /// Space reserved above body text: status/safe + chapter title chrome + breathing room.
  /// Must stay in sync with [ReadModel.drawContent] body Y offset.
  static const double contentTopChrome = 52;
  static const double contentTopExtra = 18;

  /// Space reserved below body text: time/progress chrome + breathing room.
  static const double contentBottomChrome = 36;
  static const double contentBottomExtra = 18;

  /// Y where chapter title is painted (below status bar).
  static double chapterTitleOffsetY() {
    return 15 + SpUtil.getDouble(PrefsKeys.topSafeHeight);
  }

  /// Top inset of the paginated content box (and paint offset for body lines).
  static double contentTopInset() {
    return contentTopChrome +
        SpUtil.getDouble(PrefsKeys.topSafeHeight) +
        contentTopExtra;
  }

  /// Bottom inset of the paginated content box.
  static double contentBottomInset() {
    return contentBottomChrome +
        Screen.bottomSafeHeight +
        contentBottomExtra;
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
