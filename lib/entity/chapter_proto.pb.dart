///
//  Generated code. Do not modify.
//  source: chapter_proto.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class ChapterProto extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ChapterProto', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'models'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'ChapterName', protoName: 'ChapterName')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'ChapterId', protoName: 'ChapterId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'HasContent', protoName: 'HasContent')
    ..hasRequiredFields = false
  ;

  ChapterProto._() : super();
  factory ChapterProto({
    $core.String? chapterName,
    $core.String? chapterId,
    $core.String? hasContent,
  }) {
    final _result = create();
    if (chapterName != null) {
      _result.chapterName = chapterName;
    }
    if (chapterId != null) {
      _result.chapterId = chapterId;
    }
    if (hasContent != null) {
      _result.hasContent = hasContent;
    }
    return _result;
  }
  factory ChapterProto.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ChapterProto.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ChapterProto clone() => ChapterProto()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ChapterProto copyWith(void Function(ChapterProto) updates) => super.copyWith((message) => updates(message as ChapterProto)) as ChapterProto; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ChapterProto create() => ChapterProto._();
  ChapterProto createEmptyInstance() => create();
  static $pb.PbList<ChapterProto> createRepeated() => $pb.PbList<ChapterProto>();
  @$core.pragma('dart2js:noInline')
  static ChapterProto getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ChapterProto>(create);
  static ChapterProto? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get chapterName => $_getSZ(0);
  @$pb.TagNumber(1)
  set chapterName($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasChapterName() => $_has(0);
  @$pb.TagNumber(1)
  void clearChapterName() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get chapterId => $_getSZ(1);
  @$pb.TagNumber(2)
  set chapterId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasChapterId() => $_has(1);
  @$pb.TagNumber(2)
  void clearChapterId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get hasContent => $_getSZ(2);
  @$pb.TagNumber(3)
  set hasContent($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasHasContent() => $_has(2);
  @$pb.TagNumber(3)
  void clearHasContent() => clearField(3);
}

class Chapters extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Chapters', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'models'), createEmptyInstance: create)
    ..pc<ChapterProto>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'chapters', $pb.PbFieldType.PM, subBuilder: ChapterProto.create)
    ..hasRequiredFields = false
  ;

  Chapters._() : super();
  factory Chapters({
    $core.Iterable<ChapterProto>? chapters,
  }) {
    final _result = create();
    if (chapters != null) {
      _result.chapters.addAll(chapters);
    }
    return _result;
  }
  factory Chapters.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Chapters.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Chapters clone() => Chapters()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Chapters copyWith(void Function(Chapters) updates) => super.copyWith((message) => updates(message as Chapters)) as Chapters; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Chapters create() => Chapters._();
  Chapters createEmptyInstance() => create();
  static $pb.PbList<Chapters> createRepeated() => $pb.PbList<Chapters>();
  @$core.pragma('dart2js:noInline')
  static Chapters getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Chapters>(create);
  static Chapters? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<ChapterProto> get chapters => $_getList(0);
}

