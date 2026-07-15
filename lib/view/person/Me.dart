import 'package:book/common/ReadSetting.dart';
import 'package:book/common/local_account.dart';
import 'package:book/main.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/service/TelAndSmsService.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/person/InfoPage.dart';
import 'package:book/view/person/Skin.dart';
import 'package:book/view/system/white_area.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:book/common/local_store.dart';
import 'package:flutter/material.dart';
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
    bool login = LocalAccount.isLoggedIn;

    return Visibility(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headImg(),
          Text(
            LocalAccount.username,
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(height: 5),
          Text(
            LocalAccount.email.isEmpty ? '本地账号' : LocalAccount.email,
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
            SizedBox(width: 10),
            Text(
              "登陆/注册",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        onTap: () {
          if (!login) {
            Routes.navigateTo(context, Routes.login);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool dark = SpUtil.getBool("dark");
    Color c = Color(dark ? 0x4D000000 : 0xFBFFFFFF);

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
                              title: Text('免责声明'),
                              content: SingleChildScrollView(
                                child: Text(ReadSetting.lawWarn),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: Text("确定"),
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
                  Icon(Icons.library_books_outlined),
                  '书源管理',
                  () {
                    Routes.navigateTo(context, Routes.sources);
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
                    launchUrl(
                        Uri.parse('https://github.com/leetomlee123/book'));
                  },
                  c,
                ),
                getItem(
                  ImageIcon(AssetImage("images/upgrade.png")),
                  '应用更新',
                  () async {
                    PackageInfo packageInfo = await PackageInfo.fromPlatform();
                    BotToast.showText(
                        text: "当前版本 ${packageInfo.version}（已移除云端更新检查）");
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
                              title: Text(
                                  ('清阅揽胜 V${SpUtil.getString("version")}')),
                              content: Text(
                                ReadSetting.poet,
                                style: TextStyle(fontSize: 15, height: 2.1),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: Text("确定"),
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
                offstage: !LocalAccount.isLoggedIn,
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
                      LocalAccount.logout();
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
