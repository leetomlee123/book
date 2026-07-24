import 'package:book/animation/base_animation_page.dart';
import 'package:book/animation/simulation_turn_page_animation.dart';
import 'package:book/animation/static_page_turn.dart';
import 'package:book/animation/turn_page_animation.dart';
import 'package:book/common/page_turn_perf.dart';
import 'package:book/model/read_model.dart';
import 'package:book/view/page_turn/touch_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Page-turn orchestrator.
///
/// **Single commit rule:** the only place that advances the page is
/// [_commitTurn] → [ReadModel.commitPageTurn]. Cover / Simulation / Static
/// paint only; they never call commitPageTurn themselves.
///
/// Rapid taps while animating are queued (capped) and drained as soon as the
/// current turn settles so consecutive clicks feel responsive.
class ReaderPageManager {
  static const int TYPE_ANIMATION_NONE = 0;
  static const int TYPE_ANIMATION_SIMULATION_TURN = 1;
  static const int TYPE_ANIMATION_COVER_TURN = 2;
  static const int TYPE_ANIMATION_SLIDE_TURN = 3;

  /// Anti double-submit only — short enough that queued taps drain quickly.
  static const Duration _cooldown = Duration(milliseconds: 70);

  /// Max queued tap directions (prevents runaway multi-page jump).
  static const int _maxQueued = 2;

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

  /// Directions accepted while busy; drained after settle.
  final List<int> _queuedDirs = <int>[];
  bool _drainScheduled = false;

  /// Correlates anim start → commit for [PageTurnPerf] logs.
  int _activeTurnId = 0;
  Stopwatch? _activeTurnSw;

  /// True only while confirm/cancel animation is running.
  bool get isAnimating => currentState == PageTurnState.animating;

  /// Busy for starting a *new* turn: animating OR brief post-commit cooldown.
  bool get isBusy => isAnimating || _inCooldown;

  bool get _inCooldown {
    final t = _lastCommitAt;
    if (t == null) return false;
    return DateTime.now().difference(t) < _cooldown;
  }

  Duration get _cooldownRemaining {
    final t = _lastCommitAt;
    if (t == null) return Duration.zero;
    final left = _cooldown - DateTime.now().difference(t);
    return left.isNegative ? Duration.zero : left;
  }

  /// Drop any queued rapid-tap intents (e.g. on chapter boundary).
  void clearQueuedTurns() {
    if (_queuedDirs.isEmpty) return;
    _log('clearQueuedTurns dropped=$_queuedDirs');
    _queuedDirs.clear();
  }

  bool get _needsController =>
      currentAnimationType == TYPE_ANIMATION_COVER_TURN ||
      currentAnimationType == TYPE_ANIMATION_SIMULATION_TURN;

  void _log(String msg) {
    if (kDebugMode) {
      debugPrint(
        '[PageTurn] $msg state=$currentState epoch=$_turnEpoch '
        'q=$_queuedDirs',
      );
    }
  }

  String get _modeTag => PageTurnPerf.modeName(currentAnimationType);

