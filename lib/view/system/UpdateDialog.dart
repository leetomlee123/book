import 'dart:io';

import 'package:book/common/Http.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:install_plugin/install_plugin.dart';
import 'package:path_provider/path_provider.dart';

class UpdateDialog extends StatefulWidget {
  final String version;
  final String feature;
  final String url;

  UpdateDialog(this.feature, this.version, this.url);

  @override
  State<StatefulWidget> createState() => UpdateDialogState();
}

class UpdateDialogState extends State<UpdateDialog> {
  double progress = 0.0;
  bool downloading = false;

  @override
  Widget build(BuildContext context) {
    var _textStyle = TextStyle(color: Theme.of(context).textTheme.body1.color);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      title: Text(
        "更新",
        style: _textStyle,
      ),
      content: progress == 0.0
          ? Text(
              "${widget.version}",
              style: _textStyle,
            )
          : LinearProgressIndicator(
              value: progress,
            ),
      actions: <Widget>[
        FlatButton(
          child: Text(
            '更新',
            style: _textStyle,
          ),
          onPressed: () {
            installApk();
          },
        ),
        FlatButton(
          child: Text('取消'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Future<File> downloadFile() async {
    Dio dio = HttpUtil().http();
    Directory storageDir = await getExternalStorageDirectory();
    String storagePath = storageDir.path;
    File file = new File('$storagePath/apk/deerbook.apk');

    if (file.existsSync()) {
      file.delete();
    } else {
      file.createSync();
    }

    try {
      /// 发起下载请求
      Response response = await dio.get(widget.url,
          onReceiveProgress: (receivedBytes, totalBytes) {
        setState(() {
          downloading = true;
          // 4、连接资源成功开始下载后更新状态
          progress = (receivedBytes / totalBytes);
        });
      },
          options: Options(
            responseType: ResponseType.bytes,
            followRedirects: false,
          ));
      file.writeAsBytesSync(response.data);

      return file;
    } catch (e) {
      print(e);
    }
  }

  /// 安装apk
  Future<Null> installApk() async {
    File _apkFile = await downloadFile();

    setState(() {
      downloading = false;
      progress = 0;
    });
    String _apkFilePath = _apkFile.path;

    if (_apkFilePath.isEmpty) {
      print('make sure the apk file is set');
      return;
    }

    InstallPlugin.installApk(_apkFilePath, "com.leetomlee.book").then((result) {
      print('install apk $result');
    }).catchError((error) {
      print('install apk error: $error');
    });
  }
}
