import 'package:book/common/common.dart';
import 'package:book/common/Http.dart';
import 'package:book/entity/Info.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/store/Store.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';

class InfoPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return InfoState();
  }
}

class InfoState extends State<InfoPage> {
  List<Info> ifs = [];

  @override
  void initState() {
    super.initState();
    getInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Store.connect<ColorModel>(
        builder: (context, ColorModel data, child) => Theme(
              child: Scaffold(
                appBar: AppBar(
                   backgroundColor: Colors.transparent,
                  title: Text("公告",style: TextStyle(color: data.dark ? Colors.white : Colors.black),),
                  centerTitle: true,
                  elevation: 0,
                ),
                body: Padding(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Center(
                        child: Text(ifs.length == 0 ? "公告" : ifs[0].Title),
                      ),
                      Container(
                        child: Text(
                          ifs.length == 0 ? "太平无事" : ifs[0].Content,
                          textAlign: TextAlign.start,
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Container(),
                          ),
                          Text(
                            ifs.length == 0
                                ? DateUtil.getNowDateStr()
                                : ifs[0].Date,
                            textAlign: TextAlign.start,
                          )
                        ],
                      )
                    ],
                  ),
                  padding: EdgeInsets.all(15),
                ),
              ),
              // data: data.theme,
            ));
  }

  Future<void> getInfo() async {
    Response res = await HttpUtil().http().get(Common.info);
    List data = res.data['data'];
    if (data == null) {
      return;
    }
    ifs = data.map((f) => Info.fromJson(f)).toList();
    if (mounted) {
      setState(() {});
    }
  }
}
