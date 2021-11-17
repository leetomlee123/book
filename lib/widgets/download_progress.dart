import 'package:book/event/event.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';

class DownloadProgressUI extends StatefulWidget {
  var url;

  DownloadProgressUI(this.url, {Key key}) : super(key: key);

  @override
  _DownloadProgressState createState() => _DownloadProgressState();
}

class _DownloadProgressState extends State<DownloadProgressUI> {
  var v = .0;

  @override
  void initState() {
    super.initState();
    eventBus.on<DownLoadNotify>().listen((event) {
      if (this.widget.url == event.url) {
        if (mounted) {
          setState(() {
            v = event.v;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Text("${NumUtil.multiply(v, 100)}%"));
  }
}
