import 'package:book/AppInit.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/system/MainShell.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

GetIt locator = GetIt.instance;

void main() =>
    AppInit.init().then((value) => runApp(Store.init(child: MyApp())));

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Store.connect<ColorModel>(
        builder: (context, ColorModel model, child) {
      return MaterialApp(
        title: '即刻追书',
        home: const MainShell(),
        builder: BotToastInit(),
        navigatorObservers: [
          BotToastNavigatorObserver(),
        ],
        onGenerateRoute: Routes.router.generator,
        theme: model.theme,
      );
    });
  }
}
