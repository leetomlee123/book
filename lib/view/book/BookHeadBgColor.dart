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
  List<Color> colors = [];
  @override
  void initState() {
    super.initState();
    getBkColor();
  }

  getBkColor() async {
    PaletteGenerator fromImageProvider =
        await PaletteGenerator.fromImageProvider(
            CachedNetworkImageProvider(this.widget.imgUrl));
    fromImageProvider.paletteColors.forEach((element) {
      colors.add(element.color);
    });
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Offstage(
        offstage: colors.isEmpty,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
        ));
  }
}
