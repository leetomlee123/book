import 'dart:convert';
import 'dart:io';

import 'package:book/common/Http.dart';
import 'package:book/common/Screen.dart';
import 'package:book/entity/EveryPoet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class NoMorePage extends StatefulWidget {
  @override
  _NoMorePageState createState() => _NoMorePageState();
}

class _NoMorePageState extends State<NoMorePage> {
  EveryPoet _everyPoet;
  @override
  void initState() {
    super.initState();
    getEveryNote();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Offstage(
          child: Container(
            width: Screen.width,
            height: Screen.height,
            decoration: BoxDecoration(
                image: DecorationImage(
                    image:
                        CachedNetworkImageProvider('${_everyPoet?.share ?? ''}'),
                    fit: BoxFit.fitWidth)),
          ),
          offstage: _everyPoet == null),
    );

    // return Ad();
  }

  getEveryNote() async {
    if (_everyPoet != null) {
      return;
    }
    var url = "http://open.iciba.com/dsapi";
    var client = new HttpClient();

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
