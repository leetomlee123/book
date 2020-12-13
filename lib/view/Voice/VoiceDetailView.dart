import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:book/common/DbHelper.dart';
import 'package:book/common/Screen.dart';
import 'package:book/common/common.dart';
import 'package:book/common/net.dart';
import 'package:book/entity/VoiceDetail.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/VoiceModel.dart';
import 'package:book/service/CustomCacheManager.dart';
import 'package:book/store/Store.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class VoiceDetailView extends StatefulWidget {
  String link;
  int idx;

  //  int position;
  VoiceDetailView(this.link, this.idx);

  @override
  _VoiceDetailState createState() => _VoiceDetailState();
}

class _VoiceDetailState extends State<VoiceDetailView>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  ColorModel _colorModel;

  // AnimationController controller;
  // VoiceDetail _voiceDetail;
  VoiceModel _voiceModel;
  double position = 0.1;
  String start = "00:00";
  String end = "00:00";

  double len = 1000000.0;
  List<double> fasts = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5];
  String link = '';
  String url = '';
  bool getAllTime = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // controller = AnimationController(
    //     duration: const Duration(seconds: 100), vsync: this);
    // var widgetsBinding = WidgetsBinding.instance;
    // widgetsBinding.addPostFrameCallback((callback) async {
    _colorModel = Store.value<ColorModel>(context);
    _voiceModel = Store.value<VoiceModel>(context);
    // _voiceModel.audioPlayer.stop();
    //   _voiceModel.init(this.widget.link);
    // });
    if (_voiceModel.audioPlayer.state == AudioPlayerState.PLAYING) {
      if (this.widget.link != _voiceModel.link) {
        init();
      }
    } else {
      init();
    }
  }

  init() async {
    Response resp = await Util(null)
        .http()
        .get(Common.voiceDetail + "?key=${this.widget.link}");
    var data = resp.data;
    _voiceModel.voiceDetail = VoiceDetail.fromJson(data);
    link = this.widget.link;

    Map<String, int> x =
        await DbHelper().getVoiceRecord(this.widget.link, _voiceModel.idx);

    if (_voiceModel.audioPlayer.state == AudioPlayerState.PLAYING) {
      saveRecord();
      _voiceModel.audioPlayer.release();
    }
    print('get link ${this.widget.link}');

    _voiceModel.setFast(SpUtil.getDouble("voice_fast") ?? 1.0);

    _voiceModel.setIdx1(x['idx'] == -1 ? 0 : x['idx']);

    Response resp1 = await Util(null).http().get(Common.voiceUrl +
        "?url=${_voiceModel.voiceDetail.chapters[_voiceModel.idx].link}");

    url = resp1.data['url'];
    int p = 0;
    if (_voiceModel.idx >= 0) {
      p = x['position'];
      _voiceModel.position = p.toDouble();
    }
    if(mounted){
      setState(() {
        
      });
    }
    initAudio(p);
  }

  initAudio(int p) async {
    if (kIsWeb) {
      return;
    }

    int result = await _voiceModel.audioPlayer
        .play(url, position: Duration(milliseconds: p), stayAwake: true);
    _voiceModel.audioPlayer.setPlaybackRate(playbackRate: _voiceModel.fast);
    if (result == 1) {
      print("success");

      _voiceModel.link = link;
      _voiceModel.stateImg = 'btv';
    }
    // controller.forward();

    _voiceModel.audioPlayer.onDurationChanged.listen((Duration d) {
      if (!getAllTime) {
        len = d.inMilliseconds.toDouble();
        _voiceModel.len = len;
        end = DateUtil.formatDateMs(d.inMilliseconds, format: "mm:ss");
        _voiceModel.end = end;
        getAllTime = true;
      }
    });

    _voiceModel.audioPlayer.onAudioPositionChanged.listen((Duration p) {
      _voiceModel.change(p.inMilliseconds);
    });
    _voiceModel.audioPlayer.onPlayerCompletion.listen((event) {
      // controller.dispose();
      // controller.didUnregisterListener();
      changeUrl(1);
    });
  }

