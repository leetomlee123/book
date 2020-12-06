import 'dart:convert';

import 'package:book/common/common.dart';
import 'package:book/common/net.dart';
import 'package:book/entity/VoiceIdx.dart';
import 'package:book/entity/VoiceOV.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class VoiceBook extends StatefulWidget {
  @override
  _VoiceBookState createState() => _VoiceBookState();
}

class _VoiceBookState extends State<VoiceBook>  with WidgetsBindingObserver{
  List<VoiceIdx> _voiceIdxs = [];
  ColorModel _colorModel;
  @override
  void initState() {
    _colorModel = Store.value<ColorModel>(context);
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListView(
          children:
              _voiceIdxs.map((e) => item(e.cate, e.link, e.voices)).toList()),
    );
  }

  Widget item(String title, String link, List<VoiceOV> bks) {
    return Container(
      child: ListView(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: <Widget>[
          SizedBox(
            height: 5.0,
          ),
          Row(
            children: <Widget>[
              Padding(
                child: Container(
                  width: 4,
                  height: 20,
                  color: _colorModel.dark
                      ? Colors.white
                      : _colorModel.theme.primaryColor,
                ),
                padding: EdgeInsets.only(left: 5.0, right: 3.0),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.0,
                ),
              ),
              Expanded(
                child: Container(),
              ),
              GestureDetector(
                child: Row(
                  children: <Widget>[
                    Text(
                      "更多",
                      style: TextStyle(color: Colors.grey, fontSize: 11.0),
                    ),
                    Icon(
                      Icons.keyboard_arrow_right,
                      color: Colors.grey,
                    )
                  ],
                ),
                onTap: () {
                  Routes.navigateTo(context, Routes.allTagBook,
                      params: {"title": title, "bks": jsonEncode(bks)});
                },
              )
            ],
          ),
          Column(
            children: bks
                .map((e) => ListTile(
                      title: Text(e.name),
                      trailing: Text(e.date),
                      onTap: () {
                        Routes.navigateTo(context, Routes.voiceDetail,
                            params: {"link": e.link});
                      },
                    ))
                .toList(),
          )
        ],
      ),
    );
  }

  getData() async {
    Response resp = await Util(context).http().get(Common.voiceIndex);
    List data = resp.data;
    for (var d in data) {
      _voiceIdxs.add(VoiceIdx.fromJson(d));
    }
    if (mounted) {
      setState(() {});
    }
  }
}
