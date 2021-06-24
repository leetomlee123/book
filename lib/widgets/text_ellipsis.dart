import 'package:book/model/ColorModel.dart';
import 'package:book/store/Store.dart';
import 'package:book/widgets/text_two.dart';
import 'package:flutter/material.dart';

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
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: Row(
            children: [
              Text(
                '简介',
                style: TextStyle(fontSize: 15),
              ),
              Spacer(),
              GestureDetector(
                child: Text(
                  "${ellipsis ? "展开" : "收起"}",
             
                ),
                onTap: () {
                  if (mounted) {
                    setState(() {
                      ellipsis = !ellipsis;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 2),
          child: TextTwo(
            this.widget.msg,
            maxLines: ellipsis ? 3 : 20,
          ),
        )
      ],
    );
  }
}
