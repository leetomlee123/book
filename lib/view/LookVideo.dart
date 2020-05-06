import 'dart:convert';

import 'package:book/common/LoadDialog.dart';
import 'package:book/common/PicWidget.dart';
import 'package:book/common/common.dart';
import 'package:book/common/util.dart';
import 'package:book/entity/GBook.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:chewie/chewie.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class LookVideo extends StatefulWidget {
  String id;

  LookVideo(this.id);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return LookVideoState();
  }
}

class LookVideoState extends State<LookVideo> {
  ColorModel colorModel;
  VideoPlayerController videoPlayerController;

  ChewieController chewieController;
  List<Widget> wds = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getData();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    videoPlayerController.dispose();
    chewieController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    colorModel = Store.value<ColorModel>(context);
    // TODO: implement build
    return chewieController != null
        ? Material(
            child: Theme(
              child: SingleChildScrollView(
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: wds,
                  ),
                ),
              ),
              data: colorModel.theme,
            ),
          )
        : Material(child: LoadingDialog());
  }

  getData() async {
    String url = Common.look_m + '/${this.widget.id}';
    Response future = await Util(null).http().get(url);
    videoPlayerController = VideoPlayerController.network(future.data[2]);

    chewieController = ChewieController(
      videoPlayerController: videoPlayerController,
      aspectRatio: 3 / 2,
      autoPlay: true,
      looping: true,
    );
    wds.add(Chewie(
      controller: chewieController,
    ));
    for (var i = 0; i < 2; i++) {
      List list = future.data[i];
      if (list.isNotEmpty) {
        List<GBook> list2 = list.map((f) => GBook.fromJson(f)).toList();
        wds.add(item(i == 0 ? "每日更新" : "喜欢这个视频的人也喜欢···", list2));
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  Widget item(String title, List<GBook> bks) {
    return Container(
      child: ListView(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: <Widget>[
          Row(
            children: <Widget>[
              Padding(
                child: Container(
                  width: 4,
                  height: 20,
//                  color: value.dark
//                      ? value.theme.textTheme.body1.color
//                      : value.theme.primaryColor,
                ),
                padding: EdgeInsets.only(left: 5.0, right: 3.0),
              ),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: Container(),
              ),
//              GestureDetector(
//                child: Row(
//                  children: <Widget>[
//                    Text(
//                      "更多",
//                      style: TextStyle(color: Colors.grey),
//                    ),
//                    Icon(
//                      Icons.keyboard_arrow_right,
//                      color: Colors.grey,
//                    )
//                  ],
//                ),
//                onTap: () {
////                  Routes.navigateTo(context, Routes.allTagBook,
////                      params: {"title": title, "bks": jsonEncode(bks)});
//                },
//              )
            ],
          ),
          GridView(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(5.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 1.0,
                crossAxisSpacing: 10.0,
                childAspectRatio: 0.7),
            children: bks.map((i) => img(i)).toList(),
          )
        ],
      ),
    );
  }

  Widget img(GBook gbk) {
    return GestureDetector(
      child: Column(
        children: <Widget>[
          PicWidget(
            gbk.cover,
            width: (ScreenUtil.getScreenW(context) - 40) / 3,
            height: ((ScreenUtil.getScreenW(context) - 40) / 3) * 1.2,
          ),
          Expanded(
            child: Container(),
          ),
          Text(
            gbk.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        ],
      ),
      onTap: () async {
        Navigator.pop(context);
        Routes.navigateTo(context, Routes.vDetail,
            params: {"gbook": jsonEncode(gbk)});
      },
    );
  }
}
