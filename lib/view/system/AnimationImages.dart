// 播放图片动画
import 'package:flutter/material.dart';

class AnimationImages extends StatefulWidget {
  @override
  _AnimationImagesState createState() => _AnimationImagesState();
}

class _AnimationImagesState extends State<AnimationImages> {
  // 显示的 image
  int showIndex = 0;
  bool _disposed;
  List<Image> images = [
    Image.asset("images/bp0.png"),
    Image.asset("images/bp1.png"),
    Image.asset("images/bp2.png"),
    Image.asset("images/bp3.png"),
    Image.asset("images/bp4.png"),
    Image.asset("images/bp5.png"),
    Image.asset("images/bp6.png"),
    Image.asset("images/bp7.png"),
    Image.asset("images/bp8.png"),
    Image.asset("images/bp9.png"),
  ];
  @override
  void initState() {
    super.initState();
    _disposed = false;
    Future.delayed(Duration(milliseconds: 200), () {
      _updateImage(images.length, Duration(milliseconds: 100));
    });
  }

  _updateImage(int count, Duration millisecond) {
    Future.delayed(millisecond, () {
      if (_disposed) return;
      setState(() {
        showIndex = images.length - count--;
      });
      if (count < 1) {
        count = images.length;
      }
      _updateImage(count, millisecond);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _disposed = true;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IndexedStack(
        index: showIndex,
        children: images,
      ),
    );
  }
}
