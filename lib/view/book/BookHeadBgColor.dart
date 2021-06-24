import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

class BookHeadBgColor extends StatefulWidget {
  final String imgUrl;
  BookHeadBgColor(this.imgUrl);
  @override
  _BookHeadBgColorState createState() => _BookHeadBgColorState();
}

class _BookHeadBgColorState extends State<BookHeadBgColor> {
  Color color;
  @override
  void initState() {
    super.initState();

    getBkColor();
  }

  getBkColor() async {
    PaletteGenerator.fromImageProvider(
            CachedNetworkImageProvider(this.widget.imgUrl))
        .then((fromImageProvider) {
      if (mounted) {
        setState(() {
          if (fromImageProvider.colors.isNotEmpty) {
            color = fromImageProvider.colors.first;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: color != null,
      child: Container(
        decoration:
            BoxDecoration(color: color ?? Theme.of(context).primaryColor),
      ),
    );
  }
}
