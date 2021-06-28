import 'dart:async';

import 'package:book/common/common.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ReadModel.dart';
import 'package:book/store/Store.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';

/// 导航翻页模式
class NovelRoteView extends StatelessWidget {
  ReadModel readModel;

  @override
  Widget build(BuildContext context) {
    readModel = Store.value<ReadModel>(context);

    return GestureDetector(
        onTap: () {},
        onTapDown: (e) => readModel.tapPage(context, e),
        // onHorizontalDragStart: (details) =>
        //     readModel.onHorizontalDragStart(details),
        // onHorizontalDragEnd: (details) =>
        //     readModel.onHorizontalDragEnd(details),
        // onHorizontalDragUpdate: (details) =>
        //     readModel.onHorizontalDragUpdate(details),
        // onPanDown: (DragDownDetails e) {
        //   //打印手指按下的位置
        //   print("手指按下：${e.globalPosition}");
        //   dx = e.globalPosition.dx;
        // },
        // //手指滑动
        // onPanUpdate: (DragUpdateDetails e) {
        //   // print("update ${e.globalPosition}");
        //   var z = e.globalPosition.dx - dx;
        //   if (z > 0) {
        //     print("pre");
        //   } else {
        //     print("next");
        //     eventBus.fire(ScrollEvent(0));
        //   }
        // },
        onPanEnd: (DragEndDetails e) {
          //打印滑动结束时在x、y轴上的速度
          // print("end");
          var x = e.velocity.pixelsPerSecond.dx < 0 ? 1 : -1;
          // print(x);
          readModel.changeCoverPage(x);
        },
        child: Navigator(
            // initialRoute: '/${searchItem.durChapterIndex}',
            onGenerateRoute: (settings) {
          WidgetBuilder builder;
          bool isNext = true;
          switch (settings.name) {
            case '/up':
              builder = (context) => _CoverPage(owner: this);
              isNext = false;
              break;
            default:
              builder = (context) => _CoverPage(owner: this);
              break;
          }
          // if (profile.novelPageSwitch == Profile.novelFade) {
          //   return FadePageRoute(
          //       builder: builder, milliseconds: 350, isNext: isNext);
          // }
          // if (profile.novelPageSwitch == Profile.novelCover) {
          //   return EmptyPageRoute(builder: builder);
          // }
          return MaterialPageRoute(builder: builder);
        }));
  }
}

class _CoverPage extends StatefulWidget {
  final NovelRoteView owner;
  const _CoverPage({Key key, this.owner}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _CoverPageState();
}

class _CoverPageState extends State<_CoverPage> with TickerProviderStateMixin {
  NovelRoteView owner;
  Widget lastPage;
  int lastPageIndex, lastChapterIndex, lastChangeTime;
  double x = 0;
  AnimationController _controller;
  Animation<double> _animation;


  @override
  void initState() {

    eventBus.on<ZEvent>().listen((event) {
      if (event.off == 200) {
        _controller?.dispose();
        _controller = null;
        _animation = null;
      } else {
        lastPage = null;
      }
    });
    if (_controller == null) {
      _controller = AnimationController(
        vsync: this,
        duration: Duration(
            milliseconds: SpUtil.getBool(Common.turnPageAnima, defValue: false)
                ? 300
                : 0),
      );
      _animation = CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      );
    }
    super.initState();
    owner = widget.owner;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (lastPage != null) {
      // owner.provider.showMenu
      bool isChangePage = (lastPageIndex != owner.readModel.book.index ||
          lastChapterIndex != owner.readModel.book.cur);
      if (isChangePage) {
        if (_controller == null) {
          _controller = AnimationController(
            vsync: this,
            duration: Duration(
                milliseconds:
                    SpUtil.getBool(Common.turnPageAnima, defValue: false)
                        ? 300
                        : 0),
          );
          _animation = CurvedAnimation(
            parent: _controller,
            curve: Curves.linear,
          );
        }

        bool _isNext = isNext;
        var _last = lastPage;
        lastPage = buildPage();
        // bool v = SpUtil.getBool(Common.turnPageAnima, defValue: false);
        if (_isNext)
          _controller.forward(from: 0.0);
        else
          _controller.forward(from: -1.2);

        return Stack(
          children: _isNext
              ? [
                  lastPage,
                  SlideTransition(
                      position: _animation.drive(
                          Tween(end: Offset(-1.1, .0), begin: Offset.zero)
                              .chain(CurveTween(curve: Curves.easeIn))),
                      child: _last),
                ]
              : [
                  _last,
                  SlideTransition(
                      position: _animation.drive(
                          Tween(begin: Offset(-1.1, .0), end: Offset.zero)
                              .chain(CurveTween(curve: Curves.easeIn))),
                      child: lastPage),
                ],
        );
      }
      return lastPage;
    }
    lastPage = buildPage();
    return lastPage;
  }

  Widget buildPage() {
    lastPageIndex = owner.readModel.book.index;
    lastChapterIndex = owner.readModel.book.cur;
    return owner.readModel
        .getPage();
  }

  int get curChapterIndex => owner.readModel.book.cur;

  // 是否进入下一页
  bool get isNext => !(curChapterIndex < lastChapterIndex ||
      (curChapterIndex == lastChapterIndex &&
          lastPageIndex > owner.readModel.book.index));

  changePage() async {
    Timer(Duration(milliseconds: 20), () {
      Navigator.pushReplacementNamed(context, isNext ? '/' : '/up');
    });
  }
}
