import 'package:book/model/ColorModel.dart';
import 'package:book/store/Store.dart';
import 'package:flutter/material.dart';

class WhiteArea extends StatelessWidget {
  final Widget _widget;
  final double height;
  WhiteArea(this._widget, this.height);

  @override
  Widget build(BuildContext context) {
    return Store.connect<ColorModel>(
        builder: (context, ColorModel model, child) {
      return Container(
        decoration: BoxDecoration(
          color: Color(model.dark ? 0x4D000000 : 0xABFFFFFF),
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
        margin: EdgeInsets.symmetric(vertical: 50),
        padding: EdgeInsets.symmetric(
          horizontal: 30,
        ),
        height: height,
        child: _widget,
        alignment: Alignment.center,
      );
    });
  }
}
