import 'package:flutter/material.dart';
import 'package:readmore/readmore.dart';

class TextEllipsis extends StatefulWidget {
  final String msg;

  TextEllipsis(this.msg);

  @override
  _TextEllipsisState createState() => _TextEllipsisState();
}

class _TextEllipsisState extends State<TextEllipsis> {
  bool ellipsis = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                '简介',
                style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),

              ),
              Spacer()
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 2),
          child: ReadMoreText(
            this.widget.msg,
            trimLines: 3,
            style: TextStyle(color: Colors.black),
            colorClickableText: Colors.blue,
            trimMode: TrimMode.Line,
            trimCollapsedText: 'more',
            trimExpandedText: 'less',
          ),
        )
      ],
    );
  }
}
