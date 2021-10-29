import 'package:book/common/common.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';


class MyShimmer extends StatefulWidget {
  @override
  _State createState() => _State();
}

class _State extends State<MyShimmer> {
  List<CoinRankingListItemSkeleton> items = [];
  @override
  void initState() {
    super.initState();
    for (var i = 0; i < SpUtil.getInt(Common.shimmer_nums); i++) {
      items.add(CoinRankingListItemSkeleton());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade400,
        highlightColor:  Colors.white,
        child: Column(
          children: items,
          mainAxisAlignment: MainAxisAlignment.center,
        ),
      ),
    );
  }
}

class CoinRankingListItemSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15),
      child: Container(
        child: Center(
          child: Column(
            children: <Widget>[
              Container(height: 15.0, color: Colors.grey.shade100),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