  void _perf(String event, [String detail = '']) {
    final base =
        'mode=$_modeTag state=$currentState turn=$_activeTurnId q=$_queuedDirs';
    PageTurnPerf.log(event, detail.isEmpty ? base : '$base $detail');
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
      _perf('swipe.ignored', 'reason=busy');
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
          _perf('swipe.static', 'dir=$dir');
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
      _perf('swipe.confirm', 'dir=$dir');
      return startConfirmAnimation(dir);
    }
    if (currentAnimationPage.isCancelArea()) {
      _log('finishSwipe cancel');
      _perf('swipe.cancel');
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

  /// Start (or queue) a tap-driven turn. Returns true if accepted or queued.
  bool triggerTapTurn(int direction) {
    if (direction == 0) return false;
    final dir = direction > 0 ? 1 : -1;

    // While a turn is in flight / cooling down, keep the latest intents so
    // rapid clicks still advance instead of being dropped.
    if (isBusy) {
      return _enqueueTap(dir);
    }

    return _startTapTurn(dir);
  }

  bool _enqueueTap(int dir) {
    if (_queuedDirs.length >= _maxQueued) {
      // Replace tail with latest intent (keeps 跟手 without multi-page jump).
      _queuedDirs[_queuedDirs.length - 1] = dir;
      _log('triggerTapTurn queue full → replace tail dir=$dir');
      _perf('tap.queue.replace', 'dir=$dir');
      _scheduleDrain();
      return true;
    }
    // Collapse consecutive same-direction spam into one extra step max is
    // already capped by _maxQueued; still allow stacking up to the cap.
    _queuedDirs.add(dir);
    _log('triggerTapTurn queued dir=$dir');
    _perf('tap.queue', 'dir=$dir');
    _scheduleDrain();
    return true;
  }

  bool _startTapTurn(int dir) {
    final goNext = dir > 0;
    if (goNext && !currentAnimationPage.canTurnNext()) {
      _log('triggerTapTurn blocked: cannot go next');
      _perf('tap.blocked', 'dir=$dir reason=no_next');
      _queuedDirs.clear();
      return false;
    }
    if (!goNext && !currentAnimationPage.canTurnPrevious()) {
      _log('triggerTapTurn blocked: cannot go pre');
      _perf('tap.blocked', 'dir=$dir reason=no_pre');
      _queuedDirs.clear();
      return false;
    }

    if (currentAnimationType == TYPE_ANIMATION_NONE ||
        animationController == null) {
      _log('triggerTapTurn static dir=$dir');
      _perf('tap.static', 'dir=$dir');
      _commitTurn(dir);
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
      _commitTurn(dir);
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

    _log('triggerTapTurn anim dir=$dir size=${w2}x$h2');
    _perf('tap.anim', 'dir=$dir size=${w2.toStringAsFixed(0)}x${h2.toStringAsFixed(0)}');
    final ok = startConfirmAnimation(dir);
    if (!ok) {
      // Animation failed to start — still advance page so taps never "die".
      _log('triggerTapTurn anim failed → instant commit');
      _perf('tap.anim.fallback', 'dir=$dir');
      _commitTurn(dir);
      return true;
    }
    return true;
  }

  void _scheduleDrain() {
    if (_drainScheduled || _queuedDirs.isEmpty) return;
    _drainScheduled = true;
    final wait = _cooldownRemaining;
    void run() {
      _drainScheduled = false;
      _drainQueue();
    }

    if (wait > Duration.zero) {
      Future<void>.delayed(wait, run);
    } else {
      // Defer out of animation status / commit re-entrancy.
      SchedulerBinding.instance.addPostFrameCallback((_) => run());
    }
  }

  void _drainQueue() {
    if (_queuedDirs.isEmpty) return;
    if (isAnimating) {
      // Will retry after current turn settles.
      return;
    }
    if (_inCooldown) {
      _scheduleDrain();
      return;
    }
    final dir = _queuedDirs.removeAt(0);
    _log('drain queue dir=$dir remaining=$_queuedDirs');
    _perf('queue.drain', 'dir=$dir remaining=$_queuedDirs');
    _startTapTurn(dir);
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
    _queuedDirs.clear();
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
    _perf('mode.set', 'type=$animationType effective=$_modeTag');
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
      _perf(
        'anim.confirm.ignored',
        'dir=$direction cNull=${c == null} busy=$isBusy',
      );
      return false;
    }

    _detachListeners();
    if (c.isAnimating) c.stop();
    c.value = 0;

    final animation = currentAnimationPage.getConfirmAnimation(c, canvasKey);
    if (animation == null) {
      _log('startConfirm getConfirmAnimation=null');
      _perf('anim.confirm.null', 'dir=$direction');
      currentState = PageTurnState.idle;
      return false;
    }

    _pendingDirection = direction > 0 ? 1 : -1;
    _committed = false;
    currentState = PageTurnState.animating;
    final epoch = ++_turnEpoch;
    _activeTurnId = PageTurnPerf.nextTurnId();
    _activeTurnSw = Stopwatch()..start();
    final durMs = c.duration?.inMilliseconds ?? -1;
    _bindAnimation(animation, commitOnComplete: true, epoch: epoch);
    c.forward();
    _log('startConfirm dir=$_pendingDirection epoch=$epoch');
    _perf(
      'anim.confirm.start',
      'dir=$_pendingDirection epoch=$epoch durMs=$durMs',
    );
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
    _activeTurnId = PageTurnPerf.nextTurnId();
    _activeTurnSw = Stopwatch()..start();
    _bindAnimation(animation, commitOnComplete: false, epoch: epoch);
    c.forward();
    _perf('anim.cancel.start', 'epoch=$epoch');
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

      final animMs = _activeTurnSw?.elapsedMilliseconds;
      if (commitOnComplete && !_committed && _pendingDirection != 0) {
        _committed = true;
        final dir = _pendingDirection;
        _pendingDirection = 0;
        _log('anim completed → commit dir=$dir');
        _perf('anim.completed', 'dir=$dir animMs=${animMs ?? -1}');
        _commitTurn(dir);
      } else {
        _pendingDirection = 0;
        _log('anim completed → no commit');
        _perf('anim.completed.nocommit', 'animMs=${animMs ?? -1}');
      }

      currentState = PageTurnState.idle;
      currentAnimationPage.onTouchEvent(
        TouchEvent(TouchEvent.ACTION_CANCEL, Offset.zero),
      );
      _markPaint();
      onTurnSettled?.call();
      // Kick off any taps that arrived during this animation.
      _scheduleDrain();
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
    final turnId =
        _activeTurnId == 0 ? PageTurnPerf.nextTurnId() : _activeTurnId;
    if (_activeTurnId == 0) _activeTurnId = turnId;
    final sw = PageTurnPerf.enabled ? (Stopwatch()..start()) : null;
    currentAnimationPage.readerViewModel.commitPageTurn(direction);
    if (sw != null) {
      sw.stop();
      final totalMs = _activeTurnSw?.elapsedMilliseconds;
      PageTurnPerf.log(
        'commit',
        'mode=$_modeTag turn=$turnId dir=$direction '
            'commitMs=${sw.elapsedMilliseconds} '
            'commitUs=${sw.elapsedMicroseconds} '
            'totalMs=${totalMs ?? -1} q=$_queuedDirs',
      );
    }
    _markPaint();
    // Instant (static) turns settle immediately.
    if (currentState != PageTurnState.animating) {
      onTurnSettled?.call();
      _scheduleDrain();
    }
  }

  void _markPaint() {
    canvasKey.currentContext?.findRenderObject()?.markNeedsPaint();
  }

  void interruptCancelAnimation() {
    _abortAnimation();
    _queuedDirs.clear();
    _markPaint();
    onTurnSettled?.call();
  }

  bool shouldRepaintTouch(TouchEvent? oldTouch, TouchEvent newTouch) {
    if (isBusy) return true;
    if (TouchEvent.ACTION_DOWN == newTouch.action) return true;
    return oldTouch != newTouch;
  }

  void setAnimationController(AnimationController controller) {
    // Slightly snappier default so queued taps feel closer to 跟手.
    controller.duration ??= const Duration(milliseconds: 220);
    animationController = controller;
    if (_needsController) {
      currentAnimationPage.setAnimationController(controller);
    }
  }
}
