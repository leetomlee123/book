import 'package:flutter/material.dart';

/// Defines widgets which are to used as rating bar items.
class RatingWidget {
  /// Defines widget to be used as rating bar item when the item is completely rated.
  final Widget full;

  /// Defines widget to be used as rating bar item when only the half portion of item is rated.
  final Widget half;

  /// Defines widget to be used as rating bar item when the item is unrated.
  final Widget empty;

  RatingWidget({
    @required this.full,
    @required this.half,
    @required this.empty,
  });
}

class _HalfRatingWidget extends StatelessWidget {
  final Widget child;
  final double size;
  final bool enableMask;
  final bool rtlMode;
  final Color unratedColor;

  _HalfRatingWidget({
    @required this.size,
    @required this.child,
    @required this.enableMask,
    @required this.rtlMode,
    @required this.unratedColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: enableMask
          ? Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.contain,
            child: _NoRatingWidget(
              child: child,
              size: size,
              unratedColor: unratedColor,
              enableMask: enableMask,
            ),
          ),
          FittedBox(
            fit: BoxFit.contain,
            child: ClipRect(
              clipper: _HalfClipper(
                rtlMode: rtlMode,
              ),
              child: child,
            ),
          ),
        ],
      )
          : FittedBox(
        child: child,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _HalfClipper extends CustomClipper<Rect> {
  final bool rtlMode;

  _HalfClipper({
    @required this.rtlMode,
  });

  @override
  Rect getClip(Size size) => rtlMode
      ? Rect.fromLTRB(
    size.width / 2,
    0.0,
    size.width,
    size.height,
  )
      : Rect.fromLTRB(
    0.0,
    0.0,
    size.width / 2,
    size.height,
  );

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => true;
}

class _NoRatingWidget extends StatelessWidget {
  final double size;
  final Widget child;
  final bool enableMask;
  final Color unratedColor;

  _NoRatingWidget({
    @required this.size,
    @required this.child,
    @required this.enableMask,
    @required this.unratedColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: FittedBox(
        fit: BoxFit.contain,
        child: enableMask
            ? _ColorFilter(
          color: unratedColor,
          child: child,
        )
            : child,
      ),
    );
  }
}

class _ColorFilter extends StatelessWidget {
  final Widget child;
  final Color color;

  _ColorFilter({
    @required this.child,
    @required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        color,
        BlendMode.srcATop,
      ),
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.white,
          BlendMode.srcATop,
        ),
        child: child,
      ),
    );
  }
}

class _IndicatorClipper extends CustomClipper<Rect> {
  final double ratingFraction;
  final bool rtlMode;

  _IndicatorClipper({
    this.ratingFraction,
    this.rtlMode = false,
  });

  @override
  Rect getClip(Size size) => rtlMode
      ? Rect.fromLTRB(
    size.width - size.width * ratingFraction,
    0.0,
    size.width,
    size.height,
  )
      : Rect.fromLTRB(
    0.0,
    0.0,
    size.width * ratingFraction,
    size.height,
  );

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => true;
}

/// A widget to display rating as assigned using [rating] property.
///
/// It's a read only version of [RatingBar].
/// Use [RatingBar], if interative version is required. i.e. if user input is required.
class RatingBarIndicator extends StatefulWidget {
  /// Defines the rating value for indicator.
  ///
  /// Default = 0.0
  final double rating;

  /// {@macro flutterRatingBar.itemCount}
  final int itemCount;

  /// {@macro flutterRatingBar.itemSize}
  final double itemSize;

  /// {@macro flutterRatingBar.itemPadding}
  final EdgeInsets itemPadding;

  /// Controls the scrolling behaviour of rating bar.
  ///
  /// Default is [NeverScrollableScrollPhysics].
  final ScrollPhysics physics;

  /// {@macro flutterRatingBar.textDirection}
  final TextDirection textDirection;

  /// {@macro flutterRatingBar.itemBuilder}
  final IndexedWidgetBuilder itemBuilder;

  /// {@macro flutterRatingBar.direction}
  final Axis direction;

  /// {@macro flutterRatingBar.unratedColor}
  final Color unratedColor;

