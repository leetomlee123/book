import 'package:book/animation/BaseAnimationPage.dart';
import 'package:book/animation/SimulationTurePageAnimation.dart';
import 'package:book/animation/static_page_turn.dart';
import 'package:book/animation/turn_page_animation.dart';
import 'package:book/model/ReadModel.dart';
import 'package:book/view/newBook/touch_event.dart';
import 'package:flutter/material.dart';

/// 翻页编排：默认 [TYPE_ANIMATION_NONE] 静态切页。
/// Cover / Simulation 仍可挂接，但不再作为默认路径。
class ReaderPageManager {
  /// 无动画（默认）
  static const TYPE_ANIMATION_NONE = 0;

  /// 仿真翻页（遗留，确认回调不完整）
  static const TYPE_ANIMATION_SIMULATION_TURN = 1;

  /// 覆盖翻页（遗留）
  static const TYPE_ANIMATION_COVER_TURN = 2;

  /// 未实现
  static const TYPE_ANIMATION_SLIDE_TURN = 3;

  late BaseAnimationPage currentAnimationPage;
  TouchEvent currentTouchData = TouchEvent(TouchEvent.ACTION_UP, Offset.zero);
  int currentAnimationType = TYPE_ANIMATION_NONE;

  PageTurnState currentState = PageTurnState.idle;

  late GlobalKey canvasKey;

  /// 仅 Cover/Simulation 等需要；Static 可为空。
  AnimationController? animationController;

  bool get _needsController =>
      currentAnimationType == TYPE_ANIMATION_COVER_TURN ||
      currentAnimationType == TYPE_ANIMATION_SIMULATION_TURN ||
      currentAnimationType == TYPE_ANIMATION_SLIDE_TURN;

  void setCurrentTouchEvent(TouchEvent event) {
    if (currentState == PageTurnState.animating) {
      if (currentAnimationPage.isShouldAnimatingInterrupt()) {
        if (event.action == TouchEvent.ACTION_DOWN) {
          interruptCancelAnimation();
        }
      } else {
        return;
      }
    }

    if (currentAnimationType == TYPE_ANIMATION_NONE) {
      currentTouchData = event;
      currentAnimationPage.onTouchEvent(event);
      canvasKey.currentContext?.findRenderObject()?.markNeedsPaint();
      return;
    }

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
          if (event.touchDetail is DragEndDetails) {
            startFlingAnimation(event.touchDetail as DragEndDetails);
          }
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

  void setCurrentAnimation(int animationType) {
    currentAnimationType = animationType;
    switch (animationType) {
      case TYPE_ANIMATION_SIMULATION_TURN:
        currentAnimationPage = SimulationTurnPageAnimation();
        break;
      case TYPE_ANIMATION_COVER_TURN:
        currentAnimationPage = CoverPageAnimation();
        break;
      case TYPE_ANIMATION_SLIDE_TURN:
        currentAnimationPage = StaticPageTurn();
        currentAnimationType = TYPE_ANIMATION_NONE;
        break;
      case TYPE_ANIMATION_NONE:
      default:
        currentAnimationPage = StaticPageTurn();
        currentAnimationType = TYPE_ANIMATION_NONE;
        break;
    }
  }

  int getCurrentAnimation() => currentAnimationType;

  void setCurrentCanvasContainerContext(GlobalKey canvasKey) {
    this.canvasKey = canvasKey;
  }

  void startConfirmAnimation() {
    final c = animationController;
    if (c == null) return;
    final animation =
        currentAnimationPage.getConfirmAnimation(c, canvasKey);
    if (animation == null) return;
    setAnimation(animation);
    c.forward();
  }

  void startCancelAnimation() {
    final c = animationController;
    if (c == null) return;
    final animation =
        currentAnimationPage.getCancelAnimation(c, canvasKey);
    if (animation == null) return;
    setAnimation(animation);
    c.forward();
  }

  void setAnimation(Animation<Offset> animation) {
    final c = animationController;
    if (c == null) return;
    if (!c.isCompleted) {
      animation
        ..addListener(() {
          currentState = PageTurnState.animating;
          canvasKey.currentContext?.findRenderObject()?.markNeedsPaint();
          currentAnimationPage.onTouchEvent(
              TouchEvent(TouchEvent.ACTION_MOVE, animation.value));
        })
        ..addStatusListener((status) {
          switch (status) {
            case AnimationStatus.dismissed:
              break;
            case AnimationStatus.completed:
              currentState = PageTurnState.idle;
              currentAnimationPage
                  .onTouchEvent(TouchEvent(TouchEvent.ACTION_UP, Offset.zero));
              currentTouchData = TouchEvent(TouchEvent.ACTION_UP, Offset.zero);
              c.stop();
              break;
            case AnimationStatus.forward:
            case AnimationStatus.reverse:
              currentState = PageTurnState.animating;
              break;
          }
        });
    }
    if (c.isCompleted) {
      c.reset();
    }
  }

  void startFlingAnimation(DragEndDetails details) {
    final c = animationController;
    if (c == null) return;
    final simulation =
        currentAnimationPage.getFlingAnimationSimulation(c, details);
    if (simulation == null) return;
    if (c.isCompleted) c.reset();
    c.animateWith(simulation);
  }

  void interruptCancelAnimation() {
    final c = animationController;
    if (c == null) return;
    if (!c.isCompleted) {
      c.stop();
      currentState = PageTurnState.idle;
      currentAnimationPage
          .onTouchEvent(TouchEvent(TouchEvent.ACTION_UP, Offset.zero));
      currentTouchData = TouchEvent(TouchEvent.ACTION_UP, Offset.zero);
    }
  }

  bool shouldRepaintTouch(TouchEvent? oldTouch, TouchEvent newTouch) {
    if (PageTurnState.animating == currentState) return true;
    if (TouchEvent.ACTION_DOWN == newTouch.action) return true;
    return oldTouch != newTouch;
  }

  void setAnimationController(AnimationController controller) {
    if (!_needsController) {
      animationController = null;
      return;
    }
    controller.duration = const Duration(milliseconds: 200);
    animationController = controller;
  }
}
