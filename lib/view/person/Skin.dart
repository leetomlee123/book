
import 'package:book/model/ColorModel.dart';
import 'package:book/store/Store.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';

class Skin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Store.connect<ColorModel>(
        builder: (context, ColorModel data, child) => Theme(
              child: Scaffold(
                body: Padding(
                  padding: EdgeInsets.only(
                      left: 15,
                      right: 15,
                      top: ScreenUtil.getStatusBarH(context) + 10),
                  child: Wrap(
                    spacing: 10.0,
                    runSpacing: 12.0,
                    children: data.getSkins(
                        ((ScreenUtil.getScreenW(context) - 40) / 2).toDouble(),
                        (ScreenUtil.getScreenW(context) - 40) /
                            2 /
                            5 *
                            2.toDouble()),
                  ),
                ),
              ),
              data: data.theme,
            ));
  }
}
