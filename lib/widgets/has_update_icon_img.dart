import 'package:book/common/PicWidget.dart';
import 'package:book/entity/Book.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/store/Store.dart';
import 'package:flutter/material.dart';

class HasUpdateIconImg extends StatelessWidget {
  final double width;
  final double height;
  final String type;
  final int idx;

  const HasUpdateIconImg(this.width, this.height, this.type, this.idx);

  @override
  Widget build(BuildContext context) {
    return Store.connect<ShelfModel>(
        builder: (context, ShelfModel shelf, child) {
      Book _book = shelf.shelf[this.idx];
      return Stack(
        children: <Widget>[
          PicWidget(_book.Img, height: this.height, width: this.width),
          Offstage(
            offstage: _book.NewChapterCount != 1,
            child: Container(
              height: this.height,
              width: this.width,
              child: Align(
                alignment: Alignment.topRight,
                child: Image.asset(
                  'images/h6.png',
                  width: 30,
                  height: 30,
                ),
              ),
            ),
          ),
          Visibility(
            visible: this.type == "sort",
            child: Container(
              height: this.height,
              width: this.width,
              child: Align(
                  alignment: Alignment.bottomRight,
                  child: Image.asset(
                    'images/pick.png',
                    width: 30,
                    height: 30,
                    color: !shelf.picks(this.idx)
                        ? Colors.white
                        : Theme.of(context).primaryColor,
                  )),
            ),
          ),
        ],
      );
    });
  }
}
