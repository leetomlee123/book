import 'package:audioplayers/audioplayers.dart';
import 'package:book/entity/VoiceDetail.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class VoiceModel with ChangeNotifier {
  VoiceDetail voiceDetail;
  AudioPlayer audioPlayer = AudioPlayer();

  String link = '';
  String url = '';
  double fast = SpUtil.getDouble("voiceFast", defValue: 1.0);
  double position = 0.1;
  String start = "00:00";
  String end = "00:00";
  double len = 100000000.0;
  String stateImg = "btw";
  int idx = 0;
  change(int p) {
    position = p.toDouble();
    start = DateUtil.formatDateMs(p, format: "mm:ss");
    notifyListeners();
  }

  setStateImg(var s) {
    stateImg = s;
    notifyListeners();
  }

  setVoiceDetail(v) {
    voiceDetail = v;
    notifyListeners();
  }

  setIdx(int i) {
    idx += i;

    notifyListeners();
  }

  setFast(double f) {
    SpUtil.putDouble("voiceFast", f);
    fast = f;
    notifyListeners();
  }

  setIdx1(int i) {
    idx = i;

    notifyListeners();
  }

  @override
  void dispose() {
    audioPlayer.dispose();

    super.dispose();
  }
}
