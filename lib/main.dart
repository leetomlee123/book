import 'dart:async';
import 'dart:io';

import 'package:book/event/event.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/ReadModel.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/model/VoiceModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/service/TelAndSmsService.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/book/BookShelf.dart';
import 'package:book/view/book/GoodBook.dart';
import 'package:book/view/movie/MovieRecord.dart';
import 'package:book/view/movie/Video.dart';
import 'package:book/view/person/Me.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fluro/fluro.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';

GetIt locator = GetIt.instance;
FirebaseAnalytics analytics = FirebaseAnalytics();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (await Permission.storage.request().isGranted) {
    await SpUtil.getInstance();
    // await Firebase.initializeApp();
    locator.registerSingleton(TelAndSmsService());
    final router = FluroRouter();
    Routes.configureRoutes(router);
    Routes.router = router;
    runApp(Store.init(child: MyApp()));
    await DirectoryUtil.getInstance();

    if (Platform.isAndroid) {
      SystemUiOverlayStyle systemUiOverlayStyle =
          SystemUiOverlayStyle(statusBarColor: Colors.transparent);
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Store.connect<ColorModel>(
        builder: (context, ColorModel model, child) {
      return MaterialApp(
        title: '清阅',
        home: MainPage(),
        builder: BotToastInit(),
        //
        navigatorObservers: [
          BotToastNavigatorObserver(),
          FirebaseAnalyticsObserver(analytics: analytics),
        ],
        onGenerateRoute: Routes.router.generator,
        theme: model.theme, // 配置route generate
      );
    });
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  int _tabIndex = 0;
  bool isMovie = false;
  static final GlobalKey<ScaffoldState> q = new GlobalKey();

  // Future<void> _checkUpdate() async {
  //   if (Platform.isAndroid) {
  //     FlutterBugly.checkUpgrade(isManual: false, isSilence: true);
  //     var info = await FlutterBugly.getUpgradeInfo();
  //     print("get info $info ");
  //     if (info != null && info.id != null) {
  //       await showDialog(
  //         barrierDismissible: false,
  //         context: context,
  //         builder: (_) => UpdateDialog(info?.versionName ?? '',
  //             info?.newFeature ?? '', info?.apkUrl ?? ''),
  //       );
  //     }
  //   }
  // }

  /// 跳转应用市场升级
  // _launchURL(url) async {
  //   if (await canLaunch(url)) {
  //     await launch(url);
  //   } else {
  //     throw 'Could not launch $url';
  //   }
  // }

  var _pageController = PageController();
  List<BottomNavigationBarItem> bottoms = [
    BottomNavigationBarItem(
      icon: ImageIcon(
        AssetImage("images/book_shelf.png"),
        size: 30,
      ),
      label: '书架',
    ),
    BottomNavigationBarItem(
      icon: ImageIcon(
        AssetImage("images/good.png"),
        size: 30,
      ),
      label: '精选',
    ),
    BottomNavigationBarItem(
      icon: ImageIcon(
        AssetImage("images/video.png"),
        size: 30,
      ),
      label: '美剧',
    ),
    // BottomNavigationBarItem(
    //   icon: ImageIcon(
    //     AssetImage("images/listen.png"),
    //     size: 30,
    //   ),
    //   label: '听书',
    // ),
  ];

  // imgIcon(String src, String title) {
  //   return BottomNavigationBarItem(
  //     icon: ImageIcon(
  //       AssetImage(src),
  //       size: 30,
  //     ),
  //     label: title,
  //   );
  // }

  /*
   * 存储的四个页面，和Fragment一样
   */
  var _pages = [BookShelf(), GoodBook(), Video()];

  // var _pages = [Video(), VoiceBook()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    eventBus.on<OpenEvent>().listen((openEvent) {
      if (openEvent.name == "m") {
        isMovie = true;
      } else {
        isMovie = false;
      }
      if (mounted) {
        setState(() {});
      }
      q.currentState.openDrawer();
    });
    eventBus.on<NavEvent>().listen((navEvent) {
      _pageController.jumpToPage(navEvent.idx);
    });
    // _checkUpdate();
    Store.value<ReadModel>(context).getEveryNote();
  }

  @override
  Widget build(BuildContext context) {
    return Store.connect<ColorModel>(
        builder: (context, ColorModel model, child) {
      return Theme(
        child: Store.connect<ShelfModel>(
            builder: (context, ShelfModel shelfModel, child) {
          return Scaffold(
            drawer: Drawer(
              child: isMovie ? MovieRecord() : Me(),
            ),
            key: q,
            body: PageView.builder(
                //要点1
                physics: NeverScrollableScrollPhysics(),
                //禁止页面左右滑动切换
                controller: _pageController,
                onPageChanged: _pageChanged,
                //回调函数
                itemCount: _pages.length,
                itemBuilder: (context, index) => _pages[index]),
            bottomNavigationBar: BottomNavigationBar(
              unselectedItemColor: model.dark ? Colors.white : Colors.black,
              elevation: 3,
              items: bottoms,
              type: BottomNavigationBarType.fixed,
              currentIndex: _tabIndex,
              onTap: (index) {
                _pageController.jumpToPage(index);
              },
            ),
          );
        }),
        data: model.theme,
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    Store.value<VoiceModel>(context).saveHis();
  }

  void _pageChanged(int index) {
    setState(() {
      if (_tabIndex != index) _tabIndex = index;
    });
  }
}
