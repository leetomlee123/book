import 'dart:ui';

import 'package:book/animation/AnimationControllerWithListenerNumber.dart';
import 'package:book/animation/BaseAnimationPage.dart';
import 'package:book/view/newBook/ReaderPageManager.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

/// 覆盖动画 ///
class CoverPageAnimation extends BaseAnimationPage {
  static const int ORIENTATION_VERTICAL = 1;
  static const int ORIENTATION_HORIZONTAL = 0;

  bool isTurnNext = true;
  bool isStartAnimation = false;

  int coverDirection = ORIENTATION_HORIZONTAL;

  Offset mStartPoint = Offset(0, 0);

  Tween<Offset> currentAnimationTween;
  Animation<Offset> currentAnimation;

  ANIMATION_TYPE animationType;

  AnimationStatusListener statusListener;

  @override
  Animation<Offset> getCancelAnimation(
      AnimationController controller, GlobalKey canvasKey) {
    if ((!isTurnNext && !isCanGoPre()) || (isTurnNext && !isCanGoNext())) {
      return null;
    }

    if (currentAnimation == null) {
      buildCurrentAnimation(controller, canvasKey);
    }

    // currentAnimationTween.begin = (coverDirection == ORIENTATION_HORIZONTAL)
    //     ? Offset(mTouch.dx, 0)
    //     : Offset(0, mTouch.dy);
    currentAnimationTween.begin = Offset(mTouch.dx, 0);

    // currentAnimationTween.end = (coverDirection == ORIENTATION_HORIZONTAL)
    //     ? Offset(mStartPoint.dx, 0)
    //     : Offset(0, mStartPoint.dy);
    currentAnimationTween.end = Offset(mStartPoint.dx, 0);

    animationType = ANIMATION_TYPE.TYPE_CANCEL;

    return currentAnimation;
  }

  @override
  Animation<Offset> getConfirmAnimation(
      AnimationController controller, GlobalKey canvasKey) {
    if (!isTurnNext && !isCanGoPre()) {
      BotToast.showText(text: "已经是第一页");

      return null;
    }
    if (isTurnNext && !isCanGoNext()) {
      BotToast.showText(text: "已经是最后一页");

      return null;
    }
    if (currentAnimation == null) {
      buildCurrentAnimation(controller, canvasKey);
    }

    /// 很神奇的一点，这个监听器有时会自己变成null……偶发性的，试了好多次也没找到如何触发的……但它就是存在变成null的情况
    /// 所以要检测一下，变成null了就给它弄回去
    if (statusListener == null) {
      statusListener = (status) {
        switch (status) {
          case AnimationStatus.dismissed:
            break;
          case AnimationStatus.completed:
            if (animationType == ANIMATION_TYPE.TYPE_CONFIRM) {
              canvasKey.currentContext.findRenderObject().markNeedsPaint();

              if (isTurnNext) {
                readerViewModel.changeCoverPage(1);
              } else {
                readerViewModel.changeCoverPage(-1);
              }
            }
            break;
          case AnimationStatus.forward:
          case AnimationStatus.reverse:
            break;
        }
      };
      currentAnimation.addStatusListener(statusListener);
    }

    if (statusListener != null &&
        !(controller as AnimationControllerWithListenerNumber)
            .statusListeners
            .contains(statusListener)) {
      currentAnimation.addStatusListener(statusListener);
    }
    currentAnimationTween.begin = Offset(mTouch.dx, 0);
    currentAnimationTween.end = Offset(
        isTurnNext
            ? mStartPoint.dx - currentSize.width
            : currentSize.width + mStartPoint.dx,
        0);
    animationType = ANIMATION_TYPE.TYPE_CONFIRM;

    return currentAnimation;
  }

  @override
  void onDraw(Canvas canvas) {
    if (isStartAnimation && (mTouch.dx != 0 || mTouch.dy != 0)) {
      drawBottomPage(canvas);
      drawCurrentShadow(canvas);
      drawTopPage(canvas);
    } else {
      drawStatic(canvas);
    }

    isStartAnimation = false;
  }

