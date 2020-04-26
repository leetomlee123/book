import 'package:book/model/ColorModel.dart';
import 'package:book/store/Store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingDialog extends Dialog {
  @override
  Widget build(BuildContext context) {
    //创建透明层
    return Center(
        child: Container(
          width: 600,
          height: 600,
          child: SpinKitCircle(
            color: Store
                .value<ColorModel>(context)
                .theme
                .primaryColor,
            size: 50,
          ),
        ));
  }
}
