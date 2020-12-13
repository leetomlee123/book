import 'package:audioplayers/audioplayers.dart';
import 'package:book/common/Screen.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/VoiceModel.dart';
import 'package:book/store/Store.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  VoiceModel _voiceModel;
  List<double> fasts = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _colorModel = Store.value<ColorModel>(context);
    _voiceModel = Store.value<VoiceModel>(context);

    if (_voiceModel.voiceDetail == null &&
        (_voiceModel.audioPlayer.state == AudioPlayerState.PLAYING)) {
      _voiceModel.audioPlayer.release();
    }
    if (_voiceModel.audioPlayer.state == AudioPlayerState.PLAYING) {
      if (this.widget.link != _voiceModel.link) {
        _voiceModel.link = widget.link;

        _voiceModel.init();
      }
    } else {
      _voiceModel.link = widget.link;
      _voiceModel.init();
    }
    _voiceModel.hasEntity = true;
  }

//旋转
  Widget buildRotationTransition() {
    return Center(
        child: Container(
      width: 160,
      height: 220,
      decoration: BoxDecoration(
          image: DecorationImage(
              image: _voiceModel.voiceDetail.cover.isEmpty
                  ? AssetImage("images/nocover.jpg")
                  : CachedNetworkImageProvider(_voiceModel.voiceDetail.cover),
              fit: BoxFit.cover)),
    ));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    _voiceModel.saveRecord();

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
    _voiceModel.saveRecord();
    // }
    // _audioPlayer.dispose();
    // _voiceModel.audioPlayer.dispose();
    // controller.dispose();
    super.dispose();
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
                            _voiceModel.changeUrl(-1);
                          }),
                          _tap(_voiceModel.stateImg, () async {
                            _voiceModel.toggleState();
                          }),
                          _tap("btu", () {
                            _voiceModel.changeUrl(1);
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
                              _voiceModel.changeUrl(idx, flag: false);
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
