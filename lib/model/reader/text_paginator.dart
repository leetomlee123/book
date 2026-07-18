import 'package:book/common/text_composition.dart';
import 'package:book/entity/ReadPage.dart';
import 'package:book/entity/TextPage.dart';

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
}
