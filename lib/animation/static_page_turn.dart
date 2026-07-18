import 'package:book/animation/BaseAnimationPage.dart';
import 'package:book/view/newBook/touch_event.dart';
import 'package:flutter/material.dart';

/// 无翻页动画：始终绘制当前页；在抬手时按滑动方向切页。
///
/// 预留动画接口：`BaseAnimationPage` 仍可挂 Cover/Simulation 等实现。
class StaticPageTurn extends BaseAnimationPage {
  Offset _down = Offset.zero;
  bool _moved = false;

  @override
  void onDraw(Canvas canvas) {
    final pic = readerViewModel.cur();
    if (pic != null) {
      canvas.drawPicture(pic);
    }
  }

  @override
  void onTouchEvent(TouchEvent event) {
    switch (event.action) {
      case TouchEvent.ACTION_DOWN:
        mTouch = event.touchPos;
        _down = event.touchPos;
        _moved = false;
        break;
      case TouchEvent.ACTION_MOVE:
        mTouch = event.touchPos;
        if ((event.touchPos.dx - _down.dx).abs() > 8) {
          _moved = true;
        }
        break;
      case TouchEvent.ACTION_UP:
      case TouchEvent.ACTION_CANCEL:
        final dx = mTouch.dx - _down.dx;
        final threshold = currentSize.width / 12;
        if (_moved && dx.abs() > threshold) {
          if (dx < 0) {
            if (isCanGoNext()) readerViewModel.changeCoverPage(1);
          } else {
            if (isCanGoPre()) readerViewModel.changeCoverPage(-1);
          }
        }
        mTouch = Offset.zero;
        _moved = false;
        break;
    }
  }

  @override
  bool isCancelArea() => false;

  @override
  bool isConfirmArea() => false;

  @override
  Animation<Offset>? getCancelAnimation(
      AnimationController controller, GlobalKey canvasKey) {
    return null;
  }

  @override
  Animation<Offset>? getConfirmAnimation(
      AnimationController controller, GlobalKey canvasKey) {
    return null;
  }

  @override
  Simulation? getFlingAnimationSimulation(
      AnimationController controller, DragEndDetails details) {
    return null;
  }
}
