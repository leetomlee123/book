import 'package:book/model/ColorModel.dart';
import 'package:book/store/Store.dart';
import 'package:flutter/material.dart';

class LoadingDialog extends Dialog {
  @override
  Widget build(BuildContext context) {
    //创建透明层
    return Store.connect<ColorModel>(
        builder: (context, ColorModel model, child) {
      return Material(
        child: Center(
            child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.black.withOpacity(.1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(
                      height: 9,
                    ),
                    Text(
                      "加载中....",
                      style: TextStyle(fontSize: 15),
                      textAlign: TextAlign.center,
                    )
                  ],
                ))),
      );
    });
  }
}
