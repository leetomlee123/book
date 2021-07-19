import 'dart:async';
import 'dart:ui' as ui;

import 'package:book/common/Screen.dart';
import 'package:book/common/common.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ReadModel.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';

/// 导航翻页模式
class NovelRoteView extends StatelessWidget {
  final ReadModel readModel;

  NovelRoteView(this.readModel);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {},
        onTapDown: (e) => readModel.tapPage(context, e),
        onPanEnd: (DragEndDetails e) {
          var x = e.velocity.pixelsPerSecond.dx < 0 ? 1 : -1;
          readModel.changeCoverPage(x);
        },
        child: Navigator(onGenerateRoute: (settings) {
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
  GlobalKey canvasKey = new GlobalKey();

  @override
  void initState() {
    eventBus.on<ZEvent>().listen((event) {
      if (mounted) {
        setState(() {
          if (event.off == 200) {
            _controller?.dispose();
            _controller = null;
            _animation = null;
          } else {
            lastPage = null;
          }
        });
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
    _controller?.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        //动画完成后预加载上下页面
        print("here");
        owner.readModel.preLoadWidget();
      }
    });
    super.initState();
    owner = widget.owner;
  }

  @override
  void dispose() {
    print("here dispose");
    _controller?.dispose();
    _controller?.removeStatusListener((status) {});
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
    lastPage = buildPage(firstLoad: true);
    return lastPage;
  }

  Widget buildPage({bool firstLoad = false}) {
    lastPageIndex = owner.readModel.book.index;
    lastChapterIndex = owner.readModel.book.cur;
    return CustomPaint(
      isComplex: true,
      size: Size(Screen.width, Screen.height),
      painter:
          PageContentViewPainter(owner.readModel.getPage(firstInit: firstLoad)),
    );
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

class PageContentViewPainter extends CustomPainter {
  final ui.Picture picture;

  PageContentViewPainter(this.picture);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPicture(picture);
  }

  @override
  bool shouldRepaint(PageContentViewPainter oldDelegate) {
    return this.picture != oldDelegate.picture;
  }
}
