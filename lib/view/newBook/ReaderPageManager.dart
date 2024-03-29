import 'dart:ui';

import 'package:book/animation/BaseAnimationPage.dart';
import 'package:book/animation/SimulationTurePageAnimation.dart';
import 'package:book/animation/turn_page_animation.dart';
import 'package:book/common/Screen.dart';
import 'package:book/model/ReadModel.dart';
import 'package:book/view/newBook/NovelPagePainter.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';

class ReaderPageManager {
  static const TYPE_ANIMATION_SIMULATION_TURN = 1;
  static const TYPE_ANIMATION_COVER_TURN = 2;
  static const TYPE_ANIMATION_SLIDE_TURN = 3;

  BaseAnimationPage currentAnimationPage;
  TouchEvent currentTouchData;
  int currentAnimationType = 0;

  STATE currentState;

  GlobalKey canvasKey;

  AnimationController animationController;

//  Animation<Offset> animation;

  void setCurrentTouchEvent(TouchEvent event) {
    /// 如果正在执行动画，判断是否需要中止动画
    if (currentState == STATE.STATE_ANIMATING) {
      if (currentAnimationPage.isShouldAnimatingInterrupt()) {
        if (event.action == TouchEvent.ACTION_DOWN) {
          interruptCancelAnimation();
        }
      } else {
        return;
      }
    }

    /// 用户抬起手指后，是否需要执行动画
    if (event.action == TouchEvent.ACTION_UP ||
        event.action == TouchEvent.ACTION_CANCEL) {
      switch (currentAnimationType) {
        case TYPE_ANIMATION_SIMULATION_TURN:
        case TYPE_ANIMATION_COVER_TURN:
          if (currentAnimationPage.isCancelArea()) {
            startCancelAnimation();
          } else if (currentAnimationPage.isConfirmArea()) {
            startConfirmAnimation();
          }
          break;
        case TYPE_ANIMATION_SLIDE_TURN:
          startFlingAnimation(event.touchDetail);
          break;
        default:
          break;
      }
    } else {
      currentTouchData = event;

      currentAnimationPage.onTouchEvent(currentTouchData);
    }
  }

  void setPageSize(Size size) {
    currentAnimationPage.setSize(size);
  }

  void setContentViewModel(ReadModel viewModel) {
    currentAnimationPage.setContentViewModel(viewModel);
  }

  void onPageDraw(Canvas canvas) {
    currentAnimationPage.onDraw(canvas);
  }

  setCurrentAnimation(int animationType) {
    currentAnimationType = animationType;
    switch (animationType) {
      case TYPE_ANIMATION_SIMULATION_TURN:
        currentAnimationPage = SimulationTurnPageAnimation();
        break;
      case TYPE_ANIMATION_COVER_TURN:
        currentAnimationPage = CoverPageAnimation();
        break;
      case TYPE_ANIMATION_SLIDE_TURN:
        // currentAnimationPage = SlidePageAnimation();
        break;
      default:
        break;
    }
  }

  int getCurrentAnimation() {
    return currentAnimationType;
  }

  void setCurrentCanvasContainerContext(GlobalKey canvasKey) {
    this.canvasKey = canvasKey;
  }

  void startConfirmAnimation() {
    Animation<Offset> animation = currentAnimationPage.getConfirmAnimation(
        animationController, canvasKey);

    if (animation == null) {
      return;
    }
    setAnimation(animation);

    animationController.forward();
  }

  void startCancelAnimation() {
    Animation<Offset> animation =
        currentAnimationPage.getCancelAnimation(animationController, canvasKey);

    if (animation == null) {
      return;
    }

    setAnimation(animation);

    animationController.forward();
  }