  RatingBarIndicator({
    @required this.itemBuilder,
    this.rating = 0.0,
    this.itemCount = 5,
    this.itemSize = 40.0,
    this.itemPadding = const EdgeInsets.all(0.0),
    this.physics = const NeverScrollableScrollPhysics(),
    this.textDirection,
    this.direction = Axis.horizontal,
    this.unratedColor,
  });

  @override
  _RatingBarIndicatorState createState() => _RatingBarIndicatorState();
}

class _RatingBarIndicatorState extends State<RatingBarIndicator> {
  double _ratingFraction = 0.0;
  int _ratingNumber = 0;
  bool _isRTL = false;

  @override
  void initState() {
    super.initState();
    _ratingNumber = widget.rating.truncate() + 1;
    _ratingFraction = widget.rating - _ratingNumber + 1;
  }

  @override
  Widget build(BuildContext context) {
    _isRTL = (widget.textDirection ?? Directionality.of(context)) ==
        TextDirection.rtl;
    _ratingNumber = widget.rating.truncate() + 1;
    _ratingFraction = widget.rating - _ratingNumber + 1;
    return SingleChildScrollView(
      scrollDirection: widget.direction,
      physics: widget.physics,
      child: widget.direction == Axis.horizontal
          ? Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: _isRTL ? TextDirection.rtl : TextDirection.ltr,
        children: _children(),
      )
          : Column(
        mainAxisSize: MainAxisSize.min,
        textDirection: _isRTL ? TextDirection.rtl : TextDirection.ltr,
        children: _children(),
      ),
    );
  }

  List<Widget> _children() {
    return List.generate(
      widget.itemCount,
          (index) {
        if (widget.textDirection != null) {
          if (widget.textDirection == TextDirection.rtl &&
              Directionality.of(context) != TextDirection.rtl) {
            return Transform(
              transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
              alignment: Alignment.center,
              transformHitTests: false,
              child: _buildItems(index),
            );
          }
        }
        return _buildItems(index);
      },
    );
  }

  Widget _buildItems(int index) => Padding(
    padding: widget.itemPadding,
    child: SizedBox(
      width: widget.itemSize,
      height: widget.itemSize,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.contain,
            child: index + 1 < _ratingNumber
                ? widget.itemBuilder(context, index)
                : _ColorFilter(
              color: widget.unratedColor ?? Colors.grey[200],
              child: widget.itemBuilder(context, index),
            ),
          ),
          if (index + 1 == _ratingNumber)
            _isRTL
                ? FittedBox(
              fit: BoxFit.contain,
              child: ClipRect(
                clipper: _IndicatorClipper(
                  ratingFraction: _ratingFraction,
                  rtlMode: _isRTL,
                ),
                child: widget.itemBuilder(context, index),
              ),
            )
                : FittedBox(
              fit: BoxFit.contain,
              child: ClipRect(
                clipper: _IndicatorClipper(
                  ratingFraction: _ratingFraction,
                ),
                child: widget.itemBuilder(context, index),
              ),
            ),
        ],
      ),
    ),
  );
}

/// A widget to receive rating input from users.
///
/// [RatingBar] can also be used to display rating
///
/// Prefer using [RatingBarIndicator] instead, if read only version is required.
/// As RatingBarIndicator supports any fractional rating value.
class RatingBar extends StatefulWidget {
  /// {@template flutterRatingBar.itemCount}
  /// Defines total number of rating bar items.
  ///
  /// Default = 5
  /// {@endtemplate}
  final int itemCount;

  /// Defines the initial rating to be set to the rating bar.
  final double initialRating;

  /// Return current rating whenever rating is updated.
  final ValueChanged<double> onRatingUpdate;

  /// {@template flutterRatingBar.itemSize}
  /// Defines width and height of each rating item in the bar.
  ///
  /// Default = 40.0
  /// {@endtemplate}
  final double itemSize;

  /// Default [allowHalfRating] = false. Setting true enables half rating support.
  final bool allowHalfRating;

  /// {@template flutterRatingBar.itemPadding}
  /// The amount of space by which to inset each rating item.
  /// {@endtemplate}
  final EdgeInsets itemPadding;

  /// if set to true, will disable any gestures over the rating bar.
  ///
  /// Default = false
  final bool ignoreGestures;

