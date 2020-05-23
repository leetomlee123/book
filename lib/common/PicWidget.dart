import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class PicWidget extends StatelessWidget {
  String url;
  double height;
  double width;
  bool fitOk;

  PicWidget(this.url, {this.height = 100, this.width = 80, this.fitOk});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(

      imageUrl: url,
      imageBuilder: (context, imageProvider) => ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
            ),
          ),

        ),
      ),
      errorWidget: (context, url, error) => Image.asset(
        "images/nocover.jpg",
        width: width,
        height: height,
      ),
    );
  }
}
