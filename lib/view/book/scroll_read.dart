import 'package:book/common/Screen.dart';
import 'package:book/model/ReadModel.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/book/cover_read_view.dart';
import 'package:flutter/material.dart';

class ScrollReadView extends StatefulWidget {
  ScrollReadView({Key key}) : super(key: key);

  @override
  _ScrollReadViewState createState() => _ScrollReadViewState();
}

class _ScrollReadViewState extends State<ScrollReadView> {
  ReadModel readModel;
  @override
  void initState() {
    readModel = Store.value<ReadModel>(context);
    super.initState();
  }

  getWidget(var p) {
    return CustomPaint(
      isComplex: true,
      size: Size(Screen.width, Screen.height),
      painter: PageContentViewPainter(p),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListView(
        children: [
          getWidget(readModel.pre()),
          getWidget(readModel.cur()),
          getWidget(readModel.next()),
        ],
      ),
    );
  }
}
