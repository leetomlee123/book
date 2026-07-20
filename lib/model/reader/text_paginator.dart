import 'package:book/common/text_composition.dart';
import 'package:book/entity/read_page.dart';
import 'package:book/entity/text_page.dart';

/// 统一分页入口：metrics 采集 + Rust/Dart 分页。
///
/// 从 [TextComposition] 静态 API 薄封装，便于 ReadModel 与测试注入。
class TextPaginator {
  const TextPaginator();

  Future<List<TextPage>> paginate(
    ReadPage readPage, {
    bool shouldJustifyHeight = true,
  }) {
    return TextComposition.parseContentAsync(
      readPage,
      shouldJustifyHeight: shouldJustifyHeight,
    );
  }

  List<TextPage> paginateSync(
    ReadPage readPage, {
    bool shouldJustifyHeight = true,
  }) {
    return TextComposition.parseContent(
      readPage,
      shouldJustifyHeight: shouldJustifyHeight,
    );
  }

  Map<String, dynamic> layoutParams({bool shouldJustifyHeight = true}) {
    return TextComposition.layoutParams(
      shouldJustifyHeight: shouldJustifyHeight,
    );
  }

  /// Stable layout fingerprint for page-cache invalidation.
  ///
  /// Box sizes are rounded to integers to avoid thrashing on minor system-UI
  /// height jitter; font metrics keep one decimal place.
  String layoutFingerprint({
    required Map<String, dynamic> layoutParams,
    required int contentLen,
    String contentSig = '',
  }) {
    String n(Object? v, {int decimals = 0}) {
      final d = (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0;
      if (decimals <= 0) return d.round().toString();
      final f = d.toStringAsFixed(decimals);
      // Trim trailing zeros without locale issues.
      return f.replaceFirst(RegExp(r'\.?0+$'), '');
    }

    final fontSize = n(layoutParams['fontSize'], decimals: 1);
    final lineHeight = n(layoutParams['lineHeight'], decimals: 2);
    final paragraph = n(layoutParams['paragraph'], decimals: 1);
    final padH = n(layoutParams['padH'], decimals: 1);
    final boxW = n(layoutParams['boxW']);
    final boxH = n(layoutParams['boxH']);
    final fontFamily = '${layoutParams['fontFamily'] ?? ''}';
    final fontPath = '${layoutParams['fontPath'] ?? ''}';
    final justify = layoutParams['shouldJustifyHeight'] == true ? '1' : '0';
    return '$fontSize|$lineHeight|$paragraph|$padH|$boxW|$boxH|'
        '$fontFamily|$fontPath|$justify|$contentLen|$contentSig';
  }

  /// Cheap content signature so same-length different bodies don't share cache.
  String contentSignature(String content) {
    if (content.isEmpty) return '0';
    // FNV-1a 32-bit over a sample of head/mid/tail bytes.
    var hash = 0x811c9dc5;
    void mix(int unit) {
      hash ^= unit & 0xff;
      hash = (hash * 0x01000193) & 0xffffffff;
    }

    final len = content.length;
    final step = len <= 256 ? 1 : (len ~/ 128);
    for (var i = 0; i < len; i += step) {
      mix(content.codeUnitAt(i));
    }
    mix(len & 0xff);
    mix((len >> 8) & 0xff);
    mix((len >> 16) & 0xff);
    return hash.toRadixString(16);
  }
}
