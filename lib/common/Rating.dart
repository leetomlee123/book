import 'package:flutter/material.dart';

class Rating extends StatefulWidget {
  final int initialRating;
  final void Function(int)? onRated;
  final double size;
  final Color color;

  const Rating(
      {super.key, this.initialRating = 0,
      this.onRated,
      this.size = 18.0,
      this.color = Colors.amber});

  @override
  State<Rating> createState() => _RatingState();
}

class _RatingState extends State<Rating> {
  int _rating = 0;
  final GlobalKey _starOneKey = GlobalKey();
  final GlobalKey _starTwoKey = GlobalKey();
  final GlobalKey _starThreeKey = GlobalKey();
  final GlobalKey _starFourKey = GlobalKey();
  final GlobalKey _starFiveKey = GlobalKey();
  bool _isDragging = false;

  void _updateRating(int newRating) {
    if (_rating == 1 && newRating == 1 && _isDragging != true) {
      setState(() {
        _rating = 0;
        widget.onRated?.call(0);
      });
    } else {
      setState(() {
        _rating = newRating;
        widget.onRated?.call(newRating);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (DragStartDetails details) {
        _isDragging = true;
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        RenderBox? star1 =
            _starOneKey.currentContext?.findRenderObject() as RenderBox?;
        if (star1 == null) return;
        final positionStar1 = star1.localToGlobal(Offset.zero);
        final sizeStar1 = star1.size;

        RenderBox? star2 =
            _starTwoKey.currentContext?.findRenderObject() as RenderBox?;
        if (star2 == null) return;
        final positionStar2 = star2.localToGlobal(Offset.zero);
        final sizeStar2 = star2.size;

        RenderBox? star3 =
            _starThreeKey.currentContext?.findRenderObject() as RenderBox?;
        if (star3 == null) return;
        final positionStar3 = star3.localToGlobal(Offset.zero);
        final sizeStar3 = star3.size;

        RenderBox? star4 =
            _starFourKey.currentContext?.findRenderObject() as RenderBox?;
        if (star4 == null) return;
        final positionStar4 = star4.localToGlobal(Offset.zero);
        final sizeStar4 = star4.size;

        RenderBox? star5 =
            _starFiveKey.currentContext?.findRenderObject() as RenderBox?;
        if (star5 == null) return;
        final positionStar5 = star5.localToGlobal(Offset.zero);
        final sizeStar5 = star5.size;

        if (details.globalPosition.dx < positionStar1.dx) {
          _updateRating(0);
        } else if (details.globalPosition.dx > positionStar1.dx &&
            details.globalPosition.dx < (positionStar1.dx + sizeStar1.width)) {
          _updateRating(1);
        } else if (details.globalPosition.dx > positionStar2.dx &&
            details.globalPosition.dx < (positionStar2.dx + sizeStar2.width)) {
          _updateRating(2);
        } else if (details.globalPosition.dx > positionStar3.dx &&
            details.globalPosition.dx < (positionStar3.dx + sizeStar3.width)) {
          _updateRating(3);
        } else if (details.globalPosition.dx > positionStar4.dx &&
            details.globalPosition.dx < (positionStar4.dx + sizeStar4.width)) {
          _updateRating(4);
        } else if (details.globalPosition.dx > positionStar5.dx &&
            details.globalPosition.dx < (positionStar5.dx + sizeStar5.width)) {
          _updateRating(5);
        } else if (details.globalPosition.dx >
            (positionStar1.dx + sizeStar1.width)) {
          _updateRating(5);
        }
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        _isDragging = false;
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            key: _starOneKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3.0),
              child: Icon(
                _rating >= 1 ? Icons.star : Icons.star_border,
                color: widget.color,
                size: widget.size,
              ),
            ),
            onTap: () => _updateRating(1),
          ),
          GestureDetector(
            key: _starTwoKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3.0),
              child: Icon(
                _rating >= 2 ? Icons.star : Icons.star_border,
                color: widget.color,
                size: widget.size,
              ),
            ),
            onTap: () => _updateRating(2),
          ),
          GestureDetector(
            key: _starThreeKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3.0),
              child: Icon(
                _rating >= 3 ? Icons.star : Icons.star_border,
                color: widget.color,
                size: widget.size,
              ),
            ),
            onTap: () => _updateRating(3),
          ),
          GestureDetector(
            key: _starFourKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3.0),
              child: Icon(
                _rating >= 4 ? Icons.star : Icons.star_border,
                color: widget.color,
                size: widget.size,
              ),
            ),
            onTap: () => _updateRating(4),
          ),
          GestureDetector(
            key: _starFiveKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3.0),
              child: Icon(
                _rating >= 5 ? Icons.star : Icons.star_border,
                color: widget.color,
                size: widget.size,
              ),
            ),
            onTap: () => _updateRating(5),
          ),
        ],
      ),
    );
  }
}
