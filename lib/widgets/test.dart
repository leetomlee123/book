// MIT License
//
// Copyright (c) 2019 Simon Lightfoot
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';



class ExampleScreen extends StatefulWidget {
  @override
  _ExampleScreenState createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> with SingleTickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: 0.5,
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    if (_controller.status == AnimationStatus.dismissed || _controller.status == AnimationStatus.reverse) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            PageTurnImage(
              amount: AlwaysStoppedAnimation(1.0),
              image: NetworkImage(
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/John_Masefield.djvu/page10-1024px-John_Masefield.djvu.jpg'),
            ),
            PageTurnWidget(
              amount: _controller,
              child: AlicePage1(),
            ),

          ],
        ),
      ),
    );
  }
}

class AlicePage1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: TextStyle(fontSize: 16.0),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                "CHAPTER I",
                style: TextStyle(
                  fontSize: 32.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                "Down the Rabbit-Hole",
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text("Alice was beginning to get very tired of sitting by her sister on the bank, and of"
                        " having nothing to do: once or twice she had peeped into the book her sister was "
                        "reading, but it had no pictures or conversations in it, `and what is the use of "
                        "a book,' thought Alice `without pictures or conversation?'"),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 12.0),
                    color: Colors.black26,
                    width: 160.0,
                    height: 220.0,
                    child: Placeholder(),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Text(
                "So she was considering in her own mind (as well as she could, for the hot day made her "
                "feel very sleepy and stupid), whether the pleasure of making a daisy-chain would be "
                "worth the trouble of getting up and picking the daisies, when suddenly a White "
                "Rabbit with pink eyes ran close by her.\n"
                "\n"
                "There was nothing so very remarkable in that; nor did Alice think it so very much out "
                "of the way to hear the Rabbit say to itself, `Oh dear! Oh dear! I shall be "
                "late!' (when she thought it over afterwards, it occurred to her that she ought to "
                "have wondered at this, but at the time it all seemed quite natural); but when the "
                "Rabbit actually took a watch out of its waistcoat-pocket, and looked at it, and then "
                "hurried on, Alice started to her feet, for it flashed across her mind that she had "
                "never before seen a rabbit with either a waistcoat-pocket, or a watch to take out "
                "of it, and burning with curiosity, she ran across the field after it, and fortunately "
                "was just in time to see it pop down a large rabbit-hole under the hedge.",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------

class PageTurnWidget extends StatefulWidget {
  const PageTurnWidget({
    Key key,
    this.amount,
    this.backgroundColor = const Color(0xFFFFFFCC),
    this.child,
  }) : super(key: key);

  final Animation<double> amount;
  final Color backgroundColor;
  final Widget child;

  @override
  _PageTurnWidgetState createState() => _PageTurnWidgetState();
}

class _PageTurnWidgetState extends State<PageTurnWidget> {
  final _boundaryKey = GlobalKey();
  ui.Image _image;

  @override
  void didUpdateWidget(PageTurnWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) {
      _image = null;
    }
  }

  void _captureImage(Duration timeStamp) async {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final boundary = _boundaryKey.currentContext.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    setState(() => _image = image);
  }

  @override
  Widget build(BuildContext context) {
    if (_image != null) {
      return CustomPaint(
        painter: _PageTurnEffect(
          amount: widget.amount,
          image: _image,
          backgroundColor: widget.backgroundColor,
        ),
        size: Size.infinite,
      );
    } else {
      WidgetsBinding.instance.addPostFrameCallback(_captureImage);
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final size = constraints.biggest;
          return Stack(
            overflow: Overflow.clip,
            children: <Widget>[
              Positioned(
                left: 1 + size.width,
                top: 1 + size.height,
                width: size.width,
                height: size.height,
                child: RepaintBoundary(
                  key: _boundaryKey,
                  child: widget.child,
                ),
              ),
            ],
          );
        },
      );
    }
  }
}

class PageTurnImage extends StatefulWidget {
  const PageTurnImage({
    Key key,
    this.amount,
    this.image,
    this.backgroundColor = const Color(0xFFFFFFCC),
  }) : super(key: key);

  final Animation<double> amount;
  final ImageProvider image;
  final Color backgroundColor;

  @override
  _PageTurnImageState createState() => _PageTurnImageState();
}

