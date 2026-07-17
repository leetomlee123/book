import 'package:book/model/ColorModel.dart';
import 'package:book/model/ExploreModel.dart';
import 'package:book/model/ReadModel.dart';
import 'package:book/model/SearchModel.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/model/SourceModel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global ChangeNotifier-backed providers (Riverpod).
final searchModelProvider =
    ChangeNotifierProvider<SearchModel>((ref) => SearchModel());
final exploreModelProvider =
    ChangeNotifierProvider<ExploreModel>((ref) => ExploreModel());
final colorModelProvider =
    ChangeNotifierProvider<ColorModel>((ref) => ColorModel());
final shelfModelProvider =
    ChangeNotifierProvider<ShelfModel>((ref) => ShelfModel());
final readModelProvider =
    ChangeNotifierProvider<ReadModel>((ref) => ReadModel());
final sourceModelProvider =
    ChangeNotifierProvider<SourceModel>((ref) => SourceModel());
