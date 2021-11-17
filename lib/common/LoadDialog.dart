import 'package:book/model/ColorModel.dart';
import 'package:book/store/Store.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';

class LoadingDialog extends Dialog {
  @override
  Widget build(BuildContext context) {
    var bool = SpUtil.getBool("dark");
    //创建透明层
    return Store.connect<ColorModel>(
        builder: (context, ColorModel model, child) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor:
              AlwaysStoppedAnimation(bool ? Colors.white : Colors.black),
        ),
      );
    });
  }
}
