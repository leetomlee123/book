import 'dart:convert';
import 'dart:io';

import 'package:book/common/PicWidget.dart';
import 'package:book/common/common.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/service/TelAndSmsService.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/BookShelf.dart';
import 'package:book/view/GoodBook.dart';
import 'package:book/view/Me.dart';
import 'package:book/view/Video.dart';
import 'package:fluro/fluro.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import 'entity/MRecords.dart';

GetIt locator = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SpUtil.getInstance();

  locator.registerSingleton(TelAndSmsService());
  final router = Router();
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

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Store.connect<ColorModel>(
        builder: (context, ColorModel model, child) {
          return MaterialApp(
            title: '清阅',
            home: MainPage(),
            onGenerateRoute: Routes.router.generator,
            theme: model.theme,// 配置route generate
          );
        });

  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _tabIndex = 0;
  bool isMovie = false;
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
          AssetImage("images/video.png"),
        ),
        title: Text(
          '美剧',
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
  var _pages = [BookShelf(), GoodBook(), Video(), Me()];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
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
  }

  @override
  Widget build(BuildContext context) {
    return Store.connect<ColorModel>(
        builder: (context, ColorModel model, child) {
      return Theme(
        child: Scaffold(
          drawer: Drawer(
            child: Theme(
              child: Scaffold(
                body: ListView(children: isMovie ? mList() : pDre()),
                appBar: AppBar(
                  title: Text("观剧记录"),
                  elevation: 0,
                  centerTitle: true,
                  automaticallyImplyLeading: false,
                ),
              ),
              data: model.theme,
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
            unselectedItemColor: model.dark ? Colors.white : Colors.black,
            elevation: 0,
            items: bottoms,
            type: BottomNavigationBarType.fixed,
            currentIndex: _tabIndex,
            onTap: (index) {
              _pageController.jumpToPage(index);
            },
          ),
        ),
        data: model.theme,
      );
    });
  }

  void _pageChanged(int index) {
    setState(() {
      if (_tabIndex != index) _tabIndex = index;
    });
  }

  List<Widget> pDre() {
    List<Widget> wds = [];
    wds.add(Padding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          CircleAvatar(
            radius: 45,
            backgroundImage: AssetImage('images/fu.png'),
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            SpUtil.getString("username") ?? "",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          GestureDetector(
            child: Text(
              SpUtil.haveKey('email') ? "" : '登陆/注册',
            ),
            onTap: () {
              if (!SpUtil.haveKey('email')) {
                Routes.navigateTo(
                  context,
                  Routes.login,
                );
              }
            },
          )
        ],
      ),
      padding: EdgeInsets.only(left: 15),
    ));

    return wds;
  }

  List<Widget> mList() {
    List<Widget> wds = [];
    List<MRecords> mrds = [];
    if (SpUtil.haveKey(Common.movies_record)) {
      List stringList = jsonDecode(SpUtil.getString(Common.movies_record));

      mrds = stringList.map((f) => MRecords.fromJson(f)).toList();
      for (var i = mrds.length - 1; i >= 0; i--) {
        MRecords value = mrds[i];
        wds.add(GestureDetector(
          child: ListTile(
            leading: PicWidget(
              value.cover,
            ),
            title: Text(
              value.name,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(value.cname),
          ),
          onTap: () {
            Routes.navigateTo(context, Routes.lookVideo, params: {
              "id": value.cid,
              "mcids": value.mcids ?? [],
              "cover": value.cover,
              "name": value.name
            });
          },
        ));
        wds.add(Divider());
      }
    }
    if (wds.isEmpty) {
      wds.add(Center(
        child: Text("暂无观看记录"),
      ));
    }
    return wds;
  }
}