  void setAnimation(Animation<Offset> animation) {
    if (!animationController.isCompleted) {
      animation
        ..addListener(() {
          currentState = STATE.STATE_ANIMATING;
          canvasKey.currentContext?.findRenderObject()?.markNeedsPaint();
          currentAnimationPage.onTouchEvent(
              TouchEvent(TouchEvent.ACTION_MOVE, animation.value));
        })
        ..addStatusListener((status) {
          switch (status) {
            case AnimationStatus.dismissed:
              break;
            case AnimationStatus.completed:
              currentState = STATE.STATE_IDE;
              currentAnimationPage
                  .onTouchEvent(TouchEvent(TouchEvent.ACTION_UP, Offset(0, 0)));
              currentTouchData = TouchEvent(TouchEvent.ACTION_UP, Offset(0, 0));
              animationController.stop();

              break;
            case AnimationStatus.forward:
            case AnimationStatus.reverse:
              currentState = STATE.STATE_ANIMATING;
              break;
          }
        });
    }

    if (animationController.isCompleted) {
      animationController.reset();
      print(animationController.toString());
    }
  }

  void startFlingAnimation(DragEndDetails details) {
    Simulation simulation = currentAnimationPage.getFlingAnimationSimulation(
        animationController, details);

    if (simulation == null) {
      return;
    }

    if (animationController.isCompleted) {
      animationController.reset();
    }

    animationController.animateWith(simulation);
  }

  void interruptCancelAnimation() {
    if (animationController != null && !animationController.isCompleted) {
      animationController.stop();
      currentState = STATE.STATE_IDE;
      currentAnimationPage
          .onTouchEvent(TouchEvent(TouchEvent.ACTION_UP, Offset(0, 0)));
      currentTouchData = TouchEvent(TouchEvent.ACTION_UP, Offset(0, 0));
    }
  }

  bool shouldRepaint(
      CustomPainter oldDelegate, NovelPagePainter currentDelegate) {
    if (STATE.STATE_ANIMATING == currentState) {
      return true;
    }
    if (TouchEvent.ACTION_DOWN == currentTouchData?.action) {
      return true;
    }
    NovelPagePainter oldPainter = (oldDelegate as NovelPagePainter);
    return oldPainter.currentTouchData != currentDelegate.currentTouchData;
  }

  void setAnimationController(AnimationController animationController) {
    animationController.duration = const Duration(milliseconds: 200);
    this.animationController = animationController;

    if (TYPE_ANIMATION_SLIDE_TURN == currentAnimationType) {
      animationController
        ..addListener(() {
          currentState = STATE.STATE_ANIMATING;
          canvasKey.currentContext?.findRenderObject()?.markNeedsPaint();
          if (!animationController.value.isInfinite &&
              !animationController.value.isNaN) {
            currentAnimationPage.onTouchEvent(TouchEvent(
                TouchEvent.ACTION_MOVE, Offset(0, animationController.value)));
          }
        })
        ..addStatusListener((status) {
          switch (status) {
            case AnimationStatus.dismissed:
              break;
            case AnimationStatus.completed:
              currentState = STATE.STATE_IDE;
              currentAnimationPage
                  .onTouchEvent(TouchEvent(TouchEvent.ACTION_UP, Offset(0, 0)));
              currentTouchData = TouchEvent(TouchEvent.ACTION_UP, Offset(0, 0));
              break;
            case AnimationStatus.forward:
            case AnimationStatus.reverse:
              currentState = STATE.STATE_ANIMATING;
              break;
          }
        });
    }
  }
}

enum STATE { STATE_ANIMATING, STATE_IDE }

class TouchEvent<T> {
  static const int ACTION_DOWN = 0;
  static const int ACTION_MOVE = 1;
  static const int ACTION_UP = 2;
  static const int ACTION_CANCEL = 3;

  int action;
  T touchDetail;
  Offset touchPos = Offset(Screen.width, Screen.height);

  TouchEvent(this.action, this.touchPos);

  @override
  bool operator ==(other) {
    if (!(other is TouchEvent)) {
      return false;
    }

    return (this.action == other.action) && (this.touchPos == other.touchPos);
  }

  @override
  int get hashCode => super.hashCode;
}
