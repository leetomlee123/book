import 'package:book/app_init.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/providers.dart';
import 'package:book/view/system/MainShell.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

GetIt locator = GetIt.instance;

void main() => AppInit.init().then(
      (value) => runApp(const ProviderScope(child: MyApp())),
    );

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Cold-start: register the saved reader font with FontLoader + resolve path.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(colorModelProvider).ensureCurrentFontLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(colorModelProvider);
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
  }
}
