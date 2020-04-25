import 'dart:io';

import 'package:book/event/event.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/service/TelAndSmsService.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/BookShelf.dart';
import 'package:book/view/GoodBook.dart';
import 'package:book/view/Me.dart';
import 'package:book/view/PersonCenter.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

GetIt locator = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SpUtil.getInstance();

  locator.registerSingleton(TelAndSmsService());
  runApp(Store.init(child: MyApp()));
  await DirectoryUtil.getInstance();

  if (Platform.isAndroid) {
    SystemUiOverlayStyle systemUiOverlayStyle =
        SystemUiOverlayStyle(statusBarColor: Colors.transparent);
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '清阅',
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _tabIndex = 0;
  static final GlobalKey<ScaffoldState> q = new GlobalKey();
  var _pageController = PageController();
  List<BottomNavigationBarItem> bottoms = [
    BottomNavigationBarItem(
        icon: ImageIcon(
          AssetImage("images/book_shelf.png"),
        ),
        title: Text(
          '书架',
        )),
    BottomNavigationBarItem(
        icon: ImageIcon(
          AssetImage("images/good.png"),
        ),
        title: Text(
          '精选',
        )),
    BottomNavigationBarItem(
        icon: ImageIcon(
          AssetImage("images/account.png"),
        ),
        title: Text(
          '我的',
        )),
  ];

  /*
   * 存储的四个页面，和Fragment一样
   */
  var _pages = [BookShelf(),GoodBook(), Me()];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    eventBus.on<OpenEvent>().listen((_) {
      q.currentState.openDrawer();
    });
  }

  @override
  Widget build(BuildContext context) {
    var value = Store.value<ColorModel>(context);
    return Theme(
      child: Scaffold(
        drawer: Drawer(
          child: Container(
            child: Column(
              children: <Widget>[
                UserAccountsDrawerHeader(
                  accountEmail: Text(
                    SpUtil.haveKey('email')
                        ? SpUtil.getString('email')
                        : '登陆/注册',
                  ),
                  accountName: Text(SpUtil.getString("username") ?? ""),
                  onDetailsPressed: () {
                    if (!SpUtil.haveKey('email')) {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (BuildContext context) => Login()));
                    }
                  },
                  currentAccountPicture: CircleAvatar(
                    backgroundImage: AssetImage('images/fu.png'),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: value.theme.scaffoldBackgroundColor,
                  ),
                )
              ],
            ),
            color: Store.value<ColorModel>(context).theme.primaryColor,
          ),
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
          elevation: 0,
          items: bottoms,
          type: BottomNavigationBarType.fixed,
          currentIndex: _tabIndex,
          onTap: (index) {
            _pageController.jumpToPage(index);
          },
        ),
      ),
      data: value.theme,
    );
  }

  void _pageChanged(int index) {
    setState(() {
      if (_tabIndex != index) _tabIndex = index;
    });
  }
}
