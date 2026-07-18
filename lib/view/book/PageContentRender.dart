import 'package:book/common/Screen.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/newBook/NovelPagePainter.dart';
import 'package:book/view/newBook/ReaderPageManager.dart';
import 'package:book/view/newBook/touch_event.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PageContentReader extends ConsumerStatefulWidget {
  const PageContentReader({Key? key}) : super(key: key);

  @override
  ConsumerState<PageContentReader> createState() => _PageContentReaderState();
}

class _PageContentReaderState extends ConsumerState<PageContentReader>
    with TickerProviderStateMixin {
  TouchEvent currentTouchEvent = TouchEvent(TouchEvent.ACTION_UP, Offset.zero);
  AnimationController? animationController;
  NovelPagePainter? mPainter;
  GlobalKey canvasKey = GlobalKey();
  ReaderPageManager? pageManager;
  Offset _lastPos = Offset.zero;

  @override
  void initState() {
    super.initState();
    final viewModel = ref.read(readModelProvider);
    viewModel.canvasKey = canvasKey;

    pageManager = ReaderPageManager();
    pageManager!.setCurrentAnimation(viewModel.currentAnimationMode);
    pageManager!.setCurrentCanvasContainerContext(canvasKey);
    pageManager!.setContentViewModel(viewModel);

    // Only allocate a controller for legacy animated modes.
    final mode = viewModel.currentAnimationMode;
    if (mode == ReaderPageManager.TYPE_ANIMATION_COVER_TURN ||
        mode == ReaderPageManager.TYPE_ANIMATION_SIMULATION_TURN) {
      animationController = AnimationController(vsync: this);
      pageManager!.setAnimationController(animationController!);
    } else if (mode == ReaderPageManager.TYPE_ANIMATION_SLIDE_TURN) {
      animationController = AnimationController.unbounded(vsync: this);
      pageManager!.setAnimationController(animationController!);
    }

    mPainter = NovelPagePainter(pageManager: pageManager);
    viewModel.mPainter = mPainter;
  }

  @override
  Widget build(BuildContext context) {
    // Watch so chapter/index changes rebuild paint path when needed.
    ref.watch(readModelProvider);
    return RawGestureDetector(
      gestures: <Type, GestureRecognizerFactory>{
        NovelPagePanGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<NovelPagePanGestureRecognizer>(
          () => NovelPagePanGestureRecognizer(false),
          (NovelPagePanGestureRecognizer instance) {
            instance.setMenuOpen(false);
            instance
              ..onDown = (detail) {
                _lastPos = detail.localPosition;
                currentTouchEvent =
                    TouchEvent(TouchEvent.ACTION_DOWN, detail.localPosition);
                mPainter?.setCurrentTouchEvent(currentTouchEvent);
                _repaint();
              }
              ..onUpdate = (detail) {
                final viewModel = ref.read(readModelProvider);
                if (viewModel.showMenu) return;
                _lastPos = detail.localPosition;
                currentTouchEvent =
                    TouchEvent(TouchEvent.ACTION_MOVE, detail.localPosition);
                mPainter?.setCurrentTouchEvent(currentTouchEvent);
                _repaint();
              }
              ..onEnd = (detail) {
                final viewModel = ref.read(readModelProvider);
                if (viewModel.showMenu) return;
                // Use last move position so static turn can compute dx.
                currentTouchEvent =
                    TouchEvent(TouchEvent.ACTION_UP, _lastPos);
                currentTouchEvent.touchDetail = detail;
                mPainter?.setCurrentTouchEvent(currentTouchEvent);
                _repaint();
              };
          },
        ),
      },
      child: CustomPaint(
        key: canvasKey,
        isComplex: true,
        size: Size(Screen.width, Screen.height),
        painter: mPainter,
      ),
    );
  }

  void _repaint() {
    canvasKey.currentContext?.findRenderObject()?.markNeedsPaint();
  }

  @override
  void dispose() {
    animationController?.dispose();
    super.dispose();
  }
}

class NovelPagePanGestureRecognizer extends PanGestureRecognizer {
  bool isMenuOpen;

  NovelPagePanGestureRecognizer(this.isMenuOpen);

  void setMenuOpen(bool isOpen) {
    isMenuOpen = isOpen;
  }

  @override
  String get debugDescription => 'novel page pan gesture recognizer';

  @override
  void addPointer(PointerDownEvent event) {
    if (!isMenuOpen) {
      super.addPointer(event);
    }
  }
}
