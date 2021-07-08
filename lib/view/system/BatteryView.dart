import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BatteryView extends StatelessWidget {
  final double electricQuantity;
  final double width;
  final double height;

  BatteryView(
      {Key key, this.electricQuantity, this.width = 22, this.height = 10})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: CustomPaint(
          size: Size(width, height),
          painter: BatteryViewPainter(electricQuantity)),
    );
  }
}

class BatteryViewPainter extends CustomPainter {
  double electricQuantity;
  Paint mPaint;
  double mStrokeWidth = 1.0;
  double mPaintStrokeWidth = 1.5;
  final bool isDark = SpUtil.getBool("dark", defValue: false);

  BatteryViewPainter(electricQuantity) {
    this.electricQuantity = electricQuantity;
    mPaint = Paint()..strokeWidth = mPaintStrokeWidth;
  }

  @override
  void paint(Canvas canvas, Size size) {
    //电池头部位置
    double batteryHeadLeft = 0;
    double batteryHeadTop = size.height / 4;
    double batteryHeadRight = size.width / 15;
    double batteryHeadBottom = batteryHeadTop + (size.height / 2);

    //电池框位置
    double batteryLeft = batteryHeadRight + mStrokeWidth;
    double batteryTop = 0;
    double batteryRight = size.width;
    double batteryBottom = size.height;

    //电量位置
    double electricQuantityTotalWidth =
        size.width - batteryHeadRight - 5 * mStrokeWidth; //电池减去边框减去头部剩下的宽度

    double electricQuantityLeft = batteryHeadRight +
        2 * mStrokeWidth +
        electricQuantityTotalWidth * (1 - electricQuantity);
    double electricQuantityTop = mStrokeWidth * 2;
    double electricQuantityRight = size.width - 2 * mStrokeWidth;
    double electricQuantityBottom = size.height - 2 * mStrokeWidth;

    mPaint.style = PaintingStyle.fill;
    mPaint.color = isDark ? Colors.white54 : Colors.black54;
    // mPaint.color = Color(0x80ffffff);
    //画电池头部
    canvas.drawRRect(
        RRect.fromLTRBR(batteryHeadLeft, batteryHeadTop, batteryHeadRight,
            batteryHeadBottom, Radius.circular(mStrokeWidth)),
        mPaint);
    mPaint.style = PaintingStyle.stroke;
    //画电池框
    canvas.drawRRect(
        RRect.fromLTRBR(batteryLeft, batteryTop, batteryRight, batteryBottom,
            Radius.circular(mStrokeWidth)),
        mPaint);
    mPaint.style = PaintingStyle.fill;
    mPaint.color = isDark ? Colors.white38 : Colors.black38;
    //画电池电量
    canvas.drawRRect(
        RRect.fromLTRBR(
            electricQuantityLeft + 0.5,
            electricQuantityTop,
            electricQuantityRight,
            electricQuantityBottom,
            Radius.circular(mStrokeWidth)),
        mPaint);
  }

  @override
  bool shouldRepaint(BatteryViewPainter other) {
    return true;
  }
}
