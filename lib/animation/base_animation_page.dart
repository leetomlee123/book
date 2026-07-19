import 'package:book/common/screen.dart';
import 'package:book/model/read_model.dart';
import 'package:book/view/page_turn/touch_event.dart';
import 'package:flutter/material.dart';

/// 翻页效果抽象。默认实现为 [StaticPageTurn]；
/// Cover / Simulation 等遗留动画可继续实现本接口。
abstract class BaseAnimationPage {
  Offset mTouch = Offset.zero;

  /// Optional — only required by animated (Cover/Simulation) implementations.
  AnimationController? mAnimationController;

  Size currentSize = Size(Screen.width, Screen.height);

  late ReadModel readerViewModel;

  void setSize(Size size) {
    currentSize = size;
  }

  void setContentViewModel(ReadModel viewModel) {
    readerViewModel = viewModel;
  }

  void onDraw(Canvas canvas);
  void onTouchEvent(TouchEvent event);
  void setAnimationController(AnimationController controller) {
    mAnimationController = controller;
  }

  bool isShouldAnimatingInterrupt() => false;

  bool isCanGoNext() => readerViewModel.isCanGoNext();

  bool isCanGoPre() => readerViewModel.isCanGoPre();

  bool isCancelArea();
  bool isConfirmArea();

  Animation<Offset>? getCancelAnimation(
      AnimationController controller, GlobalKey canvasKey);
  Animation<Offset>? getConfirmAnimation(
    AnimationController controller,
    GlobalKey canvasKey,
  );
  Simulation? getFlingAnimationSimulation(
      AnimationController controller, DragEndDetails details);
}

enum AnimationType { confirm, cancel, filing }