  /// if set to true will disable drag to rate feature. Note: Enabling this mode will disable half rating capability.
  ///
  /// Default = false
  final bool tapOnlyMode;

  /// {@template flutterRatingBar.textDirection}
  /// The text flows from right to left if [textDirection] = TextDirection.rtl
  /// {@endtemplate}
  final TextDirection textDirection;

  /// {@template flutterRatingBar.itemBuilder}
  /// Widget for each rating bar item.
  /// {@endtemplate}
  final IndexedWidgetBuilder itemBuilder;

  /// Customizes the Rating Bar item with [RatingWidget].
  final RatingWidget ratingWidget;

  /// if set to true, Rating Bar item will glow when being touched.
  ///
  /// Default = true
  final bool glow;

  /// Defines the radius of glow.
  ///
  /// Default = 2
  final double glowRadius;

  /// Defines color for glow.
  ///
  /// Default = theme's accent color
  final Color glowColor;

  /// {@template flutterRatingBar.direction}
  /// Direction of rating bar.
  ///
  /// Default = Axis.horizontal
  /// {@endtemplate}
  final Axis direction;

  /// {@template flutterRatingBar.unratedColor}
  /// Defines color for the unrated portion.
  ///
  /// Default = Colors.grey[200]
  /// {@endtemplate}
  final Color unratedColor;

  /// Sets minimum rating
  ///
  /// Default = 0
  final double minRating;

  /// Sets maximum rating
  ///
  /// Default = [itemCount]
  final double maxRating;

  RatingBar({
    this.itemCount = 5,
    this.initialRating = 0.0,
    @required this.onRatingUpdate,
    this.itemSize = 40.0,
    this.allowHalfRating = false,
    this.itemBuilder,
    this.itemPadding = const EdgeInsets.all(0.0),
    this.ignoreGestures = false,
    this.tapOnlyMode = false,
    this.textDirection,
    this.ratingWidget,
    this.glow = true,
    this.glowRadius = 2,
    this.direction = Axis.horizontal,
    this.glowColor,
    this.unratedColor,
    this.minRating = 0,
    this.maxRating,
  }) : assert(
  (itemBuilder == null && ratingWidget != null) ||
      (itemBuilder != null && ratingWidget == null),
  'itemBuilder and ratingWidget can\'t be initialized at the same time.'
      'Either remove ratingWidget or itembuilder.',
  );

  @override
  _RatingBarState createState() => _RatingBarState();
}

class _RatingBarState extends State<RatingBar> {
  double _rating = 0.0;

