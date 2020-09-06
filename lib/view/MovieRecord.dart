import 'dart:convert';

import 'package:book/common/PicWidget.dart';
import 'package:book/common/common.dart';
import 'package:book/entity/MRecords.dart';
import 'package:book/route/Routes.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';

class MovieRecord extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<Widget> wds = [];
    List<MRecords> mrds = [];
    if (SpUtil.haveKey(Common.movies_record)) {
      List stringList = jsonDecode(SpUtil.getString(Common.movies_record));

      mrds = stringList.map((f) => MRecords.fromJson(f)).toList();
      for (var i = mrds.length - 1; i >= 0; i--) {
        MRecords value = mrds[i];
        wds.add(GestureDetector(
          child: ListTile(
            leading: PicWidget(
              value.cover,
            ),
            title: Text(
              value.name,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(value.cname),
          ),
          onTap: () {
            Routes.navigateTo(context, Routes.lookVideo, params: {
              "id": value.cid,
              "mcids": value.mcids ?? [],
              "cover": value.cover,
              "name": value.name
            });
          },
        ));
        wds.add(Divider());
      }
    }
    if (wds.isEmpty) {
      wds.add(Center(
        child: Text("暂无观看记录"),
      ));
    }
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('观看记录'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        children: wds,
      ),
    );
  }
}
