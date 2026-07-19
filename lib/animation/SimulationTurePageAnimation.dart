import 'dart:math' as math;

import 'package:book/animation/BaseAnimationPage.dart';
import 'package:book/common/ReadSetting.dart';
import 'package:book/view/newBook/touch_event.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v;

/// 仿真翻页动画 ///
class SimulationTurnPageAnimation extends BaseAnimationPage {
  bool isStartAnimation = false;
  Offset minDragDistance = Offset(10, 10);

  Path mTopPagePath = Path();
  Path mBottomPagePath = Path();
  Path mTopBackAreaPagePath = Path();
  Path mShadowPath = Path();

  double mCornerX = 1; // 拖拽点对应的页脚
  double mCornerY = 1;

  bool mIsRTandLB = false; // 是否属于右上左下

  /// 中间水平翻：触摸落在上下各 1/3 之间时，强制水平卷曲（从侧边中部翻起）。
  bool _horizontalMode = false;

  Offset mBezierStart1 = Offset(0, 0); // 贝塞尔曲线起始点
  Offset mBezierControl1 = Offset(0, 0); // 贝塞尔曲线控制点
  Offset mBezierVertex1 = Offset(0, 0); // 贝塞尔曲线顶点
  Offset mBezierEnd1 = Offset(0, 0); // 贝塞尔曲线结束点

  Offset mBezierStart2 = Offset(0, 0); // 另一条贝塞尔曲线
  Offset mBezierControl2 = Offset(0, 0);
  Offset mBezierVertex2 = Offset(0, 0);
  Offset mBezierEnd2 = Offset(0, 0);

  double mMiddleX = 0;
  double mMiddleY = 0;
  double mDegrees = 0;
  double mTouchToCornerDis = 0;

  double mMaxLength = 0;

  TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);

  bool isTurnToNext = false;
  bool isConfirmAnimation = false;

  Tween<Offset>? currentAnimationTween;
  Animation<Offset>? currentAnimation;

  void calBezierPoint() {
    // Avoid division by zero when touch sits on the corner X.
    if ((mTouch.dx - mCornerX).abs() < 0.5) {
      mTouch = Offset(
        mCornerX + (mCornerX == 0 ? 0.5 : -0.5),
        mTouch.dy,
      );
    }
    if ((mTouch.dy - mCornerY).abs() < 0.5) {
      mTouch = Offset(
        mTouch.dx,
        mCornerY + (mCornerY == 0 ? 0.5 : -0.5),
      );
    }

    mMiddleX = (mTouch.dx + mCornerX) / 2;
    mMiddleY = (mTouch.dy + mCornerY) / 2;

    mMaxLength = math
        .sqrt(math.pow(currentSize.width, 2) + math.pow(currentSize.height, 2));

    final dxCornerMid = mCornerX - mMiddleX;
    final dyCornerMid = mCornerY - mMiddleY;
    // Safe denominators
    final denX = dxCornerMid.abs() < 1e-4
        ? (dxCornerMid >= 0 ? 1e-4 : -1e-4)
        : dxCornerMid;
    final denY = dyCornerMid.abs() < 1e-4
        ? (dyCornerMid >= 0 ? 1e-4 : -1e-4)
        : dyCornerMid;

    mBezierControl1 = Offset(
        mMiddleX - dyCornerMid * dyCornerMid / denX,
        mCornerY.toDouble());

    mBezierControl2 = Offset(
        mCornerX.toDouble(),
        mMiddleY - dxCornerMid * dxCornerMid / denY);

    mBezierStart1 = Offset(
        mBezierControl1.dx - (mCornerX - mBezierControl1.dx) / 2,
        mCornerY.toDouble());

    // 当mBezierStart1.x < 0或者mBezierStart1.x > width时
    // 如果继续翻页，会出现BUG故在此限制
    if (mTouch.dx > 0 && mTouch.dx < currentSize.width) {
      if (mBezierStart1.dx < 0 || mBezierStart1.dx > currentSize.width) {
        if (mBezierStart1.dx < 0) {
          mBezierStart1 =
              Offset(currentSize.width - mBezierStart1.dx, mBezierStart1.dy);
        }

        double f1 = (mCornerX - mTouch.dx).abs();
        if (f1 < 1e-4) f1 = 1e-4;
        double f2 = currentSize.width * f1 / mBezierStart1.dx;
        mTouch = Offset((mCornerX - f2).abs(), mTouch.dy);

        double f3 =
            (mCornerX - mTouch.dx).abs() * (mCornerY - mTouch.dy).abs() / f1;
        mTouch = Offset((mCornerX - f2).abs(), (mCornerY - f3).abs());

        mMiddleX = (mTouch.dx + mCornerX) / 2;
        mMiddleY = (mTouch.dy + mCornerY) / 2;

        final dx2 = mCornerX - mMiddleX;
        final dy2 = mCornerY - mMiddleY;
        final denX2 = dx2.abs() < 1e-4 ? (dx2 >= 0 ? 1e-4 : -1e-4) : dx2;
        final denY2 = dy2.abs() < 1e-4 ? (dy2 >= 0 ? 1e-4 : -1e-4) : dy2;

        mBezierControl1 = Offset(
            mMiddleX - dy2 * dy2 / denX2,
            mCornerY);

        mBezierControl2 = Offset(
            mCornerX,
            mMiddleY - dx2 * dx2 / denY2);

        mBezierStart1 = Offset(
            mBezierControl1.dx - (mCornerX - mBezierControl1.dx) / 2,
            mBezierStart1.dy);
      }
    }

    mBezierStart2 = Offset(mCornerX.toDouble(),
        mBezierControl2.dy - (mCornerY - mBezierControl2.dy) / 2);

    mTouchToCornerDis = math.sqrt(math.pow((mTouch.dx - mCornerX), 2) +
        math.pow((mTouch.dy - mCornerY), 2));

    mBezierEnd1 =
        getCross(mTouch, mBezierControl1, mBezierStart1, mBezierStart2);
    mBezierEnd2 =
        getCross(mTouch, mBezierControl2, mBezierStart1, mBezierStart2);

    mBezierVertex1 = Offset(
        (mBezierStart1.dx + 2 * mBezierControl1.dx + mBezierEnd1.dx) / 4,
        (2 * mBezierControl1.dy + mBezierStart1.dy + mBezierEnd1.dy) / 4);

    mBezierVertex2 = Offset(
        (mBezierStart2.dx + 2 * mBezierControl2.dx + mBezierEnd2.dx) / 4,
        (2 * mBezierControl2.dy + mBezierStart2.dy + mBezierEnd2.dy) / 4);
  }

  /// 获取交点（含平行/零分母保护）
  Offset getCross(Offset p1, Offset p2, Offset p3, Offset p4) {
    final d1x = p2.dx - p1.dx;
    final d1y = p2.dy - p1.dy;
    final d2x = p4.dx - p3.dx;
    final d2y = p4.dy - p3.dy;
    // Nearly vertical first line
    if (d1x.abs() < 1e-6 && d2x.abs() < 1e-6) {
      return Offset(p1.dx, (p1.dy + p3.dy) / 2);
    }
    if (d1x.abs() < 1e-6) {
      final k2 = d2y / d2x;
      final b2 = p3.dy - k2 * p3.dx;
      return Offset(p1.dx, k2 * p1.dx + b2);
    }
    if (d2x.abs() < 1e-6) {
      final k1 = d1y / d1x;
      final b1 = p1.dy - k1 * p1.dx;
      return Offset(p3.dx, k1 * p3.dx + b1);
    }
    final k1 = d1y / d1x;
    final b1 = p1.dy - k1 * p1.dx;
    final k2 = d2y / d2x;
    final b2 = p3.dy - k2 * p3.dx;
    if ((k1 - k2).abs() < 1e-6) {
      // Parallel — return midpoint of segment ends
      return Offset((p1.dx + p3.dx) / 2, (p1.dy + p3.dy) / 2);
    }
    final x = (b2 - b1) / (k1 - k2);
    return Offset(x, k1 * x + b1);
  }

  /// 计算拖拽点对应的页脚角。
  ///
  /// - 上 1/3：上角卷曲
  /// - 下 1/3：下角卷曲
  /// - 中间 1/3：水平卷曲（侧边中部翻起，[mTouch.y] 锁到底边算法角）
  void calcCornerXY(double x, double y) {
    final w = currentSize.width;
    final h = currentSize.height;

    mCornerX = x <= w / 2 ? 0.0 : w;

    final topBand = h / 3;
    final bottomBand = h * 2 / 3;
    if (y < topBand) {
      mCornerY = 0;
      _horizontalMode = false;
    } else if (y > bottomBand) {
      mCornerY = h;
      _horizontalMode = false;
    } else {
      // Middle band → horizontal curl from side edge.
      // Algorithm anchors on a real corner; lock touch Y to that corner Y.
      mCornerY = h;
      _horizontalMode = true;
    }

    mIsRTandLB = (mCornerX == 0 && mCornerY == h) ||
        (mCornerX == w && mCornerY == 0);
  }

  Offset _applyHorizontalLock(Offset pos) {
    if (!_horizontalMode) return pos;
    // Pure horizontal fold: keep Y on the fold edge (bottom corner line).
    return Offset(pos.dx.clamp(0.0, currentSize.width), mCornerY);
  }

  Offset _normalizeTouch(Offset pos) {
    var p = _applyHorizontalLock(pos);
    // Keep a tiny offset from the fold edge so bezier math stays stable.
    if (_horizontalMode) {
      p = Offset(p.dx, mCornerY == 0 ? 0.5 : mCornerY - 0.5);
    } else if ((p.dy - mCornerY).abs() < 0.5) {
      p = Offset(p.dx, mCornerY == 0 ? 0.5 : mCornerY - 0.5);
    }
    if ((p.dx - mCornerX).abs() < 0.5) {
      p = Offset(mCornerX == 0 ? 0.5 : mCornerX - 0.5, p.dy);
    }
    return p;
  }

  void _updateDirectionAndActive() {
    // Corner on the right + finger left of corner ⇒ turn next; opposite ⇒ prev.
    isTurnToNext = mTouch.dx < mCornerX;
    final can = (!isTurnToNext && isCanGoPre()) || (isTurnToNext && isCanGoNext());
    if (can) {
      isStartAnimation = true;
    }
  }

  @override
  void onTouchEvent(TouchEvent event) {
    if (event.action == TouchEvent.ACTION_CANCEL) {
      isStartAnimation = false;
      isConfirmAnimation = false;
      mTouch = Offset.zero;
      return;
    }

    switch (event.action) {
      case TouchEvent.ACTION_DOWN:
        calcCornerXY(event.touchPos.dx, event.touchPos.dy);
        mTouch = _normalizeTouch(event.touchPos);
        isStartAnimation = false;
        isConfirmAnimation = false;
        break;
      case TouchEvent.ACTION_MOVE:
        // During confirm/cancel the manager drives mTouch via MOVE — keep flags.
        mTouch = isConfirmAnimation
            ? event.touchPos
            : _normalizeTouch(event.touchPos);
        _updateDirectionAndActive();
        break;
      case TouchEvent.ACTION_UP:
        mTouch = _normalizeTouch(event.touchPos);
        _updateDirectionAndActive();
        break;
      default:
        mTouch = event.touchPos;
        break;
    }

    if (mTouch != Offset.zero) {
      calBezierPoint();
    }
  }

  @override
  void onDraw(Canvas canvas) {
    // Draw curl while user is dragging or confirm/cancel animation is running.
    // Do NOT require mTouch.dy != 0 — top-corner curls end with y≈0.
    final animating = isConfirmAnimation || isStartAnimation;
    if (animating && mTouch != Offset.zero) {
      // Order: bottom (revealed) → top (remaining) → back of flipped flap.
      drawBottomPageCanvas(canvas);
      drawTopPageCanvas(canvas);
      drawTopPageBackArea(canvas);
    } else {
      final targetPicture = readerViewModel.cur();
      if (targetPicture != null) {
        canvas.drawPicture(targetPicture);
      }
    }
  }

  /// 画在最顶上的那页（剩余未翻起区域，需 clip）
  void drawTopPageCanvas(Canvas canvas) {
    mTopPagePath.reset();

    mTopPagePath.moveTo(mCornerX == 0 ? currentSize.width : 0, mCornerY);
    mTopPagePath.lineTo(mBezierStart1.dx, mBezierStart1.dy);
    mTopPagePath.quadraticBezierTo(
        mBezierControl1.dx, mBezierControl1.dy, mBezierEnd1.dx, mBezierEnd1.dy);
    mTopPagePath.lineTo(mTouch.dx, mTouch.dy);
    mTopPagePath.lineTo(mBezierEnd2.dx, mBezierEnd2.dy);
    mTopPagePath.quadraticBezierTo(mBezierControl2.dx, mBezierControl2.dy,
        mBezierStart2.dx, mBezierStart2.dy);
    mTopPagePath.lineTo(mCornerX, mCornerY == 0 ? currentSize.height : 0);
    mTopPagePath.lineTo(mCornerX == 0 ? currentSize.width : 0,
        mCornerY == 0 ? currentSize.height : 0);
    mTopPagePath.close();

    /// 去掉PATH圈在屏幕外的区域，减少GPU使用
    mTopPagePath = Path.combine(
        PathOperation.intersect,
        Path()
          ..moveTo(0, 0)
          ..lineTo(currentSize.width, 0)
          ..lineTo(currentSize.width, currentSize.height)
          ..lineTo(0, currentSize.height)
          ..close(),
        mTopPagePath);

    canvas.save();
    // Clip so the revealed bottom page stays visible.
    canvas.clipPath(mTopPagePath, doAntiAlias: false);
    final curPic = readerViewModel.cur();
    if (curPic != null) canvas.drawPicture(curPic);
    drawTopPageShadow(canvas);
    canvas.restore();
  }

  /// 画顶部页的阴影 ///
  void drawTopPageShadow(Canvas canvas) {
    Path shadowPath = Path();

    int dx = mCornerX == 0 ? 5 : -5;
    int dy = mCornerY == 0 ? 5 : -5;

    shadowPath = Path.combine(
        PathOperation.intersect,
        Path()
          ..moveTo(0, 0)
          ..lineTo(currentSize.width, 0)
          ..lineTo(currentSize.width, currentSize.height)
          ..lineTo(0, currentSize.height)
          ..close(),
        Path()
          ..moveTo(mTouch.dx + dx, mTouch.dy + dy)
          ..lineTo(mBezierControl2.dx + dx, mBezierControl2.dy + dy)
          ..lineTo(mBezierControl1.dx + dx, mBezierControl1.dy + dy)
          ..close());

    canvas.drawShadow(shadowPath, Colors.black, 5, true);
  }

  /// 画翻起来的底下那页 ///
  void drawBottomPageCanvas(Canvas canvas) {
    mBottomPagePath.reset();
    mBottomPagePath.moveTo(mCornerX, mCornerY);
    mBottomPagePath.lineTo(mBezierStart1.dx, mBezierStart1.dy);
    mBottomPagePath.quadraticBezierTo(
        mBezierControl1.dx, mBezierControl1.dy, mBezierEnd1.dx, mBezierEnd1.dy);
    mBottomPagePath.lineTo(mBezierEnd2.dx, mBezierEnd2.dy);
    mBottomPagePath.quadraticBezierTo(mBezierControl2.dx, mBezierControl2.dy,
        mBezierStart2.dx, mBezierStart2.dy);
    mBottomPagePath.close();

    Path extraRegion = Path();

    extraRegion.reset();
    extraRegion.moveTo(mTouch.dx, mTouch.dy);
    extraRegion.lineTo(mBezierVertex1.dx, mBezierVertex1.dy);
    extraRegion.lineTo(mBezierVertex2.dx, mBezierVertex2.dy);
    extraRegion.close();

    mBottomPagePath =
        Path.combine(PathOperation.difference, mBottomPagePath, extraRegion);

//    /// 使用fillType来反选填充区域 ///
//    mBottomPagePath = mTopPagePath
//      ..addRect(Offset.zero & currentSize)
//      ..addPath(mTopBackAreaPagePath, Offset(0, 0))
//      ..fillType = PathFillType.evenOdd;

    /// 去掉PATH圈在屏幕外的区域，减少GPU使用
    mBottomPagePath = Path.combine(
        PathOperation.intersect,
        Path()
          ..moveTo(0, 0)
          ..lineTo(currentSize.width, 0)
          ..lineTo(currentSize.width, currentSize.height)
          ..lineTo(0, currentSize.height)
          ..close(),
        mBottomPagePath);

    canvas.save();
    canvas.clipPath(mBottomPagePath, doAntiAlias: false);
//    canvas.drawPaint(Paint()..color = Color(0xfffff2cc));
//    canvas.drawImageRect(
//        isTurnToNext?readerViewModel.getNextPage().pageImage:readerViewModel.getPrePage().pageImage,
//        Offset.zero & currentSize,
//        Offset.zero & currentSize,
//        Paint()
//          ..isAntiAlias = true
//          ..blendMode = BlendMode.srcATop);
    final pagePic =
        isTurnToNext ? readerViewModel.next() : readerViewModel.pre();
    if (pagePic != null) canvas.drawPicture(pagePic);
//
    drawBottomPageShadow(canvas);

    canvas.restore();
  }

  /// 画底下那页的阴影 ///
  void drawBottomPageShadow(Canvas canvas) {
    double left;
    double right;

    Gradient shadowGradient;
    if (mIsRTandLB) {
      //左下及右上
      left = 0;
      right = mTouchToCornerDis / 4;

      shadowGradient = LinearGradient(
        colors: [
          Color(0xAA000000),
          Colors.transparent,
        ],
      );
    } else {
      left = -mTouchToCornerDis / 4;
      right = 0;

      shadowGradient = LinearGradient(
        colors: [
          Colors.transparent,
          Color(0xAA000000),
        ],
      );
    }

    canvas.translate(mBezierStart1.dx, mBezierStart1.dy);
    canvas.rotate(math.atan2(
        mBezierControl1.dx - mCornerX, mBezierControl2.dy - mCornerY));

    var shadowPaint = Paint()
      ..isAntiAlias = false
      ..style = PaintingStyle.fill //填充
      ..shader = shadowGradient
          .createShader(Rect.fromLTRB(left, 0, right, mMaxLength));

    canvas.drawRect(Rect.fromLTRB(left, 0, right, mMaxLength), shadowPaint);
  }

  /// 翻起页背面：镜像绘制当前页正文（半透明）+ 纸色蒙层，呈现透光纸效果。
  void drawTopPageBackArea(Canvas canvas) {
    mBottomPagePath.reset();
    mBottomPagePath.moveTo(mCornerX, mCornerY);
    mBottomPagePath.lineTo(mBezierStart1.dx, mBezierStart1.dy);
    mBottomPagePath.quadraticBezierTo(
        mBezierControl1.dx, mBezierControl1.dy, mBezierEnd1.dx, mBezierEnd1.dy);
    mBottomPagePath.lineTo(mTouch.dx, mTouch.dy);
    mBottomPagePath.lineTo(mBezierEnd2.dx, mBezierEnd2.dy);
    mBottomPagePath.quadraticBezierTo(mBezierControl2.dx, mBezierControl2.dy,
        mBezierStart2.dx, mBezierStart2.dy);
    mBottomPagePath.close();

    final tempBackAreaPath = Path()
      ..moveTo(mBezierVertex1.dx, mBezierVertex1.dy)
      ..lineTo(mBezierVertex2.dx, mBezierVertex2.dy)
      ..lineTo(mTouch.dx, mTouch.dy)
      ..close();

    mTopBackAreaPagePath = Path.combine(
        PathOperation.intersect, tempBackAreaPath, mBottomPagePath);

    // Clip to screen bounds.
    mTopBackAreaPagePath = Path.combine(
        PathOperation.intersect,
        Path()
          ..moveTo(0, 0)
          ..lineTo(currentSize.width, 0)
          ..lineTo(currentSize.width, currentSize.height)
          ..lineTo(0, currentSize.height)
          ..close(),
        mTopBackAreaPagePath);

    // Paper color from reader theme (bgPaint defaults to black and looks solid).
    final paper = ReadSetting.paperColor(readerViewModel.paperTheme);

    canvas.save();
    canvas.clipPath(mTopBackAreaPagePath);

    // 1) Soft paper base so the back is never pure black.
    canvas.drawPaint(Paint()..color = paper.withValues(alpha: 0.92));

    // 2) Mirrored current page content (see-through text).
    canvas.save();
    canvas.translate(mBezierControl1.dx, mBezierControl1.dy);

    final dis = math.sqrt(math.pow((mCornerX - mBezierControl1.dx), 2) +
        math.pow((mBezierControl2.dy - mCornerY), 2));
    if (dis > 0.001) {
      final sinAngle = (mCornerX - mBezierControl1.dx) / dis;
      final cosAngle = (mBezierControl2.dy - mCornerY) / dis;

      // Householder reflection matrix (page fold).
      final matrix4 = Matrix4.columns(
        v.Vector4(
            -(1 - 2 * sinAngle * sinAngle), 2 * sinAngle * cosAngle, 0, 0),
        v.Vector4(
            2 * sinAngle * cosAngle, (1 - 2 * sinAngle * sinAngle), 0, 0),
        v.Vector4(0, 0, 1, 0),
        v.Vector4(0, 0, 0, 1),
      );
      matrix4.translateByDouble(
          -mBezierControl1.dx, -mBezierControl1.dy, 0, 1);
      canvas.transform(matrix4.storage);

      final curPic = readerViewModel.cur();
      if (curPic != null) {
        // Slightly faded so it reads as ink showing through thin paper.
        canvas.saveLayer(
          Offset.zero & currentSize,
          Paint()..color = const Color(0xB3FFFFFF), // ~70% opacity
        );
        canvas.drawPicture(curPic);
        // Warm translucent paper wash over the mirrored ink.
        canvas.drawPaint(Paint()..color = paper.withValues(alpha: 0.35));
        canvas.restore();
      } else {
        canvas.drawPaint(Paint()..color = paper.withValues(alpha: 0.85));
      }
    }

    canvas.restore();

    // 3) Edge shadow on the folded flap.
    drawTopPageBackAreaShadow(canvas);
    canvas.restore();
  }

  /// 画翻起页的阴影 ///
  void drawTopPageBackAreaShadow(Canvas canvas) {
    double i = (mBezierStart1.dx + mBezierControl1.dx) / 2;
    double f1 = (i - mBezierControl1.dx).abs();
    double i1 = (mBezierStart2.dy + mBezierControl2.dy) / 2;
    double f2 = (i1 - mBezierControl2.dy).abs();
    double f3 = math.min(f1, f2);

    double left;
    double right;
    double width;
    if (mIsRTandLB) {
      left = (mBezierStart1.dx - 1);
      right = (mBezierStart1.dx + f3 + 1);
      width = right - left;
    } else {
      left = (mBezierStart1.dx - f3 - 1);
      right = (mBezierStart1.dx + 1);
      width = left - right;
    }

    canvas.translate(mBezierStart1.dx, mBezierStart1.dy);
    canvas.rotate(math.atan2(
        mBezierControl1.dx - mCornerX, mBezierControl2.dy - mCornerY));

    Gradient shadowGradient = LinearGradient(
      colors: [
        Colors.transparent,
        Color(0xAA000000),
      ],
    );

    var shadowPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill //填充
      ..shader =
      shadowGradient.createShader(Rect.fromLTRB(0, 0, width, mMaxLength));

    canvas.drawRect(Rect.fromLTRB(0, 0, width, mMaxLength), shadowPaint);
  }

  @override
  Animation<Offset>? getCancelAnimation(
      AnimationController controller, GlobalKey canvasKey) {
    if ((!isTurnToNext && !isCanGoPre()) || (isTurnToNext && !isCanGoNext())) {
      return null;
    }
    isConfirmAnimation = false;
    isStartAnimation = true;

    if (currentAnimation == null) {
      currentAnimationTween = Tween(begin: Offset.zero, end: Offset.zero);
      currentAnimation = currentAnimationTween!.animate(controller);
    }

    // Snap fold closed back to the corner.
    currentAnimationTween!.begin = mTouch;
    currentAnimationTween!.end = Offset(
      mCornerX == 0 ? 0.5 : mCornerX - 0.5,
      mCornerY == 0 ? 0.5 : mCornerY - 0.5,
    );
    return currentAnimation;
  }

  @override
  Animation<Offset>? getConfirmAnimation(
      AnimationController controller, GlobalKey canvasKey) {
    if ((!isTurnToNext && !isCanGoPre()) || (isTurnToNext && !isCanGoNext())) {
      return null;
    }
    // Drawing flags — page commit is owned by ReaderPageManager.
    isConfirmAnimation = true;
    isStartAnimation = true;

    if (currentAnimation == null) {
      currentAnimationTween = Tween(begin: Offset.zero, end: Offset.zero);
      currentAnimation = currentAnimationTween!.animate(controller);
    }

    // Pull the corner fully across the page.
    final endX = mCornerX == 0
        ? currentSize.width * 1.5
        : -currentSize.width * 0.5;
    final endY = mCornerY == 0 ? 0.5 : currentSize.height - 0.5;

    currentAnimationTween!.begin = mTouch;
    currentAnimationTween!.end = Offset(endX, endY);
    return currentAnimation;
  }

  @override
  Simulation? getFlingAnimationSimulation(
      AnimationController controller, DragEndDetails details) {
    return null;
  }

  /// Pull distance from the anchored corner (horizontal component).
  double get _pullFromCorner => (mTouch.dx - mCornerX).abs();

  /// Confirm when the finger has pulled far enough — NOT based on absolute X
  /// (old check was almost always true near the center and caused accidental turns).
  @override
  bool isCancelArea() {
    return _pullFromCorner < currentSize.width / 5;
  }

  @override
  bool isConfirmArea() {
    return _pullFromCorner >= currentSize.width / 5;
  }
}
