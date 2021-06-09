

import 'package:book/common/Screen.dart';
import 'package:flutter/material.dart';



class TouchEvent<T> {
  static const int ACTION_DOWN = 0;
  static const int ACTION_MOVE = 1;
  static const int ACTION_UP = 2;
  static const int ACTION_CANCEL = 3;

  int action;
  T touchDetail;
  Offset touchPos =
      Offset(Screen.width,Screen.height);

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

abstract class BaseAnimationPage{

  Offset mTouch=Offset(0,0);

  AnimationController mAnimationController;

  Size currentSize=Size(Screen.width,Screen.height);

//  @protected
//  ReaderContentViewModel contentModel=ReaderContentViewModel.instance;

  // NovelReaderViewModel readerViewModel;

//  void setData(ReaderChapterPageContentConfig prePageConfig,ReaderChapterPageContentConfig currentPageConfig,ReaderChapterPageContentConfig nextPageConfig){
//    currentPageContentConfig=pageConfig;
//  }

  void setSize(Size size){
    currentSize=size;
//    mTouch=Offset(currentSize.width, currentSize.height);
  }
//   void setContentViewModel(NovelReaderViewModel viewModel){
//     readerViewModel=viewModel;
// //    mTouch=Offset(currentSize.width, currentSize.height);
//   }

  void onDraw(Canvas canvas);
  void onTouchEvent(TouchEvent event);
  void setAnimationController(AnimationController controller){
    mAnimationController=controller;
  }

  bool isShouldAnimatingInterrupt(){
   return false;
  }

  bool isCanGoNext(){
    // return readerViewModel.isCanGoNext();
  }
  bool isCanGoPre(){
    // return readerViewModel.isCanGoPre();
  }

  bool isCancelArea();
  bool isConfirmArea();

  Animation<Offset> getCancelAnimation(AnimationController controller,GlobalKey canvasKey);
  Animation<Offset> getConfirmAnimation(AnimationController controller,GlobalKey canvasKey);
  Simulation getFlingAnimationSimulation(AnimationController controller,DragEndDetails details);

}

enum ANIMATION_TYPE { TYPE_CONFIRM, TYPE_CANCEL,TYPE_FILING }
