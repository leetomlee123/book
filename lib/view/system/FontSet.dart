import 'dart:io';
import 'dart:typed_data';

import 'package:book/event/event.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/ReadModel.dart';
import 'package:book/service/CustomCacheManager.dart';
import 'package:book/store/Store.dart';
import 'package:book/widgets/download_progress.dart';
import 'package:flustars/flustars.dart';
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
  List<FontInfo> fs = [];

  var key;

  @override
  void initState() {
    _colorModel = Store.value<ColorModel>(context);
    fetchData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var readModel = Store.value<ReadModel>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "字体",
          style: TextStyle(),
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
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Expanded(
                child: Container(
              alignment: Alignment.center,
              child: ListView.builder(
                itemCount: fs.length,
                itemExtent: 70,
                itemBuilder: (context, index) {
                  var e = fs[index];
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: <Widget>[
                        Text(e.key == "Roboto" ? e.value : e.key),
                        Spacer(),
                        GestureDetector(
                          child: Container(
                            child: _colorModel.font == e.key
                                ? Icon(Icons.check)
                                : (downloading == true && e.key == key)
                                    ? DownloadProgressUI(e.value)
                                    : Text((e.fileInfo != null ||
                                            e.key == "Roboto")
                                        ? "使用"
                                        : "下载"),
                          ),
                          onTap: () async {
                            if (e.fileInfo == null && e.key != "Roboto") {
                              var fileStream = CustomCacheManager.instanceFont
                                  .getFileStream(e.value,
                                      key: e.key, withProgress: true);
                              if (mounted) {
                                setState(() {
                                  key = e.key;
                                  downloading = true;
                                });
                              }
                              fileStream.listen((event) {
                                try {
                                  var event2 = event as DownloadProgress;
                                  v = NumUtil.getNumByValueDouble(
                                      event2.progress, 2);
                                  // print(v);
                                  eventBus.fire(DownLoadNotify(e.value, v));
                                  if (v == 1.0) {
                                    if (mounted) {
                                      setState(() {
                                        downloading = false;
                                        v = .0;
                                      });
                                    }
                                  }
                                } catch (e) {
                                  try {
                                    var file = event as FileInfo;
                                    if (mounted) {
                                      setState(() {
                                        fs[index].fileInfo = file;
                                      });
                                    }
                                  } catch (e) {}
                                }
                              });
                            } else {
                              if (e.key == "Roboto") {
                                _colorModel.setFontFamily("Roboto");
                                readModel.updPage();
                              } else {
                                File file = await CustomCacheManager
                                    .instanceFont
                                    .getSingleFile(e.value, key: e.key);
                                var fontLoader = FontLoader(e.key);
                                Uint8List readAsBytes = file.readAsBytesSync();

                                fontLoader.addFont(Future.value(
                                    ByteData.view(readAsBytes.buffer)));
                                await fontLoader.load();
                                _colorModel.setFontFamily(e.key);
                                readModel.updPage();
                                //  Theme.of(context).textTheme.
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
                  );
                },
              ),
            ))
          ],
        ),
        padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
      ),
    );
  }

  Future fetchData() async {
    Map fonts = _colorModel.fonts();
    var entries = fonts.entries;
    int len = entries.length;
    for (int i = 0; i < len; i++) {
      String key = entries.elementAt(i).key;
      String value = entries.elementAt(i).value;
      var fileInfo2 = await getFileInfo(key);
      fs.add(FontInfo(key, value, fileInfo2));
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<FileInfo> getFileInfo(String key) async {
    return await CustomCacheManager.instanceFont.getFileFromCache(key);
  }
}

class FontInfo {
  String key;
  String value;
  FileInfo fileInfo;

  FontInfo(this.key, this.value, this.fileInfo);
}
