import 'package:book/view/page_turn/reader_page_manager.dart';
import 'package:book/view/page_turn/touch_event.dart';
import 'package:flutter/material.dart';

class NovelPagePainter extends CustomPainter {
  ReaderPageManager? pageManager;
  TouchEvent currentTouchData =
      TouchEvent(TouchEvent.ACTION_UP, Offset.zero);
  int? currentPageIndex;
  int? currentChapterId;
  NovelPagePainter({this.pageManager});

  void setCurrentTouchEvent(TouchEvent event) {
    currentTouchData = event;
    pageManager?.setCurrentTouchEvent(currentTouchData);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final mgr = pageManager;
    if (mgr != null) {
      mgr.setPageSize(size);
      mgr.onPageDraw(canvas);
    }
  }

  @override
  bool shouldRepaint(covariant NovelPagePainter oldDelegate) {
    return pageManager?.shouldRepaintTouch(
          oldDelegate.currentTouchData,
          currentTouchData,
        ) ??
        true;
  }
}