  @override
  void onTouchEvent(TouchEvent event) {
    if (event.touchPos != null) {
      mTouch = event.touchPos;
    }

    switch (event.action) {
      case TouchEvent.ACTION_DOWN:
        mStartPoint = event.touchPos;
        break;
      case TouchEvent.ACTION_MOVE:
      case TouchEvent.ACTION_UP:
      case TouchEvent.ACTION_CANCEL:
        isTurnNext = mTouch.dx - mStartPoint.dx < 0;
        // print("isTurnNext $isTurnNext mTouch.dx  ${mTouch.dx}  mStartPoint.dx ${mStartPoint.dx}");
        if ((!isTurnNext && isCanGoPre()) || (isTurnNext && isCanGoNext())) {
          isStartAnimation = true;
        }
        break;
      default:
        break;
    }
  }

  void drawStatic(Canvas canvas) {
    canvas.drawPicture(readerViewModel.cur());
  }

  void drawBottomPage(Canvas canvas) {
    canvas.save();
    if (isTurnNext) {
      canvas.drawPicture(readerViewModel.next());
    } else {
      canvas.drawPicture(readerViewModel.cur());
    }
    canvas.restore();
  }

  void drawTopPage(Canvas canvas) {
    canvas.save();

    if (isTurnNext) {
      canvas.translate(mTouch.dx - mStartPoint.dx, 0);
      canvas.drawPicture(readerViewModel.cur());
    } else {
      canvas.translate((mTouch.dx - mStartPoint.dx) - currentSize.width, 0);
      canvas.drawPicture(readerViewModel.pre());
    }

    canvas.restore();
  }

  void drawCurrentShadow(Canvas canvas) {
    canvas.save();

    Gradient shadowGradient;

    // if (coverDirection == ORIENTATION_HORIZONTAL) {
    shadowGradient = new LinearGradient(
      colors: [
        Colors.black54,
        Colors.transparent,
      ],
    );
    if (isTurnNext) {
      Rect rect = Rect.fromLTRB(
          currentSize.width + mTouch.dx - mStartPoint.dx,
          0,
          currentSize.width + mTouch.dx - mStartPoint.dx + 15,
          currentSize.height);
      var shadowPaint = Paint()
        ..isAntiAlias = false
        ..style = PaintingStyle.fill //填充
        ..shader = shadowGradient.createShader(rect);

      canvas.drawRect(rect, shadowPaint);
    } else {
      Rect rect = Rect.fromLTRB((mTouch.dx - mStartPoint.dx), 0,
          (mTouch.dx - mStartPoint.dx) + 15, currentSize.height);
      var shadowPaint = Paint()
        ..isAntiAlias = false
        ..style = PaintingStyle.fill //填充
        ..shader = shadowGradient.createShader(rect);

      canvas.drawRect(rect, shadowPaint);
    }
    // } else {
    //   shadowGradient = new LinearGradient(
    //     begin: Alignment.topRight,
    //     colors: [
    //       Color(0xAA000000),
    //       Colors.transparent,
    //     ],
    //   );
    //   if (isTurnNext) {
    //     Rect rect = Rect.fromLTRB(
    //         0,
    //         currentSize.height - (mStartPoint.dy - mTouch.dy),
    //         currentSize.width,
    //         currentSize.height - (mStartPoint.dy - mTouch.dy) + 20);
    //     var shadowPaint = Paint()
    //       ..isAntiAlias = false
    //       ..style = PaintingStyle.fill //填充
    //       ..shader = shadowGradient.createShader(rect);
    //
    //     canvas.drawRect(rect, shadowPaint);
    //   } else {
    //     Rect rect = Rect.fromLTRB(0, -(mStartPoint.dy - mTouch.dy),
    //         currentSize.width, -(mStartPoint.dy - mTouch.dy) + 20);
    //     var shadowPaint = Paint()
    //       ..isAntiAlias = false
    //       ..style = PaintingStyle.fill //填充
    //       ..shader = shadowGradient.createShader(rect);
    //
    //     canvas.drawRect(rect, shadowPaint);
    //   }
    // }

    canvas.restore();
  }

  @override
  Simulation getFlingAnimationSimulation(
      AnimationController controller, DragEndDetails details) {
    return null;
  }

  @override
  bool isCancelArea() {
    return (mTouch.dx - mStartPoint.dx).abs() < (currentSize.width / 15);
  }

  @override
  bool isConfirmArea() {
    return (mTouch.dx - mStartPoint.dx).abs() > (currentSize.width / 15);
  }

  void buildCurrentAnimation(
      AnimationController controller, GlobalKey canvasKey) {
    currentAnimationTween = Tween(begin: Offset.zero, end: Offset.zero);

    currentAnimation = currentAnimationTween.animate(controller);
  }
}
