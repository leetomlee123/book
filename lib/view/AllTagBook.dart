import 'dart:convert';

import 'package:book/common/PicWidget.dart';
import 'package:book/common/common.dart';
import 'package:book/common/util.dart';
import 'package:book/entity/BookInfo.dart';
import 'package:book/entity/GBook.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AllTagBook extends StatelessWidget {
  String title;
  List<GBook> bks;

  AllTagBook(this.title, this.bks);

  @override
  Widget build(BuildContext context) {
    Widget img(GBook gbk) {
      return Container(
        child: Column(
          children: <Widget>[
            GestureDetector(
              child: PicWidget(
                gbk.cover,
                fitOk: true,
              ),
              onTap: () async {
                String url = Common.detail + '/${gbk.id}';
                Response future = await Util(context).http().get(url);
                var d = future.data['data'];
                if (d == null) {
                  Routes.navigateTo(context, Routes.search, params: {
                    "type":"book",
                    "name": gbk.name,
                  });
                } else {
                  BookInfo bookInfo = BookInfo.fromJson(d);
                  Routes.navigateTo(context, Routes.detail,
                      params: {"detail": jsonEncode(bookInfo)});
                }
              },
            ),
            Text(
              gbk.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          ],
        ),
      );
    }

    // TODO: implement build
    return Store.connect<ColorModel>(
        builder: (context, ColorModel data, child) => Theme(
          data: data.theme,
          child: Scaffold(
              appBar: AppBar(
                title: Text(title),
                centerTitle: true,
                elevation: 0,
              ),
              body: ListView(
                children: <Widget>[
                  GridView(
                    shrinkWrap: true,
                    physics: new NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.all(5.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 1.0,
                        crossAxisSpacing: 10.0,
                        childAspectRatio: 0.6),
                    children: bks.map((item) => img(item)).toList(),
                  )
                ],
              )),
        ));
  }
}