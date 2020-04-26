import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class PicWidget extends StatelessWidget {
  String url;
  double height;
  double width;
  bool fitOk;

  PicWidget(this.url, {this.height, this.width, this.fitOk});

  @override
  Widget build(BuildContext context) {

    if (fitOk??false) {
      return ExtendedImage.network(
        url,
        fit: BoxFit.cover,
        cache: true,
        retries: 1,
        loadStateChanged: (ExtendedImageState state) {
          switch (state.extendedImageLoadState) {
            case LoadState.loading:
              return null;
              break;

            case LoadState.completed:
              return null;
              break;
            case LoadState.failed:
              return Image.asset(
                "images/nocover.jpg",
                width: 80,
                height: 100,
              );
              break;
          }
        },
      );
    } else {
      return ExtendedImage.network(
        url,
        height: height ?? 100,
        width: width ?? 80,
        fit: BoxFit.cover,
        cache: true,
        retries: 1,
        loadStateChanged: (ExtendedImageState state) {
          switch (state.extendedImageLoadState) {
            case LoadState.loading:
              return null;
              break;

            case LoadState.completed:
              return null;
              break;
            case LoadState.failed:
              return Image.asset(
                "images/nocover.jpg",
                width: 80,
                height: 100,
              );
              break;
          }
        },
      );
    }
  }
}
