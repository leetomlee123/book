import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

class PicWidget extends StatelessWidget {
  final String url;
  final double height;
  final double width;
  final BoxFit fit;
  final bool roll;
  final double radius;

  PicWidget(this.url,
      {this.height = 115,
      this.width = 97,
      this.fit = BoxFit.cover,
      this.roll = false,
      this.radius = 0});

  @override
  Widget build(BuildContext context) {
    Widget child = ExtendedImage.network(url, fit: this.fit,
        loadStateChanged: (ExtendedImageState state) {
      switch (state.extendedImageLoadState) {
        case LoadState.loading:
          return Image.asset(
            "images/nocover.jpg",
            width: this.width,
            height: this.height,
            fit: BoxFit.cover,
          );
        case LoadState.completed:
          return ExtendedRawImage(
            image: state.extendedImageInfo?.image,
            width: this.width,
            height: this.height,
            fit: BoxFit.cover,
          );
        case LoadState.failed:
          return Image.asset(
            "images/nocover.jpg",
            width: this.width,
            height: this.height,
            fit: BoxFit.cover,
          );
      }
    });

    if (radius > 0) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      );
    }
    return SizedBox(width: width, height: height, child: child);
  }
}
