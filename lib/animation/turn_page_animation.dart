import 'package:book/animation/BaseAnimationPage.dart';
import 'package:book/view/newBook/touch_event.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

/// 覆盖翻页：拖动时顶页平移露出底页，松手确认/取消。
///
/// 切页由 [ReaderPageManager] 在动画完成后统一提交，本类不调用 changeCoverPage。
class CoverPageAnimation extends BaseAnimationPage {
  bool isTurnNext = true;
  bool isDragging = false;

  Offset mStartPoint = Offset.zero;

  Tween<Offset>? currentAnimationTween;
  Animation<Offset>? currentAnimation;

  ANIMATION_TYPE? animationType;

  void _ensureAnimation(AnimationController controller) {
    if (currentAnimation != null) return;
    currentAnimationTween = Tween(begin: Offset.zero, end: Offset.zero);
    currentAnimation = currentAnimationTween!.animate(controller);
  }

  void _resetGesture() {
    isDragging = false;
    mTouch = Offset.zero;
    mStartPoint = Offset.zero;
    animationType = null;
  }

  @override
  Animation<Offset>? getCancelAnimation(
      AnimationController controller, GlobalKey canvasKey) {
    if ((!isTurnNext && !isCanGoPre()) || (isTurnNext && !isCanGoNext())) {
      return null;
    }
    _ensureAnimation(controller);
    currentAnimationTween!.begin = Offset(mTouch.dx, 0);
    currentAnimationTween!.end = Offset(mStartPoint.dx, 0);
    animationType = ANIMATION_TYPE.TYPE_CANCEL;
    return currentAnimation;
  }

  @override
  Animation<Offset>? getConfirmAnimation(
      AnimationController controller, GlobalKey canvasKey) {
    if (!isTurnNext && !isCanGoPre()) {
      BotToast.showText(text: '已经是第一页');
      return null;
    }
    if (isTurnNext && !isCanGoNext()) {
      BotToast.showText(text: '已经是最后一页');
      return null;
    }
    _ensureAnimation(controller);
    currentAnimationTween!.begin = Offset(mTouch.dx, 0);
    currentAnimationTween!.end = Offset(
      isTurnNext
          ? mStartPoint.dx - currentSize.width
          : currentSize.width + mStartPoint.dx,
      0,
    );
    animationType = ANIMATION_TYPE.TYPE_CONFIRM;
    return currentAnimation;
  }

  @override
  void onDraw(Canvas canvas) {
    // Draw animated layers while dragging OR while confirm/cancel runs.
    final animating = animationType != null;
    if ((isDragging || animating) && (mTouch.dx != 0 || mTouch.dy != 0)) {
      drawBottomPage(canvas);
      drawCurrentShadow(canvas);
      drawTopPage(canvas);
    } else {
      drawStatic(canvas);
    }
  }

  @override
  void onTouchEvent(TouchEvent event) {
    if (event.action == TouchEvent.ACTION_CANCEL) {
      _resetGesture();
      return;
    }

    mTouch = event.touchPos;
    switch (event.action) {
      case TouchEvent.ACTION_DOWN:
        mStartPoint = event.touchPos;
        isDragging = false;
        break;
      case TouchEvent.ACTION_MOVE:
        final dx = mTouch.dx - mStartPoint.dx;
        if (dx.abs() < 2) break;
        isTurnNext = dx < 0;
        if ((!isTurnNext && isCanGoPre()) || (isTurnNext && isCanGoNext())) {
          isDragging = true;
        }
        break;
      case TouchEvent.ACTION_UP:
        final dx = mTouch.dx - mStartPoint.dx;
        isTurnNext = dx < 0;
        if ((!isTurnNext && isCanGoPre()) || (isTurnNext && isCanGoNext())) {
          isDragging = true;
        }
        break;
      default:
        break;
    }
  }

  void drawStatic(Canvas canvas) {
    final pic = readerViewModel.cur();
    if (pic != null) canvas.drawPicture(pic);
  }

  void drawBottomPage(Canvas canvas) {
    canvas.save();
    final pic = isTurnNext ? readerViewModel.next() : readerViewModel.cur();
    if (pic != null) canvas.drawPicture(pic);
    canvas.restore();
  }

  void drawTopPage(Canvas canvas) {
    canvas.save();
    if (isTurnNext) {
      canvas.translate(mTouch.dx - mStartPoint.dx, 0);
      final pic = readerViewModel.cur();
      if (pic != null) canvas.drawPicture(pic);
    } else {
      canvas.translate((mTouch.dx - mStartPoint.dx) - currentSize.width, 0);
      final pic = readerViewModel.pre();
      if (pic != null) canvas.drawPicture(pic);
    }
    canvas.restore();
  }

  void drawCurrentShadow(Canvas canvas) {
    canvas.save();
    const shadowGradient = LinearGradient(
      colors: [Colors.black54, Colors.transparent],
    );
    if (isTurnNext) {
      final rect = Rect.fromLTRB(
        currentSize.width + mTouch.dx - mStartPoint.dx,
        0,
        currentSize.width + mTouch.dx - mStartPoint.dx + 15,
        currentSize.height,
      );
      final shadowPaint = Paint()
        ..isAntiAlias = false
        ..style = PaintingStyle.fill
        ..shader = shadowGradient.createShader(rect);
      canvas.drawRect(rect, shadowPaint);
    } else {
      final rect = Rect.fromLTRB(
        mTouch.dx - mStartPoint.dx,
        0,
        (mTouch.dx - mStartPoint.dx) + 15,
        currentSize.height,
      );
      final shadowPaint = Paint()
        ..isAntiAlias = false
        ..style = PaintingStyle.fill
        ..shader = shadowGradient.createShader(rect);
      canvas.drawRect(rect, shadowPaint);
    }
    canvas.restore();
  }

  @override
  Simulation? getFlingAnimationSimulation(
      AnimationController controller, DragEndDetails details) {
    return null;
  }

  @override
  bool isCancelArea() {
    return (mTouch.dx - mStartPoint.dx).abs() < (currentSize.width / 15);
  }

  @override
  bool isConfirmArea() {
    return (mTouch.dx - mStartPoint.dx).abs() >= (currentSize.width / 15);
  }
}
