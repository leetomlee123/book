import 'package:book/model/ColorModel.dart';
import 'package:book/store/Store.dart';
import 'package:flutter/material.dart';

class MyIcon extends StatelessWidget {
  final Function onTap;
  final double size;
  final IconData icon;
  MyIcon(this.icon,this.onTap, {this.size = 25.0});

  @override
  Widget build(BuildContext context) {
    return Store.connect<ColorModel>(
        builder: (context, ColorModel color, child) {
      return IconButton(
        // color: color.dark ? Colors.white : Colors.black,
        icon: Icon(
          icon,
          size: size,
          // color: color.dark ? Colors.white : Colors.black,
        ),
        onPressed: onTap,
      );
    });
  }
}
