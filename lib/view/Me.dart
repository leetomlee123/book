import 'dart:convert';

import 'package:book/common/common.dart';
import 'package:book/common/util.dart';
import 'package:book/entity/BookInfo.dart';
import 'package:book/entity/BookTag.dart';
import 'package:book/entity/Info.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/ReadModel.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/service/TelAndSmsService.dart';
import 'package:book/store/Store.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';

class Me extends StatelessWidget {
  Widget getItem(imagIcon, text, func) {
    return Card(
        child: ListTile(
      onTap: func,
      leading: imagIcon,
      title: Text(text),
      trailing: Icon(Icons.keyboard_arrow_right),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100),
        child: Container(
          child: GestureDetector(
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 20,
                ),
                GestureDetector(
                  child: Padding(
                    child: Container(
                      height: 80,
                      width: 80,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        backgroundImage: AssetImage(SpUtil.haveKey("login")
                            ? "images/fu.png"
                            : "images/account.png"),
                      ),
                    ),
                    padding:
                        EdgeInsets.only(top: ScreenUtil.getStatusBarH(context)),
                  ),
                  onTap: () {
                    if (SpUtil.haveKey("login")) {
                      return;
                    } else {
                      Routes.navigateTo(context, Routes.login);
                    }
                  },
                ),
                SizedBox(
                  width: 10,
                ),
                Center(
                  child: Padding(
                    child: Text(
                      SpUtil.haveKey("login")
                          ? SpUtil.getString('username')
                          : "登陆/注册",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                    padding: EdgeInsets.only(top: 30),
                  ),
                )
              ],
            ),
            onTap: () {
              if (!SpUtil.haveKey('email')) {
                Routes.navigateTo(context, Routes.login);
              }
            },
          ),
          color: Theme.of(context).primaryColor,
        ),
      ),
      body: Container(
        width: ScreenUtil.getScreenW(context),
        child: Padding(
          padding: EdgeInsets.only(right: 5, left: 5),
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              getItem(
                ImageIcon(AssetImage("images/info.png")),
                '公告',
                () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => InfoPage()));
                },
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
                      )),
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
                                ('''鉴于本服务以非人工检索方式提供无线搜索、根据您输入的关键字自动生成到第三方网页的链接，本服务会提供与其他任何互联网网站或资源的链接。由于清阅小说无法控制这些网站或资源的内容，您了解并同意：无论此类网站或资源是否可供利用，清阅小说不予负责；清阅小说亦对存在或源于此类网站或资源之任何内容、广告、产品或其他资料不予保证或负责。因您使用或依赖任何此类网站或资源发布的或经由此类网站或资源获得的任何内容、商品或服务所产生的任何损害或损失，清阅小说不负任何直接或间接责任。

因本服务搜索结果根据您键入的关键字自动搜索获得并生成，不代表清阅小说赞成被搜索链接到的第三方网页上的内容或立场。

任何通过使用本服务而搜索链接到的第三方网页均系第三方提供或制作，您可能从该第三方网页上获得资讯及享用服务，清阅小说无法对其合法性负责，亦不承担任何法律责任。

您应对使用无线搜索引擎的结果自行承担风险。清阅小说不做任何形式的保证：不保证搜索结果满足您的要求，不保证搜索服务不中断，不保证搜索结果的安全性、准确性、及时性、合法性。因网络状况、通讯故障、第三方网站等任何原因而导致您不能正常使用本服务的，清阅小说不承担任何法律责任。

您应该了解并知晓，清阅小说作为移动互联网的先行者，拥有先进的无线数据应用技术和智能搜索系统，为手机等无线端用户提供了移动互联网的最佳搜索体验。清阅小说使用行业内成熟的搜索引擎技术，同时充分考虑用户手机端上网特征，由于电脑端网页的复杂、多样与标准的不同，用户无法通过手机正常浏览电脑端网页，为了提供更好的用户体验，用户在搜索点击后，我们网页会提供转码，这就是网页实时转换技术，将页面转换为适于手机用户访问的页面，从而为用户提供可用、高效的搜索服务。由于搜索引擎对数据即时性和客观性的要求，和复杂的数据变更以及本身的技术问题，在转码的过程中可能会出现原网站的部门数据异常而导致部分数据错误，若您想获取完整的原网站完整有效的内容，您应选择去原网站浏览，介于此类技术问题，清阅小说一直在不断的完善搜索技术，以提高数据的准确性。

您使用本服务即视为您已阅读并同意受本声明内容的相关约束。清阅小说有权在根据具体情况进行修改本声明条款。对此，我们不会有专门通知，但，您可以在相关页面中查阅最新的条款。条款变更后，如果您继续使用本服务，即视为您已接受修改后的条款。如果您不接受，应当停止使用本服务。

本声明内容同时包括《清阅小说软件服务协议》，《版权保护投诉指引》及清阅小说可能不断发布本服务的相关声明、协议、业务规则等内容。上述内容一经正式发布，即为本声明不可分割的组成部分，您同样应当遵守。上述内容与本声明内容存在冲突的，以本声明为准。您对前述任何业务规则、声明内容的接受，即视为您对本声明内容全部的接受。

本声明的成立、生效、履行、解释及纠纷解决，适用中华人民共和国大陆地区法律（不包括冲突法）。

若您和清阅小说之间发生任何纠纷或争议，首先应友好协商解决；协商不成的，您同意将纠纷或争议提交清阅小说所在地的人民法院处理。'''),
                              ),
                            ),
                            actions: <Widget>[
                              FlatButton(
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
              ),
              getItem(
                ImageIcon(AssetImage("images/co.png")),
                '交流联系',
                () {
                  showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                            title: Text(
                              ('QQ群'),
                            ),
                            content: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: <Widget>[
                                Text(
                                  '953457248',
                                ),
                                SizedBox(
                                  width: 50,
                                ),
                                IconButton(
                                  onPressed: () {
                                    ClipboardData data =
                                        ClipboardData(text: "953457248");
                                    Clipboard.setData(data);
                                  },
                                  icon: Icon(
                                    Icons.content_copy,
                                  ),
                                ),
                              ],
                            ),
                            actions: <Widget>[
                              FlatButton(
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
              ),
              getItem(
                ImageIcon(AssetImage("images/skin.png")),
                '换肤',
                () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => Skin()));
                },
              ),
              getItem(
                ImageIcon(AssetImage("images/cache_manager.png")),
                '缓存管理',
                () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => CacheManager()));
                },
              ),
              getItem(
                ImageIcon(AssetImage("images/fe.png")),
                '意见反馈',
                () {
                  locator<TelAndSmsService>()
                      .sendEmail('leetomlee123@gmail.com');
                },
              ),
              getItem(
                ImageIcon(AssetImage("images/ab.png")),
                '关于',
                () {
                  showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                            title: Text(('清阅揽胜  ')),
                            content: Text(
                              '世人为荣利缠缚，动曰尘世苦海，不知云白山青，川行石立，花迎鸟笑，谷答樵讴，世亦不尘、海亦不苦、彼自尘苦其心尔',
                            ),
                            actions: <Widget>[
                              FlatButton(
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
              ),
              SpUtil.haveKey("login")
                  ? GestureDetector(
                      child: Card(
                        child: Container(
                          height: 50,
                          child: Text("退出登录"),
                          alignment: Alignment.center,
                        ),
                      ),
                      onTap: () {
                        Store.value<ShelfModel>(context).dropAccountOut();
                        eventBus.fire(new BooksEvent([]));
                      },
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}

class CacheManager extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _CacheManager();
  }
}

class _CacheManager extends State<CacheManager> {
  @override
  Widget build(BuildContext context) {
    return Store.connect<ColorModel>(
        builder: (context, ColorModel data, child) => Theme(
              child: Scaffold(
                appBar: AppBar(
                  title: Text("缓存管理"),
                  centerTitle: true,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                ),
                body: ListView(
                  children: managers(data.theme.primaryColor),
                ),
              ),
              data: data.theme,
            ));
  }

  List<Widget> managers(Color color) {
    List<Widget> wds = [];
    if (SpUtil.haveKey(Common.downloadlist)) {
      List<String> ids = SpUtil.getStringList(Common.downloadlist);
      ids.forEach((f) {
        wds.add(item(f, color));
      });
    }
    return wds;
  }

  Widget item(id, Color color) {
    BookTag bookTag = BookTag.fromJson(jsonDecode(SpUtil.getString(id)));
    int all = bookTag.chapters.length;
    int sub = 0;
    bookTag.chapters.forEach((f) {
      if (f.hasContent == 2) {
        sub += 1;
      }
    });
    return Card(
      child: Column(
        children: <Widget>[
          Text(bookTag.bookName),
          Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  child: Slider(
                    activeColor: Colors.white,
                    inactiveColor: Colors.white70,
                    value: sub.toDouble(),
                    max: all.toDouble(),
                    min: 0.0,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.arrow_downward),
                onPressed: () {
                  var value = Store.value<ReadModel>(context);
                  value.bookTag = bookTag;
                  value.bookInfo = BookInfo.x(id);
                  value.downloadAll();
                },
              )
            ],
          )
        ],
      ),
    );
  }
}

