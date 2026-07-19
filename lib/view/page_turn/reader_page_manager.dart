import 'package:book/animation/base_animation_page.dart';
import 'package:book/animation/simulation_turn_page_animation.dart';
import 'package:book/animation/static_page_turn.dart';
import 'package:book/animation/turn_page_animation.dart';
import 'package:book/model/read_model.dart';
import 'package:book/view/page_turn/touch_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Page-turn orchestrator.
///
/// **Single commit rule:** the only place that advances the page is
/// [_commitTurn] → [ReadModel.commitPageTurn]. Cover / Simulation / Static
/// paint only; they never call commitPageTurn themselves.
class ReaderPageManager {
  static const int TYPE_ANIMATION_NONE = 0;
  static const int TYPE_ANIMATION_SIMULATION_TURN = 1;
  static const int TYPE_ANIMATION_COVER_TURN = 2;
  static const int TYPE_ANIMATION_SLIDE_TURN = 3;

  /// Short anti double-submit window only (not a hard UI lock).
  static const Duration _cooldown = Duration(milliseconds: 220);

  late BaseAnimationPage currentAnimationPage;
  TouchEvent currentTouchData = TouchEvent(TouchEvent.ACTION_UP, Offset.zero);
  int currentAnimationType = TYPE_ANIMATION_NONE;
  PageTurnState currentState = PageTurnState.idle;

  late GlobalKey canvasKey;
  AnimationController? animationController;

  /// Notified when a turn fully settles (animation end or instant commit).
  VoidCallback? onTurnSettled;

  VoidCallback? _tickListener;
  AnimationStatusListener? _statusListener;
  Animation<Offset>? _boundAnimation;

  int _pendingDirection = 0;
  bool _committed = false;
  int _turnEpoch = 0;
  DateTime? _lastCommitAt;

  /// True only while confirm/cancel animation is running.
  bool get isAnimating => currentState == PageTurnState.animating;

  /// Busy for starting a *new* turn: animating OR brief post-commit cooldown.
  bool get isBusy => isAnimating || _inCooldown;

  bool get _inCooldown {
    final t = _lastCommitAt;
    if (t == null) return false;
    return DateTime.now().difference(t) < _cooldown;
  }

  bool get _needsController =>
      currentAnimationType == TYPE_ANIMATION_COVER_TURN ||
      currentAnimationType == TYPE_ANIMATION_SIMULATION_TURN;

  void _log(String msg) {
    if (kDebugMode) {
      debugPrint('[PageTurn] $msg state=$currentState epoch=$_turnEpoch');
    }
  }

  /// Feed pointer events while the user is still interacting (down/move only).
  /// Swipe completion must go through [finishSwipe]; taps through [triggerTapTurn].
  void setCurrentTouchEvent(TouchEvent event) {
    if (isBusy) return;
    // UP during tracking is ignored here — use finishSwipe.
    if (event.action == TouchEvent.ACTION_UP ||
        event.action == TouchEvent.ACTION_CANCEL) {
      return;
    }
    currentTouchData = event;
    currentAnimationPage.onTouchEvent(event);
    if (event.action == TouchEvent.ACTION_MOVE) {
      _markPaint();
    }
  }

  /// End of a classified swipe. Returns true if a turn/animation started.
  bool finishSwipe(Offset endPos) {
    if (isBusy) {
      _log('finishSwipe ignored (busy)');
      return false;
    }

    currentTouchData = TouchEvent(TouchEvent.ACTION_UP, endPos);
    currentAnimationPage.onTouchEvent(currentTouchData);

    if (currentAnimationType == TYPE_ANIMATION_NONE) {
      // Static: commit immediately from drag delta (page no longer self-commits).
      final page = currentAnimationPage;
      if (page is StaticPageTurn) {
        final dir = page.consumeSwipeDirection();
        if (dir != 0) {
          _log('finishSwipe static dir=$dir');
          _commitTurn(dir);
          return true;
        }
      }
      _markPaint();
      return false;
    }

    if (currentAnimationPage.isConfirmArea()) {
      final dir = _inferDirectionFromPage() ? 1 : -1;
      _log('finishSwipe confirm dir=$dir');
      return startConfirmAnimation(dir);
    }
    if (currentAnimationPage.isCancelArea()) {
      _log('finishSwipe cancel');
      return startCancelAnimation();
    }
    _markPaint();
    return false;
  }

