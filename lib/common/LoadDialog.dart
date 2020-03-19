import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingDialog extends Dialog {
  @override
  Widget build(BuildContext context) {
    //创建透明层
    return Center(
        child: Container(
          width: 300,
          height: 300,
          child: SpinKitCircle(
            color: Theme.of(context).primaryColor,
            size: 50,
          ),
        ));
  }
}
