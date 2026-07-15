import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class AnimationControllerWithListenerNumber extends AnimationController {
  final ObserverList<AnimationStatusListener> statusListeners =
      ObserverList<AnimationStatusListener>();

  /// Creates an animation controller.
  AnimationControllerWithListenerNumber({
    double? value,
    Duration? duration,
    Duration? reverseDuration,
    String? debugLabel,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
    required TickerProvider vsync,
  }) : super(
          value: value,
          duration: duration,
          reverseDuration: reverseDuration,
          debugLabel: debugLabel,
          lowerBound: 0.0,
          upperBound: 1.0,
          animationBehavior: animationBehavior,
          vsync: vsync);

  /// Creates an animation controller with no upper or lower bound for its value.
  AnimationControllerWithListenerNumber.unbounded({
    double value = 0.0,
    Duration? duration,
    Duration? reverseDuration,
    String? debugLabel,
    required TickerProvider vsync,
    AnimationBehavior animationBehavior = AnimationBehavior.preserve,
  }) : super.unbounded(
          value: value,
          duration: duration,
          reverseDuration: reverseDuration,
          debugLabel: debugLabel,
          animationBehavior: animationBehavior,
          vsync: vsync);

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
