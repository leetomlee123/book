import 'package:book/view/newBook/ReaderPageManager.dart';
import 'package:flutter/material.dart';

class NovelPagePainter extends CustomPainter {
  ReaderPageManager? pageManager;
  late TouchEvent currentTouchData;
  int? currentPageIndex;
  int? currentChapterId;
  NovelPagePainter({this.pageManager});

  void setCurrentTouchEvent(TouchEvent event) {
    currentTouchData = event;
    pageManager?.setCurrentTouchEvent(currentTouchData);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (pageManager != null) {
      pageManager!.setPageSize(size);
      pageManager!.onPageDraw(canvas);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return pageManager?.shouldRepaint(oldDelegate, this) ?? false;
  }
}
