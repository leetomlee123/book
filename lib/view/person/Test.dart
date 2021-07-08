import 'package:book/common/Screen.dart';
import 'package:book/model/ReadModel.dart';
import 'package:book/store/Store.dart';
import 'package:flutter/material.dart';

class MyPageView extends StatefulWidget {
  @override
  _MyPageViewState createState() => _MyPageViewState();
}

class _MyPageViewState extends State<MyPageView>
    with SingleTickerProviderStateMixin {
  Animation<double> _animation;
  AnimationController _controller;
  Offset _initialSwipeOffset;
  Offset _finalSwipeOffset;
  void _onHorizontalDragStart(DragStartDetails details) {
    _initialSwipeOffset = details.globalPosition;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    _finalSwipeOffset = details.globalPosition;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_initialSwipeOffset != null) {
      final offsetDifference = _initialSwipeOffset.dx - _finalSwipeOffset.dx;
      offsetDifference > 0
          ? _controller.forward(from: 0.0)
          : _controller.forward(from: -1.2);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class Con extends StatelessWidget {
  final Color color;
  final String text;

  Con(this.color, this.text);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        color: color,
        width: Screen.width,
        height: Screen.height,
        child: Center(child: Text(text)),
      ),
    );
  }
}
