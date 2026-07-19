import 'package:book/event/event.dart';
import 'package:flutter/material.dart';

class DownloadProgressUI extends StatefulWidget {
  final dynamic url;

  const DownloadProgressUI(this.url, {super.key});

  @override
  State<DownloadProgressUI> createState() => _DownloadProgressState();
}

class _DownloadProgressState extends State<DownloadProgressUI> {
  var v = .0;

  @override
  void initState() {
    super.initState();
    eventBus.on<DownLoadNotify>().listen((event) {
      if (widget.url == event.url) {
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
    // Keep two fractional digits, e.g. 37.25%
    final pct = (v.clamp(0.0, 1.0) * 100).toStringAsFixed(2);
    return Center(child: Text('$pct%'));
  }
}
