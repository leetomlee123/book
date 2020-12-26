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
        color: Colors.transparent,
        child: Center(
            child: Container(
                width: 150,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: model.dark
                      ? Colors.white.withOpacity(.5)
                      : Colors.black.withOpacity(.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(model.dark?Colors.black:Colors.white),
                    ),
                    SizedBox(
                      width: 9,
                    ),
                    Text(
                      "加载中....",
                      style: TextStyle(
                          fontSize: 15,
                          color: model.dark ? Colors.black : Colors.white),
                      textAlign: TextAlign.center,
                    )
                  ],
                ))),
      );
    });
  }
}