//旋转
  Widget buildRotationTransition() {
    return Center(
      child: _voiceModel.voiceDetail.cover.isEmpty
          ? Container(
              width: 160,
              height: 220,
              decoration: BoxDecoration(
                  // color: Colors.green,
                  // borderRadius: BorderRadius.circular(150),
                  // 圆形图片
                  image: DecorationImage(
                      image: AssetImage("images/nocover.jpg"),
                      fit: BoxFit.cover)),
            )
          : Container(
              width: 160,
              height: 220,
              decoration: BoxDecoration(
                  // color: Colors.green,
                  // borderRadius: BorderRadius.circular(150),
                  // 圆形图片
                  image: DecorationImage(
                      image: CachedNetworkImageProvider(
                          _voiceModel.voiceDetail.cover),
                      fit: BoxFit.cover)),
            ),
    );
  }

  saveRecord() async {
    int position = await _voiceModel?.audioPlayer?.getCurrentPosition() ?? 0;
    print(
        "save ${_voiceModel.voiceDetail?.title} position is $position key is ${_voiceModel.link} idx is ${_voiceModel.idx}");
    DbHelper().saveVoiceRecord(
        _voiceModel.link,
        _voiceModel.voiceDetail?.cover ?? '',
        _voiceModel.voiceDetail?.title ?? '',
        _voiceModel.voiceDetail?.author ?? '',
        _voiceModel.position.toInt() ?? 0,
        _voiceModel.idx,
        _voiceModel.voiceDetail.chapters[_voiceModel.idx].name);
    // DbHelper().voices();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    saveRecord();

    // if (state == AppLifecycleState.inactive) {
    //   if (_audioPlayer.state == AudioPlayerState.PLAYING) {
    //     _audioPlayer.pause();
    //   }
    // } else if (state == AppLifecycleState.resumed) {
    //   if (_audioPlayer.state == AudioPlayerState.PAUSED) {
    //     _audioPlayer.resume();
    //   }
    // }
  }

  @override
  void dispose() {
    // voiceDetail = null;
    // if (_voiceModel.link == link) {
    saveRecord();
    // }
    // _audioPlayer.dispose();
    // _voiceModel.audioPlayer.dispose();
    // controller.dispose();
    super.dispose();
  }

  changeUrl(int idx, {bool flag = true}) async {
    if (flag) {
      if (_voiceModel.idx + idx < 0) {
        BotToast.showText(text: "已经是第一节");
        return;
      }
      if (_voiceModel.idx + idx >= _voiceModel.voiceDetail.chapters.length) {
        BotToast.showText(text: "已经是最后一节");
        return;
      }
      _voiceModel.audioPlayer.release();

      _voiceModel.setIdx(idx);
    } else {
      saveRecord();
      _voiceModel.audioPlayer.release();

      _voiceModel.setIdx1(idx);
    }

    var ux = _voiceModel.voiceDetail.chapters[_voiceModel.idx].link;

    Response resp1 = await Util(null).http().get(Common.voiceUrl + "?url=$ux");

    url = resp1.data['url'];
    initAudio(0);
  }

  Widget _tap(img, func) {
    return InkWell(
      child: Container(
        width: 40,
        height: 40,
        child: Image(
          color: _colorModel.dark ? Colors.white : Colors.black,
          image: AssetImage("images/$img.png"),
        ),
      ),
      onTap: func,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _voiceModel.voiceDetail == null
        ? Scaffold()
        : Scaffold(body: Store.connect<VoiceModel>(
            builder: (context, VoiceModel model, child) {
            return ListView(
              shrinkWrap: true,
              children: [
                Column(
                  children: [
                    SizedBox(
                      height: Screen.topSafeHeight,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        buildRotationTransition(),
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Column(
                        children: [
                          Text(
                            _voiceModel.voiceDetail?.title ?? '',
                            style: TextStyle(
                                color: _colorModel.dark
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 25),
                          ),
                          Text(
                            _voiceModel.voiceDetail?.author ?? '',
                            style: TextStyle(
                                color: _colorModel.dark
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 14),
                          ),
                          Text(
                            _voiceModel.voiceDetail?.chapters[_voiceModel.idx]
                                    .name ??
                                '',
                            style: TextStyle(
                                color: _colorModel.dark
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 14),
                          ),
                        ],
                      )
                    ]),
                    SizedBox(
                      height: 40,
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(model.start),
                          Expanded(
                              child: Slider(
                            value: model.position,
                            max: model.len,
                            min: 0.0,
                            onChanged: (v) {
                              _voiceModel.audioPlayer
                                  .seek(Duration(milliseconds: v.floor()));
                            },
                            activeColor: _colorModel.dark
                                ? Colors.white
                                : _colorModel.theme.primaryColor,
                          )),
                          Text(model.end),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _listCps(),
                          _tap("btx", () {
                            changeUrl(-1);
                          }),
                          _tap(_voiceModel.stateImg, () async {
                            if (_voiceModel.stateImg == "btw") {
                              _voiceModel.audioPlayer.resume();
                              _voiceModel.setStateImg("btv");
                              print("stop");
                            } else {
                              print("restart");
                              await saveRecord();
                              _voiceModel.audioPlayer.pause();
                              _voiceModel.setStateImg("btw");
                            }
                          }),
                          _tap("btu", () {
                            changeUrl(1);
                          }),
                          _fast(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          }));
  }

  Widget _listCps() {
    return InkWell(
        child: Container(
          width: 40,
          height: 40,
          child: Image(
            color: _colorModel.dark ? Colors.white : Colors.black,
            image: AssetImage("images/list.png"),
          ),
        ),
        onTap: () {
          showModalBottomSheet(
            context: context,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            builder: (BuildContext context) {
              return Container(
                  child: ListView.builder(
                      scrollDirection: Axis.vertical,
                      itemBuilder: (BuildContext context, int idx) {
                        return ListTile(
                          title: GestureDetector(
                            child: Text(
                                _voiceModel.voiceDetail.chapters[idx].name),
                            onTap: () {
                              changeUrl(idx, flag: false);
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                      itemCount: _voiceModel.voiceDetail.chapters.length));
            },
          );
        });
  }

  Widget _fast() {
    return InkWell(
        child: Container(
          width: 40,
          height: 40,
          child: Image(
            color: _colorModel.dark ? Colors.white : Colors.black,
            image: AssetImage("images/fast.png"),
          ),
        ),
        onTap: () {
          showModalBottomSheet(
              context: context,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              builder: (BuildContext context) {
                return Store.connect<VoiceModel>(
                    builder: (context, VoiceModel model, child) {
                  return Container(
                      child: ListView(
                    padding: const EdgeInsets.all(6.0),
                    children: fasts
                        .map((e) => ListTile(
                              title: Text('X${e.toString()}'),
                              trailing: Radio(
                                value: e,
                                autofocus: true,
                                groupValue: model.fast,
                                onChanged: (v) {
                                  print(v);
                                  model.setFast(v);
                                  model.audioPlayer.setPlaybackRate(
                                      playbackRate: model.fast);
                                },
                              ),
                            ))
                        .toList(),
                  ));
                });
              });
        });
  }
}
