import 'package:book/animation/BaseAnimationPage.dart';
import 'package:book/view/newBook/touch_event.dart';
import 'package:flutter/material.dart';

/// 无翻页动画：始终绘制当前页。
///
/// **Does not call changeCoverPage.** [ReaderPageManager.finishSwipe] reads
/// [consumeSwipeDirection] and commits once.
class StaticPageTurn extends BaseAnimationPage {
  Offset _down = Offset.zero;
  Offset _last = Offset.zero;
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
        _last = event.touchPos;
        _moved = false;
        break;
      case TouchEvent.ACTION_MOVE:
        mTouch = event.touchPos;
        _last = event.touchPos;
        if ((event.touchPos.dx - _down.dx).abs() > 8) {
          _moved = true;
        }
        break;
      case TouchEvent.ACTION_CANCEL:
        mTouch = Offset.zero;
        _moved = false;
        break;
      case TouchEvent.ACTION_UP:
        mTouch = event.touchPos;
        _last = event.touchPos;
        // Direction is consumed by Manager; do not commit here.
        break;
    }
  }

  /// Returns +1 / -1 / 0 based on the last gesture; clears move state.
  int consumeSwipeDirection() {
    if (!_moved) {
      mTouch = Offset.zero;
      return 0;
    }
    final dx = _last.dx - _down.dx;
    final threshold = currentSize.width / 12;
    _moved = false;
    mTouch = Offset.zero;
    if (dx.abs() <= threshold) return 0;
    if (dx < 0) {
      return isCanGoNext() ? 1 : 0;
    }
    return isCanGoPre() ? -1 : 0;
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
