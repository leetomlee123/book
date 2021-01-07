import 'dart:io';
import 'dart:typed_data';

import 'package:book/common/LoadDialog.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/service/CustomCacheManager.dart';
import 'package:book/store/Store.dart';
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
  ColorModel _colorModel;
  List<Widget> wds = [];
  bool downloading = false;
  double v = 0.0;

  @override
  void initState() {
    _colorModel = Store.value<ColorModel>(context);

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
      body: Container(
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
            Expanded(
                child: FutureBuilder(
              future: fetchData(),
              builder: (BuildContext context,
                  AsyncSnapshot<List<FontInfo>> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasData) {
                    return Container(
                      alignment: Alignment.center,
                      child: ListView(
                        children: snapshot.data
                            .map((e) => Container(
                                  padding: EdgeInsets.only(bottom: 20),
                                  child: Row(
                                    children: <Widget>[
                                      Text(e.key == "Roboto" ? e.value : e.key),
                                      Expanded(
                                        child: Container(),
                                      ),
                                      GestureDetector(
                                        child: Container(
                                          child: _colorModel.font == e.key
                                              ? Icon(Icons.check)
                                              : Text((e.fileInfo != null ||
                                                      e.key == "Roboto")
                                                  ? "使用"
                                                  : "下载"),
                                        ),
                                        onTap: () async {
                                          if (e.fileInfo == null &&
                                              e.key != "Roboto") {
                                            showGeneralDialog(
                                              context: context,
                                              barrierLabel: "",
                                              barrierDismissible: true,
                                              barrierColor: Colors.transparent,
                                              transitionDuration:
                                                  Duration(milliseconds: 300),
                                              pageBuilder:
                                                  (BuildContext context,
                                                      Animation animation,
                                                      Animation
                                                          secondaryAnimation) {
                                                return LoadingDialog();
                                              },
                                            );
                                            FileInfo fileInfo =
                                                await CustomCacheManager
                                                    .instanceFont
                                                    .downloadFile(e.value,
                                                        key: e.key);
                                            print(fileInfo.file.path);
                                            Navigator.pop(context);
                                          } else {
                                            if (e.key == "Roboto") {
                                              _colorModel
                                                  .setFontFamily("Roboto");
                                            } else {
                                              File file =
                                                  await CustomCacheManager
                                                      .instanceFont
                                                      .getSingleFile(e.value,
                                                          key: e.key);
                                              var fontLoader =
                                                  FontLoader(e.key);
                                              Uint8List readAsBytes =
                                                  file.readAsBytesSync();

                                              fontLoader.addFont(Future.value(
                                                  ByteData.view(
                                                      readAsBytes.buffer)));
                                              await fontLoader.load();
                                              _colorModel.setFontFamily(e.key);
                                            }
                                          }
                                          if (mounted) {
                                            setState(() {});
                                          }
                                        },
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    );
                  } else {
                    return Container(
                      alignment: Alignment.center,
                      child: Text('error'),
                    );
                  }
                } else {
                  return Container(
                      alignment: Alignment.center,
                      child: CircularProgressIndicator());
                }
              },
            ))
            // ListView(
            //   children: wds,
            //   shrinkWrap: true,
            // ),
          ],
        ),
        padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
      ),
    );
  }

  Future<List<FontInfo>> fetchData() async {
    List<FontInfo> fontInfos = [];
    for (int i = 0; i < _colorModel.fonts.length; i++) {
      String key=_colorModel.fonts.keys.elementAt(i);
      String value=_colorModel.fonts.values.elementAt(i);
      var fileInfo2 = await getFileInfo(key);
      fontInfos.add(FontInfo(key, value, fileInfo2));
    }
    return fontInfos;
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

class FontInfo {
  String key;
  String value;
  FileInfo fileInfo;

  FontInfo(this.key, this.value, this.fileInfo);
}
