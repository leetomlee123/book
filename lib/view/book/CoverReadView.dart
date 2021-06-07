import 'package:book/common/Screen.dart';
import 'package:book/model/ReadModel.dart';
import 'package:book/store/Store.dart';
import 'package:flutter/material.dart';

class CoverReadView extends StatefulWidget {
  @override
  _CoverReadViewState createState() => _CoverReadViewState();
}

class _CoverReadViewState extends State<CoverReadView>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _animation;
  Widget lastPage;
  ReadModel readModel;

  @override
  void initState() {
    super.initState();
    if (_controller == null) {
      _controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400),
      );
      _animation = CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      );
    }
    readModel = Store.value<ReadModel>(context);
  }

  @override
  void dispose() {
    _controller?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Store.connect<ReadModel>(
        builder: (context, ReadModel readModel, child) {
      return GestureDetector(
        child: Stack(children: [
          readModel.bottomWidget,
          SlideTransition(
              position: _animation.drive(
                  Tween(end: Offset(-1.1, 0.0), begin: Offset.zero)
                      .chain(CurveTween(curve: Curves.linear))),
              child: readModel.topWidget),
        ]),
        behavior: HitTestBehavior.opaque,
        onTapDown: (TapDownDetails details) async {
          var wid = Screen.width;
          var hSpace = Screen.height / 4;
          var space = wid / 3;
          var curWid = details.globalPosition.dx;
          var curH = details.globalPosition.dy;

          if ((curWid > 0 && curWid < space)) {
            // if (leftClickNext) {
            //   pageController.nextPage(
            //       duration: Duration(microseconds: 1), curve: Curves.ease);
            //   return;
            // }

            _controller.reverse(from: -1.2);
            await readModel.pre();
          } else if ((curWid > space) &&
              (curWid < 2 * space) &&
              (curH < hSpace * 3)) {
            readModel.toggleShowMenu();
          } else if ((curWid > space * 2)) {
            // if (leftClickNext) {
            //   pageController.nextPage(
            //       duration: Duration(microseconds: 1), curve: Curves.ease);
            //   return;
            // }
            _controller.forward(from: 0.0);
            await readModel.next();
          }
        },
        onHorizontalDragStart: readModel.onHorizontalDragStart,
        onHorizontalDragUpdate: readModel.onHorizontalDragUpdate,
        onHorizontalDragEnd: readModel.onHorizontalDragEnd,
      );
    });
  }
}
