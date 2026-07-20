import 'package:book/model/color_model.dart';
import 'package:book/model/explore_model.dart';
import 'package:book/model/read_model.dart';
import 'package:book/model/search_model.dart';
import 'package:book/model/shelf_model.dart';
import 'package:book/model/source_model.dart';
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
