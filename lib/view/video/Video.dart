import 'package:flutter/material.dart';

/// Video feature is deprioritized for the Dart 3 / Flutter 3.44 migration.
/// Placeholder so analysis does not fail on removed flutter_swiper / keframe deps.
class Video extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return VideoState();
  }
}

class VideoState extends State<Video> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("美剧"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Text("视频功能暂不可用"),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class MHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[],
    );
  }
}
