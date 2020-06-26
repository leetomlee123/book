import 'package:book/model/ColorModel.dart';
import 'package:book/store/Store.dart';
import 'package:flutter/material.dart';

class FontSet extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return StateFontSet();
  }
}

class StateFontSet extends State<FontSet> {
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
        body: Container(child: Column(

          children: model.fontList(),
        ),padding: EdgeInsets.symmetric(vertical: 10.0,horizontal: 10.0),),
      );
    });
  }
}
