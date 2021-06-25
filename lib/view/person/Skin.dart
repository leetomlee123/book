import 'package:book/model/ColorModel.dart';
import 'package:book/store/Store.dart';
import 'package:flutter/material.dart';

class Skin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Store.connect<ColorModel>(
        builder: (context, ColorModel data, child) => Theme(
              child: Scaffold(
                appBar: AppBar(
                  title: Text("主题切换"),
                  centerTitle: true,
                ),
                body: GridView.count(
                  //水平子Widget之间间距
                  crossAxisSpacing: 10.0,
                  //垂直子Widget之间间距
                  mainAxisSpacing: 30.0,
                  //GridView内边距
                  padding: EdgeInsets.all(10.0),
                  //一行的Widget数量
                  crossAxisCount: 2,
                  //子Widget宽高比例
                  childAspectRatio: 2.0,
                  //子Widget列表
                  children: data.getSkins(),
                ),
              ),
              data: data.theme,
            ));
  }
}
