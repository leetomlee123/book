import 'package:book/AppInit.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/book/BookShelf.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

GetIt locator = GetIt.instance;
// FirebaseAnalytics analytics = FirebaseAnalytics();
// FirebaseAnalyticsObserver observer =
//     FirebaseAnalyticsObserver(analytics: analytics);
// FirebaseAuth auth = FirebaseAuth.instance;
// GoogleSignIn googleSignIn = GoogleSignIn(
//   scopes: <String>[
//     'email',
//     'https://www.googleapis.com/auth/contacts.readonly',
//   ],
// );
void main() =>
    AppInit.init().then((value) => runApp(Store.init(child: MyApp())));

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Store.connect<ColorModel>(
        builder: (context, ColorModel model, child) {
      return MaterialApp(
        title: '即刻追书',
        home: BookShelf(),
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

// class MainPage extends StatefulWidget {
//   @override
//   _MainPageState createState() => _MainPageState();
// }

// class _MainPageState extends State<MainPage> {
  // int _tabIndex = 0;
  // bool isMovie = false;
  // GlobalKey<SliderMenuContainerState> _key =
  //     new GlobalKey<SliderMenuContainerState>();

  // var _pageController = PageController();
  // List<BottomNavigationBarItem> bottoms = [
  //   BottomNavigationBarItem(
  //     icon: ImageIcon(
  //       AssetImage("images/book_shelf.png"),
  //       size: 27,
  //     ),
  //     label: '书架',
  //   ),
  // BottomNavigationBarItem(
  //   icon: ImageIcon(
  //     AssetImage("images/good.png"),
  //     size: 27,
  //   ),
  //   label: '精选',
  // ),
  // ];

  /*
   * 存储的四个页面，和Fragment一样
   */
  // var _pages = [BookShelf()];

  // var _pages = [BookShelf(), GoodBook(), Video(), YoutubePlayerDemoApp()];

  // var _pages = [Video(), VoiceBook()];
  // initEnv() async {
  //   getConfigFromServer();
  //   // await Store.value<ShelfModel>(context).initShelf();
  //   // await Firebase.initializeApp();
  // }


  // @override
  // void initState() {
  //   var widgetsBinding = WidgetsBinding.instance;
  //   widgetsBinding.addPostFrameCallback((callback) async {});
  //   initEnv();
  //   super.initState();

  //   JPush jpush = new JPush();
  //   jpush.setup(
  //     appKey: "f90562283a6e6bffa036d5dd",
  //     channel: "flutter_channel",
  //     production: true,
  //     debug: false, //是否打印debug日志
  //   );

  //   eventBus.on<CleanEvent>().listen((navEvent) {
  //     BotToast.cleanAll();
  //   });
  //   // _checkUpdate();
  //   // Store.value<ReadModel>(context).getEveryNote();
  // }

  // @override
  // Widget build(BuildContext context) {
  //   return SliderMenuContainer(
  //     sliderMain: Scaffold(
  //       body: PageView.builder(
  //           //要点1
  //           physics: NeverScrollableScrollPhysics(),
  //           //禁止页面左右滑动切换
  //           controller: _pageController,
  //           onPageChanged: _pageChanged,
  //           //回调函数
  //           itemCount: _pages.length,
  //           itemBuilder: (context, index) => _pages[index]),
  //       // bottomNavigationBar: BottomNavigationBar(
  //       //   unselectedItemColor: model.dark ? Colors.white : Colors.black,
  //       //   elevation: 3,
  //       //   items: bottoms,
  //       //   type: BottomNavigationBarType.fixed,
  //       //   currentIndex: _tabIndex,
  //       //   onTap: (index) {
  //       //     _pageController.jumpToPage(index);
  //       //   },
  //       // ),
  //     ),
  //     sliderMenu: Me(),
  //   );
  // }

  // void _pageChanged(int index) {
  //   setState(() {
  //     if (_tabIndex != index) _tabIndex = index;
  //   });
  // }
// }