  bool _inferDirectionFromPage() {
    final page = currentAnimationPage;
    if (page is CoverPageAnimation) return page.isTurnNext;
    if (page is SimulationTurnPageAnimation) return page.isTurnToNext;
    return true;
  }

  void cancelPendingTouch() {
    if (currentState == PageTurnState.animating) return;
    currentTouchData = TouchEvent(TouchEvent.ACTION_CANCEL, Offset.zero);
    currentAnimationPage.onTouchEvent(currentTouchData);
    _markPaint();
  }

  bool triggerTapTurn(int direction) {
    if (isBusy) {
      _log('triggerTapTurn ignored (busy animating=$isAnimating cd=$_inCooldown)');
      return false;
    }

    final goNext = direction > 0;
    if (goNext && !currentAnimationPage.isCanGoNext()) {
      _log('triggerTapTurn blocked: cannot go next');
      return false;
    }
    if (!goNext && !currentAnimationPage.isCanGoPre()) {
      _log('triggerTapTurn blocked: cannot go pre');
      return false;
    }

    if (currentAnimationType == TYPE_ANIMATION_NONE ||
        animationController == null) {
      _log('triggerTapTurn static dir=${goNext ? 1 : -1}');
      _commitTurn(goNext ? 1 : -1);
      return true;
    }

    final w = currentAnimationPage.currentSize.width;
    final h = currentAnimationPage.currentSize.height;
    // Ensure page has a usable size (CustomPaint may not have painted yet).
    if (w <= 0 || h <= 0) {
      final box = canvasKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        currentAnimationPage.setSize(box.size);
      }
    }
    final w2 = currentAnimationPage.currentSize.width;
    final h2 = currentAnimationPage.currentSize.height;
    if (w2 <= 0 || h2 <= 0) {
      _log('triggerTapTurn fallback static (no size)');
      _commitTurn(goNext ? 1 : -1);
      return true;
    }

    final Offset start;
    final Offset end;
    if (currentAnimationType == TYPE_ANIMATION_SIMULATION_TURN) {
      // Seed a bottom-corner curl (most stable). Pull well past confirm threshold.
      start = goNext
          ? Offset(w2 * 0.92, h2 * 0.92)
          : Offset(w2 * 0.08, h2 * 0.92);
      end = goNext
          ? Offset(w2 * 0.25, h2 * 0.75)
          : Offset(w2 * 0.75, h2 * 0.75);
    } else {
      start = goNext ? Offset(w2 * 0.85, h2 * 0.5) : Offset(w2 * 0.15, h2 * 0.5);
      end = goNext ? Offset(w2 * 0.35, h2 * 0.5) : Offset(w2 * 0.65, h2 * 0.5);
    }

    currentAnimationPage.onTouchEvent(TouchEvent(TouchEvent.ACTION_DOWN, start));
    currentAnimationPage.onTouchEvent(TouchEvent(TouchEvent.ACTION_MOVE, end));
    currentTouchData = TouchEvent(TouchEvent.ACTION_MOVE, end);

