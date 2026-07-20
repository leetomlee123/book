import 'package:json_annotation/json_annotation.dart';

part 'text_line.g.dart';

/// One visual line of chapter text after pagination.
///
/// ABI v3 contract: **semantic layout only**.
/// - [top]/[height] are page-local vertical metrics for stacking lines.
/// - [justify]/[targetWidth] express alignment intent; Flutter's Skia
///   [TextPainter] computes the final letterSpacing at paint time.
/// - Do **not** treat any field as a cosmic-text glyph coordinate.
@JsonSerializable()
class TextLine {
  final String text;

  /// Y offset from the top of this page's content box (not screen chrome).
  double top;

  /// Line box height used for pagination (fontSize * lineHeight).
  final double height;

  /// When true, Flutter should full-justify to [targetWidth] via letterSpacing.
  final bool justify;

  /// Last soft-wrapped line of a paragraph — never full-justify.
  final bool isLastLine;

  /// True when this line ends a `\n` paragraph.
  final bool isParagraphEnd;

  /// Content-column width the line should fill when [justify] is true.
  final double targetWidth;

  /// Optional paint-time cache. Prefer recomputing from [justify]/[targetWidth].
  double? letterSpacing;

  TextLine(
    this.text, {
    this.top = 0,
    this.height = 0,
    this.justify = false,
    this.isLastLine = false,
    this.isParagraphEnd = false,
    this.targetWidth = 0,
    this.letterSpacing,
  });

  /// Convenience for simple message / fallback lines.
  factory TextLine.simple(
    String text, {
    double top = 0,
    double height = 24,
    double targetWidth = 0,
  }) {
    return TextLine(
      text,
      top: top,
      height: height,
      targetWidth: targetWidth,
      isLastLine: true,
      isParagraphEnd: true,
    );
  }

  factory TextLine.fromJson(Map<String, dynamic> json) =>
      _$TextLineFromJson(json);

  Map<String, dynamic> toJson() => _$TextLineToJson(this);

  /// Vertical bottom-justify redistribution (page-level).
  void justifyDy(double offsetDy) {
    top += offsetDy;
  }

  // ---- Backward-compatible aliases (old ABI used dx/dy) ----

  @Deprecated('ABI v3: paint uses paddingLeft, not dx')
  double get dx => 0;

  @Deprecated('ABI v3: use top')
  double get dy => top;

  @Deprecated('ABI v3: use top')
  set dy(double v) => top = v;
}
