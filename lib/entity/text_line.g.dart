// GENERATED CODE - DO NOT MODIFY BY HAND
// Hand-maintained to match text_line.dart (ABI v3).

part of 'text_line.dart';

TextLine _$TextLineFromJson(Map<String, dynamic> json) {
  // Accept legacy cache rows that only had text/dx/dy/letterSpacing.
  final top = (json['top'] as num?)?.toDouble() ??
      (json['dy'] as num?)?.toDouble() ??
      0.0;
  final height = (json['height'] as num?)?.toDouble() ?? 0.0;
  final targetWidth = (json['targetWidth'] as num?)?.toDouble() ??
      (json['target_width'] as num?)?.toDouble() ??
      0.0;
  return TextLine(
    json['text'] as String? ?? '',
    top: top,
    height: height,
    justify: json['justify'] as bool? ?? false,
    isLastLine: json['isLastLine'] as bool? ??
        json['is_last_line'] as bool? ??
        false,
    isParagraphEnd: json['isParagraphEnd'] as bool? ??
        json['is_paragraph_end'] as bool? ??
        false,
    targetWidth: targetWidth,
    letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ??
        (json['letter_spacing'] as num?)?.toDouble(),
  );
}

Map<String, dynamic> _$TextLineToJson(TextLine instance) => <String, dynamic>{
      'text': instance.text,
      'top': instance.top,
      'height': instance.height,
      'justify': instance.justify,
      'isLastLine': instance.isLastLine,
      'isParagraphEnd': instance.isParagraphEnd,
      'targetWidth': instance.targetWidth,
      if (instance.letterSpacing != null)
        'letterSpacing': instance.letterSpacing,
    };
