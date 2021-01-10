import 'package:book/model/ColorModel.dart';
import 'package:book/store/Store.dart';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';

class Upgrade extends StatefulWidget {
  @override
  _UpgradeState createState() => _UpgradeState();
}

class _UpgradeState extends State<Upgrade> {
  ColorModel _colorModel;
  @override
  void initState() {
    _colorModel = Store.value<ColorModel>(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("检查更新"),
        automaticallyImplyLeading: false,
        elevation: 0,
        flexibleSpace: _colorModel.dark
            ? Container()
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    // Colors.accents[_colorModel.idx].shade100,
                    Colors.accents[_colorModel.idx].shade200,
                    Colors.accents[_colorModel.idx].shade400,
                  ], begin: Alignment.centerRight, end: Alignment.centerLeft),
                ),
              ),
      ),
      body: FutureBuilder(
        future: getData(),
        builder: (BuildContext context, AsyncSnapshot<PackageInfo> snapshot) {
          /*表示数据成功返回*/
          if (snapshot.hasData) {
            PackageInfo data = snapshot.data;
            return Center(
              child: Column(
                children: [
                  
                ],
              ),
            );
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }

  Future<PackageInfo> getData() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo;
  }
}
