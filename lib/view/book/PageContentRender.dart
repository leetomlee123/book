import 'package:book/animation/AnimationControllerWithListenerNumber.dart';
import 'package:book/model/ReadModel.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/newBook/NovelPagePainter.dart';
import 'package:book/view/newBook/ReaderPageManager.dart';
import 'package:book/view/newBook/touch_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Explicit reader pointer phases — one gesture → one outcome.
enum _PointerPhase {
  idle,
  down, // pressed, not yet past slop
  dragging, // past slop — only swipe path may turn
  settling, // page-turn animation running; ignore input
}

/// Reader canvas with a single pointer state machine.
///
/// - Tap vs drag are mutually exclusive (slop).
/// - Only block input while a turn animation is in flight (not cooldown).
/// - Stale [settling] always recovers on next pointer down.
class PageContentReader extends ConsumerStatefulWidget {
  const PageContentReader({super.key});

  @override
  ConsumerState<PageContentReader> createState() => _PageContentReaderState();
}

class _PageContentReaderState extends ConsumerState<PageContentReader>
    with TickerProviderStateMixin {
  late final AnimationControllerWithListenerNumber animationController;
  NovelPagePainter? mPainter;
  final GlobalKey canvasKey = GlobalKey();
  ReaderPageManager? pageManager;
  int? _boundMode;

  _PointerPhase _phase = _PointerPhase.idle;
  int? _activePointer;
  Offset _downPos = Offset.zero;
  Offset _lastPos = Offset.zero;

  static const double _dragSlop = 18;

  @override
  void initState() {
    super.initState();
    final viewModel = ref.read(readModelProvider);
    viewModel.canvasKey = canvasKey;

    animationController = AnimationControllerWithListenerNumber(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    pageManager = ReaderPageManager()..onTurnSettled = _onTurnSettled;

    _applyMode(viewModel.currentAnimationMode, viewModel);
    mPainter = NovelPagePainter(pageManager: pageManager);
    viewModel.mPainter = mPainter;
  }

  void _applyMode(int mode, ReadModel viewModel) {
    final mgr = pageManager;
    if (mgr == null) return;
    // Scroll mode (3) is a separate surface; treat as static if we ever land here.
    final effective = mode == ReaderPageManager.TYPE_ANIMATION_SLIDE_TURN
        ? ReaderPageManager.TYPE_ANIMATION_NONE
        : mode;
    mgr.setCurrentAnimation(effective);
    mgr.setCurrentCanvasContainerContext(canvasKey);
    mgr.setContentViewModel(viewModel);
    mgr.setAnimationController(animationController);
    mgr.currentAnimationPage.setAnimationController(animationController);
    _boundMode = mode;
  }

  void _onTurnSettled() {
    if (!mounted) return;
    _phase = _PointerPhase.idle;
    _activePointer = null;
    _log('settled → idle');
  }

  void _repaint() {
    canvasKey.currentContext?.findRenderObject()?.markNeedsPaint();
  }

  bool get _menuOpen => ref.read(readModelProvider).showMenu;

  /// Only hard-lock while the turn animation is running.
  /// Cooldown is handled inside the manager (double-submit guard), not here —
  /// otherwise the UI can look "dead" after one tap.
  bool get _animating => pageManager?.isAnimating == true;

  void _recoverIfStale() {
    // If we think we're settling but the manager is idle, unlock.
    if (_phase == _PointerPhase.settling && !_animating) {
      _phase = _PointerPhase.idle;
      _activePointer = null;
      _log('recovered stale settling');
    }
  }

  void _log(String msg) {
    if (kDebugMode) {
      debugPrint(
        '[ReaderGesture] $msg phase=$_phase animating=$_animating '
        'busy=${pageManager?.isBusy}',
      );
    }
  }

  Size _canvasSize(BuildContext context) {
    final box = canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize && box.size.width > 0) {
      return box.size;
    }
    final mq = MediaQuery.sizeOf(context);
    if (mq.width > 0) return mq;
    return const Size(360, 640);
  }

  void _onPointerDown(PointerDownEvent e) {
    _recoverIfStale();

    if (_activePointer != null) {
      _log('DOWN ignored (active pointer)');
      return;
    }
    if (_menuOpen) {
      _log('DOWN ignored (menu)');
      return;
    }
    if (_animating || _phase == _PointerPhase.settling) {
      _log('DOWN ignored (animating)');
      return;
    }

    _activePointer = e.pointer;
    _downPos = e.localPosition;
    _lastPos = e.localPosition;
    _phase = _PointerPhase.down;
    _log('DOWN ${e.localPosition}');
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (e.pointer != _activePointer) return;
    if (_phase != _PointerPhase.down && _phase != _PointerPhase.dragging) {
      return;
    }
    if (_menuOpen || _animating) return;

    _lastPos = e.localPosition;
    final dist = (_lastPos - _downPos).distance;

    if (_phase == _PointerPhase.down && dist > _dragSlop) {
      _phase = _PointerPhase.dragging;
      _log('→ DRAGGING dist=${dist.toStringAsFixed(1)}');
      mPainter?.setCurrentTouchEvent(
        TouchEvent(TouchEvent.ACTION_DOWN, _downPos),
      );
    }

    if (_phase == _PointerPhase.dragging) {
      mPainter?.setCurrentTouchEvent(
        TouchEvent(TouchEvent.ACTION_MOVE, e.localPosition),
      );
      _repaint();
    }
  }

  void _onPointerUp(PointerUpEvent e) {
    if (e.pointer != _activePointer) return;
    _activePointer = null;
    _lastPos = e.localPosition;

    final phase = _phase;
    _phase = _PointerPhase.idle;

    final vm = ref.read(readModelProvider);
    if (vm.showMenu) {
      pageManager?.cancelPendingTouch();
      _log('UP ignored (menu)');
      return;
    }
    if (_animating) {
      _log('UP ignored (animating)');
      return;
    }

    switch (phase) {
      case _PointerPhase.dragging:
        _log('UP as SWIPE end=${e.localPosition}');
        final started = pageManager?.finishSwipe(e.localPosition) ?? false;
        if (started) {
          _phase = _PointerPhase.settling;
        }
        _repaint();
        break;

      case _PointerPhase.down:
        _log('UP as TAP pos=${e.localPosition}');
        pageManager?.cancelPendingTouch();
        final size = _canvasSize(context);
        final started = vm.tapPageAt(e.localPosition, size);
        if (started || pageManager?.isAnimating == true) {
          _phase = _PointerPhase.settling;
        }
        break;

      case _PointerPhase.settling:
      case _PointerPhase.idle:
        _log('UP ignored (phase=$phase)');
        break;
    }
  }

  void _onPointerCancel(PointerCancelEvent e) {
    if (e.pointer != _activePointer) return;
    _activePointer = null;
    _phase = _PointerPhase.idle;
    pageManager?.cancelPendingTouch();
    _repaint();
    _log('CANCEL');
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(readModelProvider);
    if (_boundMode != viewModel.currentAnimationMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _applyMode(viewModel.currentAnimationMode, viewModel);
        _repaint();
      });
    }

    _recoverIfStale();

    final size = _canvasSize(context);

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: CustomPaint(
        key: canvasKey,
        isComplex: true,
        size: size,
        painter: mPainter,
      ),
    );
  }

  @override
  void dispose() {
    pageManager?.onTurnSettled = null;
    animationController.dispose();
    super.dispose();
  }
}
