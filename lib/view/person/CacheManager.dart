import 'dart:convert';

import 'package:book/common/common.dart';
import 'package:book/entity/BookTag.dart';
import 'package:book/entity/Chapter.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/store/Store.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';

class CacheManager extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _CacheManager();
  }
}

class _CacheManager extends State<CacheManager> {
  @override
  Widget build(BuildContext context) {
    return Store.connect<ColorModel>(
        builder: (context, ColorModel data, child) => Theme(
              child: Scaffold(
                appBar: AppBar(
                  title: Text("缓存管理"),
                  centerTitle: true,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                ),
                body: ListView(
                  children: managers(Theme.of(context).primaryColor),
                ),
              ),
              // data: data.theme,
            ));
  }

  List<Widget> managers(Color color) {
    List<Widget> wds = [];
    if (SpUtil.haveKey(Common.downloadlist)) {
      List<String> ids = SpUtil.getStringList(Common.downloadlist);
      ids.forEach((f) {
        wds.add(item(f, color));
      });
    }
    return wds;
  }

  Widget item(id, Color color) {
    List list = jsonDecode(SpUtil.getString('${id}chapters'));
    List all = list.map((e) => Chapter.fromJson(e)).toList();
    BookTag bookTag = BookTag.fromJson(jsonDecode(SpUtil.getString(id)));
    int sub = 0;
    all.forEach((f) {
      if (f.hasContent == 2) {
        sub += 1;
      }
    });
    return Card(
      child: Column(
        children: <Widget>[
          Text(bookTag.bookName),
          Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  child: Slider(
                    activeColor: Colors.white,
                    inactiveColor: Colors.white70,
                    value: sub.toDouble(),
                    max: all.length.toDouble(),
                    min: 0.0,
                    onChanged: (v){

                    },
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.arrow_downward),
                onPressed: () {
                  // var value = Store.value<ReadModel>(context);
                  // value.bookTag = bookTag;
                  // value.book = BookInfo.x(id);
                  // value.downloadAll();
                },
              )
            ],
          )
        ],
      ),
    );
  }
}
