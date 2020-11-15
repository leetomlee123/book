import 'package:flutter/material.dart';

class StickDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _child;

  StickDelegate(this._child);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return this._child;
  }

  @override
  double get maxExtent => this._child.preferredSize.height;

  @override
  double get minExtent => this._child.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
