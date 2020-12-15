import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class PicWidget extends StatelessWidget {
  String url;
  double height;
  double width;
  bool fitOk;
  bool roll;

  PicWidget(this.url,
      {this.height = 115, this.width = 97, this.fitOk, this.roll = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      //    decoration: BoxDecoration(shape: BoxShape.rectangle, boxShadow: [
      //   BoxShadow(color: Colors.grey[300],offset: Offset(1, 1),blurRadius: 3,),
      //   BoxShadow(color: Colors.grey[300], offset: Offset(-1, -1), blurRadius: 3),
      //   BoxShadow(color: Colors.grey[300], offset: Offset(1, -1), blurRadius: 3),
      //   BoxShadow(color: Colors.grey[300], offset: Offset(-1, 1), blurRadius: 3)
      // ]),
      child: CachedNetworkImage(
        imageUrl: url,
        imageBuilder: (context, imageProvider) => ClipRRect(
//        borderRadius: BorderRadius.circular(5),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius:
                  roll ? BorderRadius.circular(35) : BorderRadius.circular(0),
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
              borderRadius:
                  roll ? BorderRadius.circular(35) : BorderRadius.circular(0),
              image: DecorationImage(
                image: AssetImage(
                  "images/nocover.jpg",
                ),
                fit: BoxFit.cover,
              )),
        ),
      ),
    );
  }
}
