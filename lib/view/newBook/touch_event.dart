import 'package:book/common/Screen.dart';
import 'package:flutter/material.dart';

/// 阅读页触控事件（与翻页实现解耦）。
class TouchEvent<T> {
  static const int ACTION_DOWN = 0;
  static const int ACTION_MOVE = 1;
  static const int ACTION_UP = 2;
  static const int ACTION_CANCEL = 3;

  int action;
  T? touchDetail;
  Offset touchPos = Offset(Screen.width, Screen.height);

  TouchEvent(this.action, this.touchPos);

  @override
  bool operator ==(Object other) {
    if (other is! TouchEvent) return false;
    return action == other.action && touchPos == other.touchPos;
  }

  @override
  int get hashCode => Object.hash(action, touchPos);
}

enum PageTurnState { animating, idle }
