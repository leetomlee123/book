import 'package:book/common/local_store.dart';
import 'package:flutter/material.dart';
import 'package:readmore/readmore.dart';

class TextEllipsis extends StatefulWidget {
  final String msg;

  const TextEllipsis(this.msg, {super.key});

  @override
  State<TextEllipsis> createState() => _TextEllipsisState();
}

class _TextEllipsisState extends State<TextEllipsis> {
  bool ellipsis = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 10),
          child: Row(
            children: [
              Text(
                '简介',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              Spacer()
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 2),
          child: ReadMoreText(
            widget.msg,
            trimLines: 3,
            colorClickableText: Colors.blue,
            trimMode: TrimMode.Line,
            style: TextStyle(
                color: SpUtil.getBool("dark") ? Colors.white : Colors.black),
          ),
        )
      ],
    );
  }
}
