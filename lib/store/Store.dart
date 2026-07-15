import 'package:book/model/ColorModel.dart';
import 'package:book/model/ReadModel.dart';
import 'package:book/model/SearchModel.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/model/SourceModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global ChangeNotifier-backed providers (Riverpod).
final searchModelProvider =
    ChangeNotifierProvider<SearchModel>((ref) => SearchModel());
final colorModelProvider =
    ChangeNotifierProvider<ColorModel>((ref) => ColorModel());
final shelfModelProvider =
    ChangeNotifierProvider<ShelfModel>((ref) => ShelfModel());
final readModelProvider =
    ChangeNotifierProvider<ReadModel>((ref) => ReadModel());
final sourceModelProvider =
    ChangeNotifierProvider<SourceModel>((ref) => SourceModel());

/// Thin facade kept for existing call sites (`Store.value` / `Store.connect`).
class Store {
  static BuildContext? context;
  static BuildContext? widgetCtx;

  /// Root wrapper — was MultiProvider, now [ProviderScope].
  static Widget init({context, child}) {
    return ProviderScope(child: child);
  }

  /// Non-listening read (was `Provider.of(context, listen: false)`).
  static T value<T>(BuildContext context) {
    final container = ProviderScope.containerOf(context);
    return container.read(_listenable<T>());
  }

  /// Listening rebuild (was `Consumer<T>`).
  static Widget connect<T>({
    required Widget Function(BuildContext, T, Widget?) builder,
    Widget? child,
  }) {
    return Consumer(
      builder: (context, ref, child) {
        final model = ref.watch(_listenable<T>());
        return builder(context, model, child);
      },
      child: child,
    );
  }

  static ProviderListenable<T> _listenable<T>() {
    if (T == SearchModel) {
      return searchModelProvider as ProviderListenable<T>;
    }
    if (T == ColorModel) {
      return colorModelProvider as ProviderListenable<T>;
    }
    if (T == ShelfModel) {
      return shelfModelProvider as ProviderListenable<T>;
    }
    if (T == ReadModel) {
      return readModelProvider as ProviderListenable<T>;
    }
    if (T == SourceModel) {
      return sourceModelProvider as ProviderListenable<T>;
    }
    throw ArgumentError('No Riverpod provider registered for type $T');
  }
}
