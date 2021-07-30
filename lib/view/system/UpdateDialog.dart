import 'dart:io';

import 'package:book/common/Http.dart';
import 'package:book/entity/AppInfo.dart';
import 'package:book/event/event.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:install_plugin/install_plugin.dart';
import 'package:path_provider/path_provider.dart';

class UpdateDialog extends StatefulWidget {
  final AppInfo update;

  UpdateDialog(this.update);

  @override
  State<StatefulWidget> createState() => UpdateDialogState();
}

class UpdateDialogState extends State<UpdateDialog> {
  double progress = 0.0;
  bool downloading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      title: Text(
        "更新",
      ),
      content: progress == 0.0
          ? Text('''${this.widget.update.msg}''')
          : LinearProgressIndicator(
              value: progress,
              semanticsLabel: "$progress %",
              semanticsValue: "$progress %",
            ),
      actions: <Widget>[
        TextButton(
          child: Text(
            '更新',
          ),
          onPressed: () {
            installApk();
          },
        ),
        TextButton(
          child: Text('取消'),
          onPressed: () {
            eventBus.fire(new CleanEvent(1));
          },
        ),
      ],
    );
  }

  Future<File> downloadFile() async {
    Dio dio = HttpUtil.instance.dio;
    Directory storageDir = await getExternalStorageDirectory();
    String storagePath = storageDir.path;
    File file = new File('$storagePath/deerbook.apk');

    if (file.existsSync()) {
      file.delete();
    } else {
      file.createSync();
    }

    try {
      /// 发起下载请求
      Response response = await dio.get(widget.update.link,
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

    String msg =
        await InstallPlugin.installApk(_apkFilePath, "com.leetomlee.book");
  }
}
