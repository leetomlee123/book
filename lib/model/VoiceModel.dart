import 'package:audioplayers/audioplayers.dart';
import 'package:book/common/DbHelper.dart';
import 'package:book/common/common.dart';
import 'package:book/common/net.dart';
import 'package:book/entity/VoiceDetail.dart';
import 'package:book/entity/VoiceModelEntity.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class VoiceModel with ChangeNotifier, VoiceModelEntity {
  AudioPlayer audioPlayer = AudioPlayer();

  init() async {
    Response resp =
        await Util(null).http().get(Common.voiceDetail + "?key=$link");
    var data = resp.data;
    voiceDetail = VoiceDetail.fromJson(data);

    Map<String, int> x = await DbHelper().getVoiceRecord(link, idx);

    if (audioPlayer.state == AudioPlayerState.PLAYING) {
      await saveRecord();
      audioPlayer.release();
    }

    setFast(SpUtil.getDouble("voice_fast") ?? 1.0);

    setIdx1(x['idx'] == -1 ? 0 : x['idx']);

    Response resp1 = await Util(null)
        .http()
        .get(Common.voiceUrl + "?url=${voiceDetail.chapters[idx].link}");

    url = resp1.data['url'];
    int p = 0;
    if (idx >= 0) {
      p = x['position'];
      position = p.toDouble();
    }

    await initAudio(p);
    notifyListeners();
  }

  changeUrl(int ix, {bool flag = true}) async {
    if (flag) {
      if (idx + ix < 0) {
        BotToast.showText(text: "已经是第一节");
        return;
      }
      if (idx + ix >= voiceDetail.chapters.length) {
        BotToast.showText(text: "已经是最后一节");
        return;
      }
      audioPlayer.release();

      setIdx(ix);
    } else {
      await saveRecord();
      audioPlayer.release();

      setIdx1(ix);
    }

    var ux = voiceDetail.chapters[idx].link;

    Response resp1 = await Util(null).http().get(Common.voiceUrl + "?url=$ux");

    url = resp1.data['url'];
    initAudio(0);
  }

  initAudio(int p) async {
    if (kIsWeb) {
      return;
    }

    int result = await audioPlayer.play(url,
        position: Duration(milliseconds: p), stayAwake: true);
    audioPlayer.setPlaybackRate(playbackRate: fast);
    if (result == 1) {
      print("success");

      link = link;
      stateImg = 'btv';
    }
    // controller.forward();

    audioPlayer.onDurationChanged.listen((Duration d) {
      if (!getAllTime) {
        len = d.inMilliseconds.toDouble();
        end = DateUtil.formatDateMs(d.inMilliseconds, format: "mm:ss");
        getAllTime = true;
      }
    });

    audioPlayer.onAudioPositionChanged.listen((Duration p) {
      change(p.inMilliseconds);
    });
    audioPlayer.onPlayerCompletion.listen((event) {
      // controller.dispose();
      // controller.didUnregisterListener();
      changeUrl(1);
    });
  }

  change(int p) {
    position = p.toDouble();
    start = DateUtil.formatDateMs(p, format: "mm:ss");
    notifyListeners();
  }

  toggleState() async {
    if (stateImg == "btw") {
      audioPlayer.resume();
      setStateImg("btv");
      print("stop");
    } else {
      print("restart");
      await saveRecord();
      audioPlayer.pause();
      setStateImg("btw");
    }
  }

  saveRecord() async {
    int position = await audioPlayer?.getCurrentPosition() ?? 0;
    print(
        "save ${voiceDetail?.title} position is $position key is ${link} idx is ${idx}");
    DbHelper().saveVoiceRecord(
        link,
        voiceDetail?.cover ?? '',
        voiceDetail?.title ?? '',
        voiceDetail?.author ?? '',
        position.toInt() ?? 0,
        idx,
        voiceDetail.chapters[idx].name);
    // DbHelper().voices();
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
