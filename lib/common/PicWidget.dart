import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class PicWidget extends StatelessWidget {
  String url;
  double height;
  double width;
  BoxFit fit;
  bool roll;

  PicWidget(this.url,
      {this.height = 115,
      this.width = 97,
      this.fit = BoxFit.cover,
      this.roll = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      //    decoration: BoxDecoration(shape: BoxShape.rectangle, boxShadow: [
      //   BoxShadow(color: Colors.grey[300],offset: Offset(1, 1),blurRadius: 3,),
      //   BoxShadow(color: Colors.grey[300], offset: Offset(-1, -1), blurRadius: 3),
      //   BoxShadow(color: Colors.grey[300], offset: Offset(1, -1), blurRadius: 3),
      //   BoxShadow(color: Colors.grey[300], offset: Offset(-1, 1), blurRadius: 3)
      // ]),
      child: ExtendedImage.network(url,
          fit: this.fit,
          loadStateChanged: (ExtendedImageState state) {
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            return null;
            break;
          case LoadState.completed:
            return ExtendedRawImage(
              image: state.extendedImageInfo?.image,
              width: this.width,
              height: this.height,
              fit: BoxFit.cover,
            );
            break;
          case LoadState.failed:
            return Image.asset(
              "images/nocover.jpg",
              fit: BoxFit.fill,
            );
            break;
        }
      }),
    );
  }
}
