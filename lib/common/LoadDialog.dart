import 'package:book/model/ColorModel.dart';
import 'package:book/store/Store.dart';
import 'package:flutter/material.dart';

class LoadingDialog extends Dialog {
  @override
  Widget build(BuildContext context) {
    //创建透明层
    return Store.connect<ColorModel>(
        builder: (context, ColorModel model, child) {
      return Center(
        child: CircularProgressIndicator(
            ),
      );
    });
  }
}
