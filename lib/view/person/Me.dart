import 'package:book/common/Http.dart';
import 'package:book/common/ReadSetting.dart';
import 'package:book/common/common.dart';
import 'package:book/entity/AppInfo.dart';
import 'package:book/main.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/service/TelAndSmsService.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/person/InfoPage.dart';
import 'package:book/view/person/Skin.dart';
import 'package:book/view/system/white_area.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_xupdate/flutter_xupdate.dart';
import 'package:flutter_xupdate/update_entity.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class Me extends StatelessWidget {
  Widget getItem(imageIcon, text, func, Color c) {
    return ListTile(
      onTap: func,
      leading: imageIcon,
      title: Text(text),
    );
  }

  Widget _headImg() {
    return Container(
      width: 60,
      height: 60,
      child: CircleAvatar(
        backgroundImage: AssetImage("images/fu.png"),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    bool login = SpUtil.haveKey("auth");

    return Visibility(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headImg(),
          Text(
            SpUtil.getString('username') ?? "",
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(
            height: 5,
          ),
          Text(
            SpUtil.getString('email') ?? "",
          ),
        ],
      ),
      visible: login,
      replacement: GestureDetector(
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _headImg(),
            SizedBox(
              width: 10,
            ),
            Text(
              "登陆/注册",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        onTap: () {
          if (login) {
            return;
          } else {
            Routes.navigateTo(context, Routes.login);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color c =
        Color(!Store.value<ColorModel>(context).dark ? 0x4D000000 : 0xFBFFFFFF);
    // bool dark = SpUtil.getBool("dark");
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: kToolbarHeight),
      child: ConstrainedBox(
        constraints: BoxConstraints.expand(),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: _buildHeader(context),
                ),
                Divider(),
                getItem(
                  ImageIcon(AssetImage("images/info.png")),
                  '公告',
                  () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (BuildContext context) => InfoPage()));
                  },
                  c,
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
                getItem(
                  ImageIcon(AssetImage("images/skin.png")),
                  '主题',
                  () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (BuildContext context) => Skin()));
                  },
                  c,
                ),
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
                    PackageInfo packageInfo = await PackageInfo.fromPlatform();
                    String version = packageInfo.version;

                    Response response =
                        await HttpUtil.instance.dio.get(Common.update);
                    var data = response.data['data'];
                    AppInfo appInfo = AppInfo.fromJson(data);
                    if (int.parse(appInfo.version.replaceAll(".", "")) >
                        int.parse(version.replaceAll(".", ""))) {
                      Navigator.pop(context);
                      Future.delayed(Duration(milliseconds: 400), () {
                        var up = UpdateEntity(
                            hasUpdate: true,
                            isForce: appInfo.forceUpdate == "2",
                            isIgnorable: false,
                            versionCode: 1,
                            versionName: appInfo.version,
                            updateContent: appInfo.msg,
                            downloadUrl: appInfo.link,
                            apkSize: int.parse(appInfo.apkSize),
                            apkMd5: appInfo.apkMD5);

                        FlutterXUpdate.updateByInfo(
                          updateEntity: up,
                          supportBackgroundUpdate: true,
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
              ],
            ),
            Positioned(
              bottom: 1,
              left: 10,
              right: 10,
              child: Offstage(
                offstage: !SpUtil.haveKey("username"),
                child: Store.connect<ShelfModel>(
                    builder: (context, ShelfModel model, child) {
                  return GestureDetector(
                    child: WhiteArea(
                        Text(
                          "退出登录",
                          style: TextStyle(color: Colors.redAccent),
                        ),
                        45),
                    onTap: () async {
                      await model.dropAccountOut();
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
