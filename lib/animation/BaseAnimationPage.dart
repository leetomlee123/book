import 'package:book/common/Screen.dart';
import 'package:book/model/ReadModel.dart';
import 'package:book/view/newBook/ReaderPageManager.dart';
import 'package:flutter/material.dart';

abstract class BaseAnimationPage {
  Offset mTouch = Offset(0, 0);

  late AnimationController mAnimationController;

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

  bool isShouldAnimatingInterrupt() {
    return false;
  }

  bool isCanGoNext() {
    return readerViewModel.isCanGoNext();
  }

  bool isCanGoPre() {
    return readerViewModel.isCanGoPre();
  }

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

enum ANIMATION_TYPE { TYPE_CONFIRM, TYPE_CANCEL, TYPE_FILING }