    _log('triggerTapTurn anim dir=${goNext ? 1 : -1} size=${w2}x$h2');
    final ok = startConfirmAnimation(goNext ? 1 : -1);
    if (!ok) {
      // Animation failed to start — still advance page so taps never "die".
      _log('triggerTapTurn anim failed → instant commit');
      _commitTurn(goNext ? 1 : -1);
      return true;
    }
    return true;
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
    _abortAnimation();
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
    final c = animationController;
    if (c != null && _needsController) {
      currentAnimationPage.setAnimationController(c);
    }
    currentState = PageTurnState.idle;
  }

  int getCurrentAnimation() => currentAnimationType;

  void setCurrentCanvasContainerContext(GlobalKey canvasKey) {
    this.canvasKey = canvasKey;
  }

  bool startConfirmAnimation(int direction) {
    final c = animationController;
    if (c == null || isBusy || direction == 0) {
      _log(
        'startConfirm ignored cNull=${c == null} busy=$isBusy dir=$direction',
      );
      return false;
    }

    _detachListeners();
    if (c.isAnimating) c.stop();
    c.value = 0;

    final animation = currentAnimationPage.getConfirmAnimation(c, canvasKey);
    if (animation == null) {
      _log('startConfirm getConfirmAnimation=null');
      currentState = PageTurnState.idle;
      return false;
    }

    _pendingDirection = direction > 0 ? 1 : -1;
    _committed = false;
    currentState = PageTurnState.animating;
    final epoch = ++_turnEpoch;
    _bindAnimation(animation, commitOnComplete: true, epoch: epoch);
    c.forward();
    _log('startConfirm dir=$_pendingDirection epoch=$epoch');
    return true;
  }

  bool startCancelAnimation() {
    final c = animationController;
    if (c == null || isBusy) return false;

    _detachListeners();
    if (c.isAnimating) c.stop();
    c.value = 0;

    final animation = currentAnimationPage.getCancelAnimation(c, canvasKey);
    if (animation == null) {
      currentState = PageTurnState.idle;
      return false;
    }

    _pendingDirection = 0;
    _committed = false;
    currentState = PageTurnState.animating;
    final epoch = ++_turnEpoch;
    _bindAnimation(animation, commitOnComplete: false, epoch: epoch);
    c.forward();
    return true;
  }

  void _abortAnimation() {
    _detachListeners();
    final c = animationController;
    if (c != null && c.isAnimating) c.stop();
    _pendingDirection = 0;
    _committed = false;
    currentState = PageTurnState.idle;
    _turnEpoch++;
  }

  void _detachListeners() {
    final anim = _boundAnimation;
    if (anim != null) {
      if (_tickListener != null) anim.removeListener(_tickListener!);
      if (_statusListener != null) anim.removeStatusListener(_statusListener!);
    }
    _tickListener = null;
    _statusListener = null;
    _boundAnimation = null;
  }

  void _bindAnimation(
    Animation<Offset> animation, {
    required bool commitOnComplete,
    required int epoch,
  }) {
    _detachListeners();
    _boundAnimation = animation;

    _tickListener = () {
      if (epoch != _turnEpoch) return;
      if (currentState != PageTurnState.animating) return;
      _markPaint();
      currentAnimationPage.onTouchEvent(
        TouchEvent(TouchEvent.ACTION_MOVE, animation.value),
      );
    };

    // Only [completed] ends a turn. Never treat [dismissed] as settle.
    _statusListener = (status) {
      if (epoch != _turnEpoch) return;
      if (status != AnimationStatus.completed) return;
      if (currentState != PageTurnState.animating) return;

      if (commitOnComplete && !_committed && _pendingDirection != 0) {
        _committed = true;
        final dir = _pendingDirection;
        _pendingDirection = 0;
        _log('anim completed → commit dir=$dir');
        _commitTurn(dir);
      } else {
        _pendingDirection = 0;
        _log('anim completed → no commit');
      }

      currentState = PageTurnState.idle;
      currentAnimationPage.onTouchEvent(
        TouchEvent(TouchEvent.ACTION_CANCEL, Offset.zero),
      );
      _markPaint();
      onTurnSettled?.call();
    };

    animation.addListener(_tickListener!);
    animation.addStatusListener(_statusListener!);
  }

  /// THE only page-advance entry (besides ReadModel internal callers).
  void _commitTurn(int direction) {
    if (direction == 0) return;
    // Start cooldown BEFORE mutating page so any re-entrant busy check sees it.
    _lastCommitAt = DateTime.now();
    _log('COMMIT dir=$direction');
    currentAnimationPage.readerViewModel.commitPageTurn(direction);
    _markPaint();
    // Instant (static) turns settle immediately.
    if (currentState != PageTurnState.animating) {
      onTurnSettled?.call();
    }
  }

  void _markPaint() {
    canvasKey.currentContext?.findRenderObject()?.markNeedsPaint();
  }

  void interruptCancelAnimation() {
    _abortAnimation();
    _markPaint();
    onTurnSettled?.call();
  }

  bool shouldRepaintTouch(TouchEvent? oldTouch, TouchEvent newTouch) {
    if (isBusy) return true;
    if (TouchEvent.ACTION_DOWN == newTouch.action) return true;
    return oldTouch != newTouch;
  }

  void setAnimationController(AnimationController controller) {
    controller.duration ??= const Duration(milliseconds: 280);
    animationController = controller;
    if (_needsController) {
      currentAnimationPage.setAnimationController(controller);
    }
  }
}
