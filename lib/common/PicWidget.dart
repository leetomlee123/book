import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class PicWidget extends StatelessWidget {
  String url;

  PicWidget(this.url);

  @override
  Widget build(BuildContext context) {
    return ExtendedImage.network(
      url,
      height: 100,
      width: 80,
      fit: BoxFit.fill,
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
            return Image.asset("images/nocover.jpg",width: 80,height: 100,);
            break;
        }
      },
    );
  }
}
