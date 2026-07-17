import 'package:book/animation/AnimationControllerWithListenerNumber.dart';
import 'package:book/common/Screen.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/newBook/NovelPagePainter.dart';
import 'package:book/view/newBook/ReaderPageManager.dart';
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

  @override
  void initState() {
    super.initState();
    final viewModel = ref.read(readModelProvider);
    viewModel.canvasKey = canvasKey;
    switch (viewModel.currentAnimationMode) {
      case ReaderPageManager.TYPE_ANIMATION_SIMULATION_TURN:
      case ReaderPageManager.TYPE_ANIMATION_COVER_TURN:
        animationController = AnimationControllerWithListenerNumber(
          vsync: this,
        );
        break;
      case ReaderPageManager.TYPE_ANIMATION_SLIDE_TURN:
        animationController = AnimationControllerWithListenerNumber.unbounded(
          vsync: this,
        );
        break;
    }

    if (animationController != null) {
      pageManager = ReaderPageManager();
      pageManager!.setCurrentAnimation(viewModel.currentAnimationMode);
      pageManager!.setCurrentCanvasContainerContext(canvasKey);
      pageManager!.setAnimationController(animationController!);
      pageManager!.setContentViewModel(viewModel);
      mPainter = NovelPagePainter(pageManager: pageManager);
    }
    viewModel.mPainter = mPainter;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(readModelProvider);
    return RawGestureDetector(
      gestures: <Type, GestureRecognizerFactory>{
        NovelPagePanGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<NovelPagePanGestureRecognizer>(
          () => NovelPagePanGestureRecognizer(false),
          (NovelPagePanGestureRecognizer instance) {
            instance.setMenuOpen(false);

            instance
              ..onDown = (detail) {
                if (currentTouchEvent.action != TouchEvent.ACTION_DOWN ||
                    currentTouchEvent.touchPos != detail.localPosition) {
                  currentTouchEvent =
                      TouchEvent(TouchEvent.ACTION_DOWN, detail.localPosition);
                  mPainter?.setCurrentTouchEvent(currentTouchEvent);
                  canvasKey.currentContext
                      ?.findRenderObject()
                      ?.markNeedsPaint();
                }
              };
            instance
              ..onUpdate = (detail) {
                if (!viewModel.showMenu) {
                  if (currentTouchEvent.action != TouchEvent.ACTION_MOVE ||
                      currentTouchEvent.touchPos != detail.localPosition) {
                    currentTouchEvent = TouchEvent(
                        TouchEvent.ACTION_MOVE, detail.localPosition);
                    mPainter?.setCurrentTouchEvent(currentTouchEvent);
                    canvasKey.currentContext
                        ?.findRenderObject()
                        ?.markNeedsPaint();
                  }
                }
              };
            instance
              ..onEnd = (detail) {
                if (!viewModel.showMenu) {
                  if (currentTouchEvent.action != TouchEvent.ACTION_UP ||
                      currentTouchEvent.touchPos != Offset(0, 0)) {
                    currentTouchEvent = TouchEvent<DragEndDetails>(
                        TouchEvent.ACTION_UP, Offset(0, 0));
                    currentTouchEvent.touchDetail = detail;

                    mPainter?.setCurrentTouchEvent(currentTouchEvent);
                    canvasKey.currentContext
                        ?.findRenderObject()
                        ?.markNeedsPaint();
                  }
                }
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
  String get debugDescription => "novel page pan gesture recognizer";

  @override
  void addPointer(PointerDownEvent event) {
    if (!isMenuOpen) {
      super.addPointer(event);
    }
  }
}
