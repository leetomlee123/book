import 'package:book/common/common.dart';
import 'package:book/event/event.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ColorModel with ChangeNotifier {
  bool dark = false;
  var fontFamily = '';
  List<Color> skins = Colors.accents;
  Map fonts = {
    "默认字体": "",
    "方正新楷体": "http://dl.cdn.sogou.com/font/FZXK_GBK.ttf",
    "方正俊黑体": "http://oss-asq-download.11222.cn/font/package/FZJunHJW.ttf",
    "方正宋繁体": "http://moren-1252794300.file.myqcloud.com/fangzhengsongheiFT.ttf",
    "方正宋简体": "http://mag.reader.3g.qq.com/plugin/fzstys-gb18030.ttf"
  };
  int idx = SpUtil.getInt('skin');
  ThemeData _theme;
  String font = SpUtil.getString("fontName");

  ThemeData get theme {
    if (SpUtil.haveKey("dark")) {
      dark = SpUtil.getBool("dark");
    }
    _theme = dark
        ? ThemeData.dark()
        : ThemeData.light().copyWith(primaryColor: skins[idx]);
    return _theme;
  }

  getSkins(w, h) {
    List<Widget> wds = [];
    for (var i = 0; i < skins.length; i++) {
      wds.add(GestureDetector(
        child: Container(
          width: w,
          height: h,
          child: Stack(
            children: <Widget>[
              Container(
                color: skins[i],
              ),
              i == idx
                  ? Align(
                      alignment: Alignment.topRight,
                      child: ImageIcon(
                        AssetImage('images/pick.png'),
                        color: Colors.white,
                      ),
                    )
                  : Container()
            ],
          ),
        ),
        onTap: () {
          idx = i;
          notifyListeners();
          SpUtil.putInt('skin', idx);
        },
      ));
    }
    return wds;
  }

  switchModel() {
    if (dark) {
      _theme = ThemeData.dark();
    } else {
      _theme = ThemeData.light().copyWith(primaryColor: skins[idx]);
    }
    dark = !dark;
    SpUtil.putBool("dark", dark);
    notifyListeners();
  }

  List<Widget> fontList() {
    List<Widget> wds = [];
    var center = Center(
      child: Text(
        "\t\t\t\t\t\t\t\t\t\t\t\t\t\t问刘十九\r\n绿蚁新醅酒，红泥小火炉。\r\n晚来天欲雪，能饮一杯无？",
        style: TextStyle(fontWeight: FontWeight.bold, fontFamily: font),
      ),
    );
    wds.add(center);
    for (var i = 0; i < fonts.length; i++) {
      wds.add(Row(
        children: <Widget>[
          Text(fonts.keys.elementAt(i)),
          Expanded(
            child: Container(),
          ),
          FlatButton(
            child: Text("使用"),
            onPressed: () {
              loadFont(fonts.keys.elementAt(i), fonts.values.elementAt(i));
            },
          )
        ],
      ));
    }
    return wds;
  }

  loadFont(var name, var url) async {
    if (name != "默认字体") {
      var fontLoad = FontLoader(name);
      var load = NetworkAssetBundle(Uri()).load(url);
      fontLoad.addFont(load);
      await fontLoad.load();
    }
    font = name;
    notifyListeners();
    var keys = SpUtil.getKeys();
    print(keys.length);
    for (var f in keys) {
      if (f.startsWith('pages') || f.startsWith(Common.page_height_pre)) {
        SpUtil.remove(f);
      }
    }
    keys = SpUtil.getKeys();
    print(keys.length);
    if (SpUtil.haveKey("fontName")) {
      SpUtil.remove("fontName");
    }
    SpUtil.putString("fontName", name);
    eventBus.fire(ReadRefresh(""));
  }
}
