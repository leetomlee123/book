// GENERATED CODE - DO NOT MODIFY BY HAND
// Hand-maintained to match text_page.dart (ABI v3).

part of 'text_page.dart';

TextPage _$TextPageFromJson(Map<String, dynamic> json) {
  return TextPage(
    (json['lines'] as List<dynamic>?)
            ?.map((e) => TextLine.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <TextLine>[],
    (json['height'] as num?)?.toDouble() ?? 0,
    pageIndex: json['pageIndex'] as int? ??
        json['page_index'] as int? ??
        0,
    charStart: json['charStart'] as int? ??
        json['char_start'] as int? ??
        0,
    charEnd: json['charEnd'] as int? ?? json['char_end'] as int? ?? 0,
  );
}

Map<String, dynamic> _$TextPageToJson(TextPage instance) => <String, dynamic>{
      'lines': instance.lines.map((e) => e.toJson()).toList(),
      'height': instance.height,
      'pageIndex': instance.pageIndex,
      'charStart': instance.charStart,
      'charEnd': instance.charEnd,
    };
