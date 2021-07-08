import 'package:book/common/Http.dart';
import 'package:book/common/ReadSetting.dart';
import 'package:book/common/Screen.dart';
import 'package:book/common/common.dart';
import 'package:book/entity/Update.dart';
import 'package:book/event/event.dart';
import 'package:book/main.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/service/TelAndSmsService.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/person/InfoPage.dart';
import 'package:book/view/person/Skin.dart';
import 'package:book/view/system/UpdateDialog.dart';
import 'package:book/view/system/white_area.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';

class Me extends StatelessWidget {
  Widget getItem(imageIcon, text, func, Color c) {
    return ListTile(
      onTap: func,
      leading: imageIcon,
      title: Text(text),
    );
  }

  PreferredSizeWidget _appBar(BuildContext context) {
    if (SpUtil.haveKey("username")) {
      return PreferredSize(
          preferredSize: Size.fromHeight(150),
          child: Store.connect<ColorModel>(
              builder: (context, ColorModel model, child) {
            return UserAccountsDrawerHeader(
              margin: EdgeInsets.all(0),
              accountEmail: Text(
                SpUtil.getString('email') ?? "",
                style:
                    TextStyle(color: model.dark ? Colors.white : Colors.black),
              ),
              accountName: Text(
                SpUtil.getString('username') ?? "",
                style:
                    TextStyle(color: model.dark ? Colors.white : Colors.black),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundImage: AssetImage("images/fu.png"),
              ),
              otherAccountsPictures: [
                // CircleAvatar(
                //   backgroundImage: AssetImage("images/vip.png"),
                // )
              ],
              decoration: BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage(
                        "images/a0${model.dark ? 'r' : 's'}.png",
                      ),
                      fit: BoxFit.cover)),
            );
          }));
    } else {
      return PreferredSize(
        preferredSize: Size.fromHeight(100),
        child: GestureDetector(
          child: Container(
            padding: EdgeInsets.only(top: kToolbarHeight, bottom: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  height: 60,
                  width: 60,
                  child: CircleAvatar(
                    backgroundImage: AssetImage("images/fu.png"),
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Text(
                  "登陆/注册",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),
          onTap: () {
            if (SpUtil.haveKey("username")) {
              return;
            } else {
              Routes.navigateTo(context, Routes.login);
            }
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Color c =
        Color(!Store.value<ColorModel>(context).dark ? 0x4D000000 : 0xFBFFFFFF);
    return Scaffold(
      appBar: _appBar(context),
      body: Container(
        height: Screen.height,
        child: Padding(
          padding: EdgeInsets.only(right: 5, left: 5),
          child: Column(
            children: <Widget>[
              getItem(
                ImageIcon(AssetImage("images/info.png")),
                '公告',
                () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => InfoPage()));
                },
                c,
              ),
              Store.connect<ColorModel>(
                builder: (context, ColorModel data, child) => getItem(
                  ImageIcon(data.dark
                      ? AssetImage("images/sun.png")
                      : AssetImage("images/moon.png")),
                  data.dark ? '日间模式' : '夜间模式',
                  () {
                    data.switchModel();
                  },
                  c,
                ),
              ),
              getItem(
                ImageIcon(AssetImage("images/re.png")),
                '免责声明',
                () {
                  showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                            title: Text(
                              '免责声明',
                            ),
                            content: SingleChildScrollView(
                              child: Text(
                                ReadSetting.lawWarn,
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: Text(
                                  "确定",
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ));
                },
                c,
              ),
              // getItem(
              //   ImageIcon(AssetImage("images/co.png")),
              //   '应用反馈',
              //   ({int number = 953457248, bool isGroup = true}) async {
              //     String url = isGroup
              //         ? 'mqqapi://card/show_pslcard?src_type=internal&version=1&uin=${number ?? 0}&card_type=group&source=qrcode'
              //         : 'mqqwpa://im/chat?chat_type=wpa&uin=${number ?? 0}&version=1&src_type=web&web_src=oicqzone.com';
              //     if (await canLaunch(url)) {
              //       await launch(url);
              //     } else {
              //       print('不能访问');
              //     }
              //   },
              //   c,
              // ),
              getItem(
                ImageIcon(AssetImage("images/skin.png")),
                '主题',
                () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => Skin()));
                },
                c,
              ),
              // getItem(
              //   ImageIcon(AssetImage("images/cache_manager.png")),
              //   '缓存管理',
              //   () {
              //     Navigator.of(context).push(MaterialPageRoute(
              //         builder: (BuildContext context) => CacheManager()));
              //   },
              // ),
              getItem(
                ImageIcon(AssetImage("images/fe.png")),
                '意见反馈',
                () {
                  locator<TelAndSmsService>()
                      .sendEmail('leetomlee123@gmail.com');
                },
                c,
              ),
              getItem(
                ImageIcon(AssetImage("images/github.png")),
                '开源地址',
                () {
                  launch('https://github.com/leetomlee123/book');
                },
                c,
              ),
              getItem(
                ImageIcon(AssetImage("images/upgrade.png")),
                '应用更新',
                () async {
                  Response response =
                      await HttpUtil().http().get(Common.update);
                  var data = response.data['data'];
                  Update update = Update.fromJson(data);
                  PackageInfo packageInfo = await PackageInfo.fromPlatform();

                  String version = packageInfo.version;
                  if (update.version != version) {
                    Navigator.pop(context);

                    BotToast.showWidget(toastBuilder: (context) {
                      return Center(
                        child: UpdateDialog(update),
                      );
                    });
                  } else {
                    BotToast.showText(text: "暂无更新");
                  }
                },
                c,
              ),
              getItem(
                ImageIcon(AssetImage("images/ab.png")),
                '关于',
                () {
                  showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                            title: Text(('清阅揽胜 V${SpUtil.getString(
                              "version",
                            )}')),
                            content: Text(
                              ReadSetting.poet,
                              style: TextStyle(fontSize: 15, height: 2.1),
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: new Text(
                                  "确定",
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ));
                },
                c,
              ),

              Offstage(
                offstage: !SpUtil.haveKey("username"),
                child: Align(
                  alignment: Alignment.center,
                  child: Store.connect<ShelfModel>(
                      builder: (context, ShelfModel model, child) {
                    return GestureDetector(
                      child: WhiteArea(
                          Text(
                            "退出登录",
                            style: TextStyle(color: Colors.redAccent),
                          ),
                          50),
                      onTap: () {
                        model.dropAccountOut();
                        eventBus.fire(new BooksEvent([]));
                      },
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
