import 'dart:convert';

import 'package:better_player/better_player.dart';
import 'package:book/common/FunUtil.dart';
import 'package:book/common/Http.dart';
import 'package:book/common/PicWidget.dart';
import 'package:book/common/common.dart';
import 'package:book/entity/GBook.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:screen/screen.dart' as Light;

class LookVideo extends StatefulWidget {
  final String id;
  final List<dynamic> mcids;
  final String name;
  final String cover;

  LookVideo(this.id, this.mcids, this.name, this.cover);

  @override
  State<StatefulWidget> createState() {
    return LookVideoState();
  }
}

class LookVideoState extends State<LookVideo> with WidgetsBindingObserver {
  ColorModel _colorModel;
  int idx = 0;
  BetterPlayerController _betterPlayerController;

  String source;

  List<Widget> wds = [];
  Widget cps;
  double light;
  bool initOk = false;
  var urlKey;
  var name;

  @override
  void initState() {
    _colorModel = Store.value<ColorModel>(context);
    WidgetsBinding.instance.addObserver(this);
    urlKey = this.widget.id;
    super.initState();
    getData();
  }

  @override
  Future<void> dispose() async {
    super.dispose();

    _betterPlayerController?.dispose();
    WidgetsBinding.instance.removeObserver(this);

    saveRecord(await _betterPlayerController.videoPlayerController.position);
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    saveRecord(await _betterPlayerController.videoPlayerController.position);
  }

  saveRecord(Duration position) {
    if (position == null) {
      return;
    }
    if (SpUtil.haveKey(source)) {
      SpUtil.remove(source);
    }

    SpUtil.putInt(source, position.inMicroseconds);
  }

  @override
  Widget build(BuildContext context) {
    return wds.isNotEmpty
        ? Scaffold(
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: ScreenUtil.getStatusBarH(context),
                  color: Colors.black,
                ),
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: BetterPlayer(controller: _betterPlayerController),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                  child: Row(
                    children: [
                      Text(this.widget.name),
                      Spacer(),
                    ],
                  ),
                ),
                cps,
                SizedBox(
                  height: 10,
                ),
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: wds,
                  ),
                )
              ],
            ),
          )
        : Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  getData() async {
    light = await Light.Screen.brightness;
    Response future = await play(urlKey);

    cps = Center(
      child: Wrap(
        runAlignment: WrapAlignment.start,
        spacing: 4, //主轴上子控件的间距
        runSpacing: 5, //交叉轴上子控件之间的间
        children: mItems(this.widget.mcids),
      ),
    );

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

  Future<Response> play(var id) async {
    Response future = await getUrl(id);
    source = future.data[2];
    BetterPlayerConfiguration betterPlayerConfiguration =
        BetterPlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,

      controlsConfiguration: BetterPlayerControlsConfiguration(

      ),
    );
    BetterPlayerDataSource dataSource =
        BetterPlayerDataSource(BetterPlayerDataSourceType.network, source);
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(dataSource).then((value) {
      if (SpUtil.haveKey(source)) {
        int p = SpUtil.getInt(source);
        _betterPlayerController.seekTo(Duration(microseconds: p));
      }
    });
    return future;
  }

  Future<Response> getUrl(var key) async {
    String url = Common.look_m + key;
    Response future = await HttpUtil().http().get(url);
    return future;
  }

  void _urlChange(url, name, {autoPlay = true, allowFullScreen = true}) async {
    saveRecord(_betterPlayerController.videoPlayerController.value.position);

    if (_betterPlayerController != null) {
      /// 如果控制器存在，清理掉重新创建
      // videoPlayerController.removeListener(_videoListener);
      _betterPlayerController.pause();
//      videoPlayerController.dispose();
    }
    setState(() {
      urlKey = url;
    });
    getData();

  }

  List<Widget> mItems(List<dynamic> list) {
    List<Widget> wds = [];
    for (var i = 0; i < list.length; i++) {
      Map map = Map.castFrom(list[i]);
      if (map.keys.elementAt(0) == urlKey) {
        idx = i;
      }
      wds.add(GestureDetector(
          onTap: () {
            var jsonEncode2 = jsonEncode(list);
            FunUtil.saveMoviesRecord(this.widget.cover, this.widget.name,
                map.keys.elementAt(0), map.values.elementAt(0), jsonEncode2);
            saveRecord(
                _betterPlayerController.videoPlayerController.value.position);
            _urlChange(map.keys.elementAt(0), map.values.elementAt(0));
          },
          child: Container(
            margin: EdgeInsets.only(top: 8),
            child: Text(
              map.values.elementAt(0),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: map.keys.elementAt(0) == urlKey
                      ? (_colorModel.dark
                          ? Colors.white
                          : _colorModel.theme.primaryColor)
                      : (_colorModel.dark ? Colors.white38 : null)),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(
                  color: map.keys.elementAt(0) == urlKey
                      ? (_colorModel.dark
                          ? Colors.white
                          : _colorModel.theme.primaryColor)
                      : (_colorModel.dark ? Colors.white38 : Colors.black),
                  width: 0.75),
            ),
          )));
    }
    return wds;
  }

  Widget item(String title, List<GBook> bks) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8),
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
            padding: EdgeInsets.all(10.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 20.0,
                crossAxisSpacing: 23.0,
                childAspectRatio: 0.6),
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
