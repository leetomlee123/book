import 'dart:io';

import 'package:book/common/util.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/store/Store.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class FontSet extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return StateFontSet();
  }
}

class StateFontSet extends State<FontSet> {
String _fontPath;
  @override
  void initState() {
    initPath();
    // TODO: implement initState
    super.initState();
  }

  initPath() async {
    _fontPath = (await getApplicationDocumentsDirectory()).path + "/font";
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Store.connect<ColorModel>(
        builder: (context, ColorModel model, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text('阅读字体'),
              elevation: 0,
              centerTitle: true,
            ),
            body: Container(
              child: Column(
                children: <Widget>[
                  Center(
                    child: Text(
                      "\t\t\t\t\t\t\t\t\t\t\t\t\t\t问刘十九\r\n绿蚁新醅酒，红泥小火炉。\r\n晚来天欲雪，能饮一杯无？",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: model.font,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  ListView.builder(
                    itemBuilder: (context, i) {
                      var elementAt2 = model.fonts.keys.elementAt(i);
                      var elementAt = model.fonts.values.elementAt(i);
                      var s = elementAt.toString().split('/');
                      var name = s[s.length - 1];
                      return Container(
                        padding: EdgeInsets.only(bottom: 20),
                        child: Row(
                          children: <Widget>[
                            Text(elementAt2),
                            Expanded(
                              child: Container(),
                            ),
                            GestureDetector(
                              child: Container(
                                child: model.font == name
                                    ? Icon(Icons.check)
                                    : Text((SpUtil.haveKey(elementAt2) ||
                                    elementAt2 == "默认字体")
                                    ? "使用"
                                    : "下载"),
                              ),
                              onTap: () async {
                                if (elementAt2 == "默认字体") {
                                  model.setFontFamily("");
                                } else {
                                  if (SpUtil.haveKey(elementAt2)) {
                                    try {
                                      await model.readFont(name);
                                    } catch (e) {}
                                    model.setFontFamily(name);
                                  } else {
                                    try {
                                      await download(name, elementAt);
                                      SpUtil.putString(elementAt2, "1");
                                      setState(() {});
                                    } catch (e) {
                                      print(e + "zz");
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                    itemCount: model.fonts.length,
                    shrinkWrap: true,
                  )
                ],
              ),
              padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
            ),
          );
        });
  }

  Future<bool> isDirectoryExist(String path) async {
    File file = File(path);
    return await file.exists();
  }

  Future<void> createDirectory(String path) async {
    Directory directory = Directory(path);
    directory.create();
  }

  Future<void> download(String name, String url) async {
    bool exist = await isDirectoryExist(_fontPath); //判定目录是否存在 - 不存在就创建
    if (!exist) {
      await createDirectory(_fontPath);
    }
    var path = _fontPath + "/" + name;
    var bool2 = await isDirectoryExist(path);
    if (bool2) {
      print("已存在");
      return;
    }
    Util(context).http().download(url, path);
  }
}
