// 播放图片动画
import 'package:book/model/ColorModel.dart';
import 'package:book/store/Store.dart';
import 'package:flutter/material.dart';

class AnimationImages extends StatefulWidget {
  @override
  _AnimationImagesState createState() => _AnimationImagesState();
}

class _AnimationImagesState extends State<AnimationImages> {
  // 显示的 image
  int showIndex = 0;
  bool _disposed;
  List<Image> images = [];
  ColorModel _colorModel;

  @override
  void initState() {
    _colorModel = Store.value<ColorModel>(context);
    super.initState();
    for (int i = 0; i <= 29; i++) {
      String prefix = i.toString();
      if (i <= 9) {
        prefix = "0" + prefix;
      }
      images.add(Image.asset("images/loading_000$prefix.png",color: _colorModel.theme.primaryColor));
    }
    _disposed = false;
    Future.delayed(Duration(milliseconds: 200), () {
      _updateImage(images.length, Duration(milliseconds: 80));
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
