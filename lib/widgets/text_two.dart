import 'package:flutter/material.dart';

class TextTwo extends StatelessWidget {
  final String text;
  final int maxLines;
  final double fontSize;

  TextTwo(this.text,{this.maxLines,this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      style: TextStyle(color: Color(0x9A000000),fontSize: fontSize),
    );
  }
}
