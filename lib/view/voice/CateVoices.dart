import 'package:book/common/common.dart';
import 'package:book/common/net.dart';
import 'package:book/entity/VoiceMore.dart';
import 'package:book/route/Routes.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class CateVoices extends StatefulWidget {
  final String url;

  CateVoices(this.url);

  @override
  _CateVoicesState createState() => _CateVoicesState();
}

class _CateVoicesState extends State<CateVoices> {
  List<VoiceMore> _voiceIdxs = [];

  @override
  void initState() {
    super.initState();
    getData();
  }

  getData() async {
    var formData = FormData.fromMap({"key": this.widget.url});
    Response resp =
        await Util(null).http().post(Common.voiceMore, data: formData);
    List data = resp.data;
    for (var d in data) {
      _voiceIdxs.add(VoiceMore.fromJson(d));
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return _voiceIdxs.isEmpty
        ? Scaffold()
        : Scaffold(
            appBar: AppBar(title: Text("听书历史")),
            body: Container(
              child: ListView(
                  children: _voiceIdxs
                      .map((e) => ListTile(
                            title: Text(e.title),
                            trailing: Text(e.date),
                            onTap: () {
                              Routes.navigateTo(context, Routes.voiceDetail,
                                  params: {"link": e.href, "idx": "0"});
                            },
                          ))
                      .toList()),
            ),
          );
  }
}
