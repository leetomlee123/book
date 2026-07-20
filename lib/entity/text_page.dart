import 'package:book/entity/text_line.dart';
import 'package:json_annotation/json_annotation.dart';

part 'text_page.g.dart';

/// One screen page of composed [TextLine]s (ABI v3).
@JsonSerializable()
class TextPage {
  final List<TextLine> lines;

  /// Content-box height occupied by this page (for scroll tiles).
  final double height;

  /// 0-based page index within the chapter layout.
  final int pageIndex;

  /// UTF-16-ish content range is not used; these are UTF-8 byte offsets from
  /// the native pager (0 when produced by Dart fallback).
  final int charStart;
  final int charEnd;

  const TextPage(
    this.lines,
    this.height, {
    this.pageIndex = 0,
    this.charStart = 0,
    this.charEnd = 0,
  });

  factory TextPage.fromJson(Map<String, dynamic> json) =>
      _$TextPageFromJson(json);

  Map<String, dynamic> toJson() => _$TextPageToJson(this);
}