  //double _ratingHistory = 0.0;
  double iconRating = 0.0;
  double _minRating, _maxrating;
  bool _isRTL = false;
  ValueNotifier<bool> _glow = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _minRating = widget.minRating;
    _maxrating = widget.maxRating ?? widget.itemCount.toDouble();
    _rating = widget.initialRating;
  }

  @override
  void didUpdateWidget(RatingBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRating != widget.initialRating) {
      _rating = widget.initialRating;
    }
    _minRating = widget.minRating;
    _maxrating = widget.maxRating ?? widget.itemCount.toDouble();
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _isRTL = (widget.textDirection ?? Directionality.of(context)) ==
        TextDirection.rtl;
    iconRating = 0.0;
    return Material(
      color: Colors.transparent,
      child: Wrap(
        alignment: WrapAlignment.start,
        textDirection: _isRTL ? TextDirection.rtl : TextDirection.ltr,
        direction: widget.direction,
        children: List.generate(
          widget.itemCount,
              (index) => _buildRating(context, index),
        ),
      ),
    );
  }

  Widget _buildRating(BuildContext context, int index) {
    Widget ratingWidget;
    if (index >= _rating) {
      ratingWidget = _NoRatingWidget(
        size: widget.itemSize,
        child: widget.ratingWidget?.empty ?? widget.itemBuilder(context, index),
        enableMask: widget.ratingWidget == null,
        unratedColor: widget.unratedColor ?? Colors.grey[200],
      );
    } else if (index >= _rating - (widget.allowHalfRating ? 0.5 : 1.0) &&
        index < _rating &&
        widget.allowHalfRating) {
      if (widget.ratingWidget?.half == null) {
        ratingWidget = _HalfRatingWidget(
          size: widget.itemSize,
          child: widget.itemBuilder(context, index),
          enableMask: widget.ratingWidget == null,
          rtlMode: _isRTL,
          unratedColor: widget.unratedColor ?? Colors.grey[200],
        );
      } else {
        ratingWidget = SizedBox(
          width: widget.itemSize,
          height: widget.itemSize,
          child: FittedBox(
            fit: BoxFit.contain,
            child: _isRTL
                ? Transform(
              transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
              alignment: Alignment.center,
              transformHitTests: false,
              child: widget.ratingWidget.half,
            )
                : widget.ratingWidget.half,
          ),
        );
      }
      iconRating += 0.5;
    } else {
      ratingWidget = SizedBox(
        width: widget.itemSize,
        height: widget.itemSize,
        child: FittedBox(
          fit: BoxFit.contain,
          child:
          widget.ratingWidget?.full ?? widget.itemBuilder(context, index),
        ),
      );
      iconRating += 1.0;
    }

    return IgnorePointer(
      ignoring: widget.ignoreGestures,
      child: GestureDetector(
        onTap: () {
          if (widget.onRatingUpdate != null) {
            widget.onRatingUpdate(index + 1.0);
            setState(() {
              _rating = index + 1.0;
            });
          }
        },
        onHorizontalDragStart: _isHorizontal ? (_) => _glow.value = true : null,
        onHorizontalDragEnd: _isHorizontal
            ? (_) {
          _glow.value = false;
          widget.onRatingUpdate(iconRating);
          iconRating = 0.0;
        }
            : null,
        onHorizontalDragUpdate: _isHorizontal
            ? (dragUpdates) => _dragOperation(dragUpdates, widget.direction)
            : null,
        onVerticalDragStart: _isHorizontal ? null : (_) => _glow.value = true,
        onVerticalDragEnd: _isHorizontal
            ? null
            : (_) {
          _glow.value = false;
          widget.onRatingUpdate(iconRating);
          iconRating = 0.0;
        },
        onVerticalDragUpdate: _isHorizontal
            ? null
            : (dragUpdates) => _dragOperation(dragUpdates, widget.direction),
        child: Padding(
          padding: widget.itemPadding,
          child: ValueListenableBuilder(
            valueListenable: _glow,
            builder: (context, glow, _) {
              if (glow && widget.glow) {
                Color glowColor =
                    widget.glowColor ?? Theme.of(context).accentColor;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withAlpha(30),
                        blurRadius: 10,
                        spreadRadius: widget.glowRadius,
                      ),
                      BoxShadow(
                        color: glowColor.withAlpha(20),
                        blurRadius: 10,
                        spreadRadius: widget.glowRadius,
                      ),
                    ],
                  ),
                  child: ratingWidget,
                );
              } else {
                return ratingWidget;
              }
            },
          ),
        ),
      ),
    );
  }

  bool get _isHorizontal => widget.direction == Axis.horizontal;

  void _dragOperation(DragUpdateDetails dragDetails, Axis direction) {
    if (!widget.tapOnlyMode) {
      RenderBox box = context.findRenderObject();
      var _pos = box.globalToLocal(dragDetails.globalPosition);
      double i;
      if (direction == Axis.horizontal) {
        i = _pos.dx / (widget.itemSize + widget.itemPadding.horizontal);
      } else {
        i = _pos.dy / (widget.itemSize + widget.itemPadding.vertical);
      }
      var currentRating = widget.allowHalfRating ? i : i.round().toDouble();
      if (currentRating > widget.itemCount) {
        currentRating = widget.itemCount.toDouble();
      }
      if (currentRating < 0) {
        currentRating = 0.0;
      }
      if (_isRTL && widget.direction == Axis.horizontal) {
        currentRating = widget.itemCount - currentRating;
      }
      if (widget.onRatingUpdate != null) {
        if (currentRating < _minRating) {
          _rating = _minRating;
        } else if (currentRating > _maxrating) {
          _rating = _maxrating;
        } else {
          _rating = currentRating;
        }
        setState(() {});
      }
    }
  }
}
