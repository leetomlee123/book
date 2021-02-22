import 'package:book/model/ColorModel.dart';
import 'package:book/model/MovieModel.dart';
import 'package:book/model/ReadModel.dart';
import 'package:book/model/SearchModel.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/model/VoiceModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Store {
  static BuildContext context;
  static BuildContext widgetCtx;

  //  我们将会在main.dart中runAPP实例化init
  static init({context, child}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SearchModel()),
        ChangeNotifierProvider(create: (_) => ColorModel()),
        ChangeNotifierProvider(create: (_) => ShelfModel()),
        ChangeNotifierProvider(create: (_) => ReadModel()),
        ChangeNotifierProvider(create: (_) => MovieModel()),
        ChangeNotifierProvider(create: (_) => VoiceModel()),
      ],
      child: child,
    );
  }

  //  通过Provider.value<T>(context)获取状态数据
  static T value<T>(context) {
    return Provider.of(context, listen: false);
  }

  //  通过Consumer获取状态数据
  static Consumer connect<T>({builder, child}) {
    return Consumer<T>(builder: builder, child: child);
  }
}