class _PageTurnImageState extends State<PageTurnImage> {
  ImageStream _imageStream;
  ImageInfo _imageInfo;
  bool _isListeningToStream = false;

  ImageStreamListener _imageListener;

  @override
  void initState() {
    super.initState();
    _imageListener = ImageStreamListener(_handleImageFrame);
  }

  @override
  void dispose() {
    _stopListeningToStream();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    _resolveImage();
    if (TickerMode.of(context)) {
      _listenToStream();
    } else {
      _stopListeningToStream();
    }
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(PageTurnImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.image != oldWidget.image) {
      _resolveImage();
    }
  }

  @override
  void reassemble() {
    _resolveImage(); // in case the image cache was flushed
    super.reassemble();
  }

  void _resolveImage() {
    final ImageStream newStream = widget.image.resolve(createLocalImageConfiguration(context));
    assert(newStream != null);
    _updateSourceStream(newStream);
  }

  void _handleImageFrame(ImageInfo imageInfo, bool synchronousCall) {
    setState(() => _imageInfo = imageInfo);
  }

  // Updates _imageStream to newStream, and moves the stream listener
  // registration from the old stream to the new stream (if a listener was
  // registered).
  void _updateSourceStream(ImageStream newStream) {
    if (_imageStream?.key == newStream?.key) return;

    if (_isListeningToStream) _imageStream.removeListener(_imageListener);

    _imageStream = newStream;
    if (_isListeningToStream) _imageStream.addListener(_imageListener);
  }

  void _listenToStream() {
    if (_isListeningToStream) return;
    _imageStream.addListener(_imageListener);
    _isListeningToStream = true;
  }

  void _stopListeningToStream() {
    if (!_isListeningToStream) return;
    _imageStream.removeListener(_imageListener);
    _isListeningToStream = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_imageInfo != null) {
      return CustomPaint(
        painter: _PageTurnEffect(
          amount: widget.amount,
          image: _imageInfo.image,
          backgroundColor: widget.backgroundColor,
        ),
        size: Size.infinite,
      );
    } else {
      return const SizedBox();
    }
  }
}

class _PageTurnEffect extends CustomPainter {
  _PageTurnEffect({
    @required this.amount,
    @required this.image,
    this.backgroundColor,
    this.radius = 0.18,
  })  : assert(amount != null && image != null && radius != null),
        super(repaint: amount);

  final Animation<double> amount;
  final ui.Image image;
  final Color backgroundColor;
  final double radius;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final pos = amount.value;
    final movX = (1.0 - pos) * 0.85;
    final calcR = (movX < 0.20) ? radius * movX * 5 : radius;
    final wHRatio = 1 - calcR;
    final hWRatio = image.height / image.width;
    final hWCorrection = (hWRatio - 1.0) / 2.0;

    final w = size.width.toDouble();
    final h = size.height.toDouble();
    final c = canvas;
    final shadowXf = (wHRatio - movX);
    final shadowSigma = Shadow.convertRadiusToSigma(8.0 + (32.0 * (1.0 - shadowXf)));
    final pageRect = Rect.fromLTRB(0.0, 0.0, w * shadowXf, h);
    if (backgroundColor != null) {
      c.drawRect(pageRect, Paint()..color = backgroundColor);
    }
    c.drawRect(
      pageRect,
      Paint()
        ..color = Colors.black54
        ..maskFilter = MaskFilter.blur(BlurStyle.outer, shadowSigma),
    );

    final ip = Paint();
    for (double x = 0; x < size.width; x++) {
      final xf = (x / w);
      final v = (calcR * (math.sin(math.pi / 0.5 * (xf - (1.0 - pos)))) + (calcR * 1.1));
      final xv = (xf * wHRatio) - movX;
      final sx = (xf * image.width);
      final sr = Rect.fromLTRB(sx, 0.0, sx + 1.0, image.height.toDouble());
      final yv = ((h * calcR * movX) * hWRatio) - hWCorrection;
      final ds = (yv * v);
      final dr = Rect.fromLTRB(xv * w, 0.0 - ds, xv * w + 1.0, h + ds);
      c.drawImageRect(image, sr, dr, ip);
    }
  }

  @override
  bool shouldRepaint(_PageTurnEffect oldDelegate) {
    return oldDelegate.image != image || oldDelegate.amount.value != amount.value;
  }
}