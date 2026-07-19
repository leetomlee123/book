import 'package:book/entity/book.dart';
import 'package:book/entity/read_page.dart';
import 'package:flutter/material.dart';

/// Tap zones + page-turn eligibility for the reader canvas.
class ReaderInputController {
  ReaderInputController({
    required this.isBusy,
    required this.tapLeftToAdvanceOf,
    required this.toggleMenu,
    required this.triggerTapTurn,
    required this.commitPageTurn,
    required this.markNeedsPaint,
    required this.notify,
    required this.bookOf,
    required this.chaptersLength,
    required this.curPageOf,
    required this.hasNextPicture,
    required this.hasPreviousPicture,
  });

  final bool Function() isBusy;
  final bool Function() tapLeftToAdvanceOf;
  final void Function() toggleMenu;
  final bool Function(int direction) triggerTapTurn;
  final void Function(int direction) commitPageTurn;
  final void Function() markNeedsPaint;
  final void Function() notify;
  final Book? Function() bookOf;
  final int Function() chaptersLength;
  final ReadPage? Function() curPageOf;
  final bool Function() hasNextPicture;
  final bool Function() hasPreviousPicture;

  /// Zone tap: middle menu, sides turn. Returns true if a turn started.
  bool tapAt(Offset localPos, Size size) {
    if (isBusy()) return false;
    final wid = size.width;
    final hSpace = size.height / 4;
    final space = wid / 3;
    final x = localPos.dx;
    final y = localPos.dy;
    if (x > space && x < 2 * space && y < hSpace * 3) {
      toggleMenu();
      return false;
    }
    if (x >= 2 * space) {
      return turnByDirection(1);
    }
    if (x <= space) {
      return turnByDirection(tapLeftToAdvanceOf() ? 1 : -1);
    }
    return false;
  }

  /// Returns true if a turn was started.
  bool turnByDirection(int direction) {
    if (isBusy()) return false;
    if (triggerTapTurn(direction)) {
      return true;
    }
    commitPageTurn(direction);
    markNeedsPaint();
    notify();
    return true;
  }

  bool canTurnNext() {
    final b = bookOf();
    if (b == null) return false;
    final cur = curPageOf();
    if (b.chapterIndex >= chaptersLength() - 1 &&
        b.pageIndex >= ((cur?.pageOffsets ?? 1) - 1)) {
      return false;
    }
    if (hasNextPicture()) return true;
    if (b.pageIndex + 1 < (cur?.pageOffsets ?? 0)) return true;
    return b.chapterIndex + 1 < chaptersLength();
  }

  bool canTurnPrevious() {
    final b = bookOf();
    if (b == null) return false;
    if (b.chapterIndex <= 0 && b.pageIndex <= 0) return false;
    if (hasPreviousPicture()) return true;
    if (b.pageIndex > 0) return true;
    return b.chapterIndex > 0;
  }
}
