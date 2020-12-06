import 'dart:io';

import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:book/common/DbHelper.dart';
import 'package:book/common/Screen.dart';
import 'package:book/common/common.dart';
import 'package:book/common/net.dart';
import 'package:book/entity/VoiceDetail.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/VoiceModel.dart';
import 'package:book/store/Store.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class VoiceDetailView extends StatefulWidget {
  final String link;
  VoiceDetailView(this.link);

  @override
  _VoiceDetailState createState() => _VoiceDetailState();
}

class _VoiceDetailState extends State<VoiceDetailView>
    with WidgetsBindingObserver {
  ColorModel _colorModel;
  VoiceModel _voiceModel;
  double position = 0.1;
  String start = "00:00";
  String end = "00:00";
  VoiceDetail voiceDetail;
  double len = 10000.0;
  double fast = 1.0;
  List<double> fasts = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5];
  String url = '';
  bool getAllTime = false;
  AudioPlayer _audioPlayer = AudioPlayer();
  String stateImg = "video_stop.png";

  AudioCache audioCache = AudioCache();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // var widgetsBinding = WidgetsBinding.instance;
    // widgetsBinding.addPostFrameCallback((callback) async {
    _colorModel = Store.value<ColorModel>(context);
    _voiceModel = Store.value<VoiceModel>(context);
    //   _voiceModel.init(this.widget.link);
    // });
    init();
  }

  saveRecord() async {
    int position = await _audioPlayer.getCurrentPosition();
    DbHelper().saveVoiceRecord(
        this.widget.link,
        _voiceModel.voiceDetail?.cover ?? '',
        _voiceModel.voiceDetail?.title ?? '',
        _voiceModel.voiceDetail?.author ?? '',
        position ?? 0,
        _voiceModel.idx);
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

  init() async {
    Response resp = await Util(null)
        .http()
        .get(Common.voiceDetail + "?key=${this.widget.link}");
    var data = resp.data;
    _voiceModel.voiceDetail = VoiceDetail.fromJson(data);
    voiceDetail = _voiceModel.voiceDetail;

    if (mounted) {
      setState(() {});
    }
    Map<String, int> x = await DbHelper().getVoiceRecord(this.widget.link);

    if (x['idx'] > 0) {
      _voiceModel.setIdx1(x['idx']);
    } else {
      _voiceModel.setIdx1(0);
    }
    Response resp1 = await Util(null).http().get(
        Common.voiceUrl + "?url=${voiceDetail.chapters[_voiceModel.idx].link}");

    url = resp1.data['url'];
    int p = 0;
    if (x['idx'] >= 0) {
      p = x['position'];
    }
    initAudio(p);
  }

  initAudio(int p) async {
    if (kIsWeb) {
      return;
    }
    if (Platform.isIOS) {
      if (audioCache.fixedPlayer != null) {
        audioCache.fixedPlayer.startHeadlessService();
      }
      _audioPlayer.startHeadlessService();
    }
    int result = await _audioPlayer.play(
      url,
      position: Duration(milliseconds: p),
    );
    _audioPlayer.setPlaybackRate(playbackRate: _voiceModel.fast);
    if (result == 1) {
      print("success");
    }

    if (mounted) {
      setState(() {});
    }
    _audioPlayer.onDurationChanged.listen((Duration d) {
      if (!getAllTime) {
        setState(() {
          len = d.inSeconds.toDouble();
          print(len);
          end = DateUtil.formatDateMs(d.inMilliseconds, format: "mm:ss");
          getAllTime = true;
        });
      }
    });

    _audioPlayer.onAudioPositionChanged.listen((Duration p) {
      var a = p.inSeconds.toDouble();
      var b = DateUtil.formatDateMs(p.inMilliseconds, format: "mm:ss");
      _voiceModel.change(b, a);
    });
    _audioPlayer.onPlayerCompletion.listen((event) {
      changeUrl(1, true);
    });
  }

  @override
  void dispose() {
    voiceDetail = null;
    saveRecord();
    _audioPlayer.dispose();
    super.dispose();
  }

  changeUrl(int idx, bool flag) async {
    if (flag) {
      if (_voiceModel.idx + idx < 0) {
        BotToast.showText(text: "已经是第一节");
        return;
      }
      if (_voiceModel.idx + idx >= voiceDetail.chapters.length) {
        BotToast.showText(text: "已经是最后一节");
        return;
      }
      _voiceModel.setIdx(idx);
    } else {
      _voiceModel.setIdx1(idx);
    }
    var ux = voiceDetail.chapters[_voiceModel.idx].link;

    Response resp1 = await Util(null).http().get(Common.voiceUrl + "?url=$ux");

    url = resp1.data['url'];
    initAudio(0);
  }

  Widget _tap(img, func) {
    return IconButton(
      color: _colorModel.dark ? Colors.white : Colors.black,
      icon: ImageIcon(
        AssetImage("images/$img"),
        size: 60.0,
        color: _colorModel.dark ? Colors.white : Colors.black,
      ),
      onPressed: func,
    );
  }

  @override
  Widget build(BuildContext context) {
    return voiceDetail == null
        ? Scaffold()
        : Scaffold(
            body: ListView(
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
                      voiceDetail.cover.isEmpty
                          ? Container(
                              width: 280,
                              height: 280,
                              decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(150),
                                  // 圆形图片
                                  image: DecorationImage(
                                      image: AssetImage("images/bg.png"),
                                      fit: BoxFit.cover)),
                            )
                          : Container(
                              width: 280,
                              height: 280,
                              decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(150),
                                  // 圆形图片
                                  image: DecorationImage(
                                      image: CachedNetworkImageProvider(
                                          voiceDetail.cover),
                                      fit: BoxFit.cover)),
                            )
                    ],
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Store.connect<VoiceModel>(
                      builder: (context, VoiceModel model, child) {
                    return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              Text(
                                voiceDetail?.title ?? '',
                                style: TextStyle(
                                    color: _colorModel.dark
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 25),
                              ),
                              Text(
                                voiceDetail?.author ?? '',
                                style: TextStyle(
                                    color: _colorModel.dark
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 14),
                              ),
                              Text(
                                voiceDetail?.chapters[model.idx].name ?? '',
                                style: TextStyle(
                                    color: _colorModel.dark
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 14),
                              ),
                            ],
                          )
                        ]);
                  }),
                  SizedBox(
                    height: 40,
                  ),
                  Store.connect<VoiceModel>(
                      builder: (context, VoiceModel model, child) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(model.start),
                          Expanded(
                            child: Slider(
                              value: model.position,
                              max: len,
                              // min: 0.0,
                              onChanged: (v) {
                                _audioPlayer.seek(Duration(seconds: v.toInt()));
                              },
                              activeColor: Colors.white,
                            ),
                          ),
                          Text(end),
                        ],
                      ),
                    );
                  }),
                  SizedBox(
                    height: 20,
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _listCps(),
                        _tap("audio_prev.png", () {
                          changeUrl(-1, true);
                        }),
                        _tap(stateImg, () {
                          if (_audioPlayer.state == AudioPlayerState.PLAYING) {
                            _audioPlayer.pause();
                            stateImg = "video_play.png";
                          } else if (_audioPlayer.state ==
                              AudioPlayerState.PAUSED) {
                            _audioPlayer.resume();
                            stateImg = "video_stop.png";
                          }
                          setState(() {});
                        }),
                        _tap("audio_next.png", () {
                          changeUrl(1, true);
                        }),
                        _fast(),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ));
  }

  Widget _listCps() {
    return IconButton(
        color: _colorModel.dark ? Colors.white : Colors.black,
        icon: ImageIcon(
          AssetImage("images/list.png"),
          size: 32.0,
          color: _colorModel.dark ? Colors.white : Colors.black,
        ),
        onPressed: () {
          showModalBottomSheet<void>(
              context: context,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              builder: (BuildContext context) {
                return Container(
                    child: ListView.separated(
                        //排列方向 垂直和水平
                        scrollDirection: Axis.vertical,
                        //分割线构建器
                        separatorBuilder: (BuildContext context, int index) {
                          return Divider(height: 1, color: Colors.black);
                        },
                        itemBuilder: (BuildContext context, int position) {
                          return ListTile(
                            title: GestureDetector(
                              child: Text(voiceDetail.chapters[position].name),
                              onTap: () {
                                changeUrl(position, false);
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                        itemCount: voiceDetail.chapters.length)

                    // ListView(
                    //   padding: const EdgeInsets.all(4.0),
                    //   children: voiceDetail.chapters
                    //       .map((e) => ListTile(
                    //             title: Text(e.name),
                    //           ))
                    //       .toList(),
                    // ),
                    );
              });
        });
  }

  Widget _fast() {
    return IconButton(
        color: _colorModel.dark ? Colors.white : Colors.black,
        icon: ImageIcon(
          AssetImage("images/fast.png"),
          size: 32.0,
          color: _colorModel.dark ? Colors.white : Colors.black,
        ),
        onPressed: () {
          showModalBottomSheet<void>(
              context: context,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              builder: (BuildContext context) {
                return Container(
                  child: Store.connect<VoiceModel>(
                      builder: (context, VoiceModel model, child) {
                    return ListView(
                      padding: const EdgeInsets.all(4.0),
                      children: fasts
                          .map((e) => ListTile(
                                title: Text('X${e.toString()}'),
                                trailing: Radio(
                                  value: e,
                                  groupValue: model.fast,
                                  onChanged: (v) {
                                    model.setFast(e);
                                    _audioPlayer.setPlaybackRate(
                                        playbackRate: model.fast);
                                  },
                                ),
                              ))
                          .toList(),
                    );
                  }),
                );
              });
        });
  }
}
