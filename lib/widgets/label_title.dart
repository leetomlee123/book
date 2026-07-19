import 'package:flutter/material.dart';

class LabelTitle extends StatelessWidget {
  final String title;
  const LabelTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 5.0, right: 3.0),
      child: Row(
        children: <Widget>[
          SizedBox(width: 4, height: 20),
          SizedBox(width: 5),
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