class Skin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Store.connect<ColorModel>(
        builder: (context, ColorModel data, child) => Theme(
              child: Scaffold(
                body: Padding(
                  padding: EdgeInsets.only(
                      left: 15,
                      right: 15,
                      top: ScreenUtil.getStatusBarH(context) + 10),
                  child: Wrap(
                    spacing: 10.0,
                    runSpacing: 12.0,
                    children: data.getSkins(
                        ((ScreenUtil.getScreenW(context) - 40) / 2).toDouble(),
                        (ScreenUtil.getScreenW(context) - 40) /
                            2 /
                            5 *
                            2.toDouble()),
                  ),
                ),
              ),
              data: data.theme,
            ));
  }
}

class InfoPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return InfoState();
  }
}

class InfoState extends State<InfoPage> {
  List<Info> ifs = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getInfo();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Store.connect<ColorModel>(
        builder: (context, ColorModel data, child) => Theme(
              child: Scaffold(
                appBar: AppBar(
                  title: Text("公告"),
                  centerTitle: true,
                  elevation: 0,
                ),
                body: Padding(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Center(
                        child: Text(ifs.length == 0 ? "公告" : ifs[0].Title),
                      ),
                      Container(
                        child: Text(
                          ifs.length == 0 ? "太平无事" : ifs[0].Content,
                          textAlign: TextAlign.start,
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Container(),
                          ),
                          Text(
                            ifs.length == 0
                                ? DateUtil.getNowDateStr()
                                : ifs[0].Date,
                            textAlign: TextAlign.start,
                          )
                        ],
                      )
                    ],
                  ),
                  padding: EdgeInsets.all(15),
                ),
              ),
              data: data.theme,
            ));
  }

  Future<void> getInfo() async {
    Response res = await Util(null).http().get(Common.info);
    List data = res.data['data'];
    if (data == null) {
      return;
    }
    ifs = data.map((f) => Info.fromJson(f)).toList();
    if (mounted) {
      setState(() {});
    }
  }
}
