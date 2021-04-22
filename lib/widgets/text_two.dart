import 'package:book/model/ColorModel.dart';
import 'package:book/store/Store.dart';
import 'package:flutter/material.dart';

class TextTwo extends StatelessWidget {
  final String text;
  final int maxLines;
  final double fontSize;

  TextTwo(this.text,{this.maxLines,this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Store.connect<ColorModel>(builder: (context,ColorModel model,child){
      return Text(
        text,
        maxLines: maxLines,
        style: TextStyle(color: model.dark?Colors.white:Color(0x9A000000),fontSize: fontSize),
      );
    });
  }
}
