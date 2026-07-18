import 'dart:convert';
import 'dart:io';

import 'package:book/common/Http.dart';
import 'package:book/common/Screen.dart';
import 'package:book/entity/EveryPoet.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

class NoMorePage extends StatefulWidget {
  @override
  _NoMorePageState createState() => _NoMorePageState();
}

class _NoMorePageState extends State<NoMorePage> {
  EveryPoet? _everyPoet;
  @override
  void initState() {
    super.initState();
    getEveryNote();
  }

  @override
  Widget build(BuildContext context) {
    final share = _everyPoet?.share ?? '';
    return Scaffold(
      body: Offstage(
        offstage: _everyPoet == null,
        child: Container(
          width: Screen.width,
          height: Screen.height,
          decoration: share.isEmpty
              ? null
              : BoxDecoration(
                  image: DecorationImage(
                    image: ExtendedNetworkImageProvider(share, cache: true),
                    fit: BoxFit.fitWidth,
                  ),
                ),
        ),
      ),
    );
  }

  getEveryNote() async {
    if (_everyPoet != null) {
      return;
    }
    var url = "http://open.iciba.com/dsapi";
    var client = HttpClient();

    var request = await client.getUrl(Uri.parse(url));
    var response = await request.close();

    var responseBody = await response.transform(utf8.decoder).join();
    var dataList = await parseJson(responseBody);

    _everyPoet = EveryPoet(dataList['note'], dataList['picture4'],
        dataList['content'], dataList['fenxiang_img']);
    if (mounted) {
      setState(() {});
    }
  }
}
