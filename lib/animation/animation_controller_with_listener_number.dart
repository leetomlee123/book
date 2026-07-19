import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AnimationControllerWithListenerNumber extends AnimationController {
  final ObserverList<AnimationStatusListener> statusListeners =
      ObserverList<AnimationStatusListener>();

  /// Creates an animation controller.
  AnimationControllerWithListenerNumber({
    super.value,
    super.duration,
    super.reverseDuration,
    super.debugLabel,
    super.animationBehavior,
    required super.vsync,
  }) : super(
          lowerBound: 0.0,
          upperBound: 1.0);

  /// Creates an animation controller with no upper or lower bound for its value.
  AnimationControllerWithListenerNumber.unbounded({
    super.value,
    super.duration,
    super.reverseDuration,
    super.debugLabel,
    required super.vsync,
    super.animationBehavior,
  }) : super.unbounded();

  @override
  void addStatusListener(AnimationStatusListener listener) {
    statusListeners.add(listener);
    super.addStatusListener(listener);
  }

  @override
  void removeStatusListener(AnimationStatusListener listener) {
    statusListeners.remove(listener);
    super.removeStatusListener(listener);
  }

  bool isListenerEmpty() {
    return statusListeners.isEmpty;
  }
}
