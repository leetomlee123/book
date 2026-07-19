import 'package:book/common/local_store.dart';
import 'package:flutter/material.dart';

/// Local static notices (no network).
class InfoPage extends StatefulWidget {
  const InfoPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return InfoState();
  }
}

class InfoState extends State<InfoPage> {
  @override
  Widget build(BuildContext context) {
    final version = SpUtil.getString('version');
    return Scaffold(
      appBar: AppBar(
        title: Text("公告"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Text(
                '本地书源模式',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(height: 12),
            Text(
              '本版本已切换为本地书源阅读：\n'
              '1. 请在「书源管理」自行导入 Legado / 阅读书源 JSON\n'
              '2. 应用不附带、不自动下载任何第三方书源\n'
              '3. 账号为本地账号，仅保存在本机，不上传服务器\n'
              '4. 阅读进度与书架缓存保存在本机\n\n'
              '请勿导入或使用侵犯他人版权的书源。',
              textAlign: TextAlign.start,
              style: TextStyle(height: 1.5),
            ),
            Spacer(),
            Row(
              children: <Widget>[
                Expanded(child: Container()),
                Text(
                  version.isEmpty
                      ? DateUtil.getNowDateStr()
                      : 'v$version · ${DateUtil.getNowDateStr()}',
                  textAlign: TextAlign.start,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
