import 'dart:io';
import 'dart:typed_data';

import 'package:book/common/LoadDialog.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/service/CustomCacheManager.dart';
import 'package:book/store/Store.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class FontSet extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return StateFontSet();
  }
}

class StateFontSet extends State<FontSet> {
  String _fontPath;
  ColorModel _colorModel;
  List<Widget> wds = [];
  bool downloading = false;
  double v = 0.0;

  @override
  void initState() {
    _colorModel = Store.value<ColorModel>(context);
    _fontItems();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          "字体",
          style: TextStyle(
            color: _colorModel.dark ? Colors.white : Colors.black,
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: wds.isEmpty
          ? Container()
          : Container(
              child: Column(
                children: <Widget>[
                  Center(
                    child: Text(
                      "\t\t\t\t\t\t\t\t\t\t\t\t\t\t问刘十九\r\n绿蚁新醅酒，红泥小火炉。\r\n晚来天欲雪，能饮一杯无？",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: _colorModel.font,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  downloading
                      ? Slider(value: 10, min: 0.0, max: 100, onChanged: (v) {})
                      : Container(),
                  SizedBox(
                    height: 20,
                  ),
                  ListView(
                    children: wds,
                    shrinkWrap: true,
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
            ),
    );
  }

  _fontItems() async {
    wds = [];
    List<Future> futures = [];
    _colorModel.fonts.forEach((key, value) {
      var fontName = key;
      var fontUrl = value;
      futures.add(getFileInfo(fontName).then((fileInfo) {
        wds.add(Container(
          padding: EdgeInsets.only(bottom: 20),
          child: Row(
            children: <Widget>[
              Text(fontName == "Roboto" ? fontUrl : fontName),
              Expanded(
                child: Container(),
              ),
              GestureDetector(
                child: Container(
                  child: _colorModel.font == fontName
                      ? Icon(Icons.check)
                      : Text((fileInfo != null || fontName == "Roboto")
                          ? "使用"
                          : "下载"),
                ),
                onTap: () async {
                  if (fileInfo == null && fontName != "Roboto") {
                    showGeneralDialog(
                      context: context,
                      barrierLabel: "",
                      barrierDismissible: true,
                      transitionDuration: Duration(milliseconds: 300),
                      pageBuilder: (BuildContext context, Animation animation,
                          Animation secondaryAnimation) {
                        return LoadingDialog();
                      },
                    );
                    FileInfo fileInfo = await CustomCacheManager.instanceFont
                        .downloadFile(fontUrl, key: fontName);
                    print(fileInfo.file.path);
                    Navigator.pop(context);
                  } else {
                    if (fontName == "Roboto") {
                      _colorModel.setFontFamily("Roboto");
                    } else {
                      File file = await CustomCacheManager.instanceFont
                          .getSingleFile(fontUrl, key: fontName);
                      var fontLoader = FontLoader(fontName);
                      Uint8List readAsBytes = file.readAsBytesSync();

                      fontLoader.addFont(
                          Future.value(ByteData.view(readAsBytes.buffer)));
                      await fontLoader.load();
                      _colorModel.setFontFamily(fontName);
                    }
                  }

                  _fontItems();
                },
              ),
              SizedBox(
                width: 10,
              ),
            ],
          ),
        ));
      }));
    });
    Future.wait(futures).then((value) {
      if (mounted) {
        setState(() {});
      }
    }).catchError((e) {
      print(e);
    });
  }

  Future<FileInfo> getFileInfo(String key) async {
    return await CustomCacheManager.instanceFont.getFileFromCache(key);
  }

// Future<bool> isDirectoryExist(String path) async {
//   File file = File(path);
//   return await file.exists();
// }

// Future<void> createDirectory(String path) async {
//   Directory directory = Directory(path);
//   directory.create();
// }

// Future<void> download(String name, String url) async {
//   bool exist = await isDirectoryExist(_fontPath); //判定目录是否存在 - 不存在就创建
//   if (!exist) {
//     await createDirectory(_fontPath);
//   }
//   var path = _fontPath + "/" + name + '.TTF';
//   var bool2 = await isDirectoryExist(path);
//   if (bool2) {
//     print("已存在");
//     return;
//   }
//   showGeneralDialog(
//     context: context,
//     barrierLabel: "",
//     barrierDismissible: true,
//     transitionDuration: Duration(milliseconds: 300),
//     pageBuilder: (BuildContext context, Animation animation,
//         Animation secondaryAnimation) {
//       return LoadingDialog();
//     },
//   );
//   await Util(null).http().download(url, path);
//   Navigator.pop(context);
//   SpUtil.putString(name, "1");

//   BotToast.showText(text: "$name 字体下载完成");
// }
}
