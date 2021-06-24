import 'package:book/model/ColorModel.dart';
import 'package:book/store/Store.dart';
import 'package:flutter/material.dart';

class LabelTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Store.connect<ColorModel>(
        builder: (context, ColorModel model, child) {
      return Padding(
        padding: EdgeInsets.only(left: 5.0, right: 3.0),
        child: Row(
          children: <Widget>[
            Container(
              width: 4,
              height: 20,
            ),
            SizedBox(
              width: 5,
            ),
            Text(
              title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
          ),
            ),
          ],
        ),
      );
    });
  }

  final String title;

  LabelTitle(this.title);
}
