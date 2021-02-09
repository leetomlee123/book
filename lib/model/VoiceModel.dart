import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:book/common/DbHelper.dart';
import 'package:book/common/common.dart';
import 'package:book/common/Http.dart';
import 'package:book/entity/VoiceDetail.dart';
import 'package:book/entity/VoiceIdx.dart';
import 'package:book/entity/VoiceModelEntity.dart';
import 'package:book/entity/VoiceMore.dart';
import 'package:book/event/event.dart';
import 'package:book/service/CustomCacheManager.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class VoiceModel with ChangeNotifier {
  String modelJsonKey = "Voice_History";
  bool hasEntity = false;
  bool isVoiceIdx = true;
  List<VoiceMore> voiceMores = [];
  bool showMenu = false;
  bool getAllTime = false;
  VoiceDetail voiceDetail;
  double fast = 1.0;
  List<VoiceIdx> voiceIdxs = [];
  String link = '';
  String url = '';
  double position = 0.1;
  String start = "00:00";
  String end = "00:00";
  double len = 10000000000.0;
  String stateImg = "btw";
  int idx = 0;
  AudioPlayer audioPlayer;
  int loading = 0;
  bool loadNext = true;

  setIsVoiceIdx(bool x) {
    isVoiceIdx = x;
    notifyListeners();
  }

  showMenuFun(bool v) {
    showMenu = v;
    notifyListeners();
  }

  VoiceModel() {
    audioPlayer = AudioPlayer();

    if (SpUtil.haveKey(modelJsonKey)) {
      hasEntity = true;
      SpUtil.getObj(modelJsonKey, (v) {
        VoiceModelEntity voiceModelEntity = VoiceModelEntity.fromJson(v);
        voiceDetail = VoiceDetail("", "", null, "", voiceModelEntity.cover);
        idx = voiceModelEntity.idx;
        link = voiceModelEntity.link;
        fast = voiceModelEntity.fast;
      });
    }
  }

  init() async {
    Response resp =
        await HttpUtil().http().get(Common.voiceDetail + "?key=$link");
    var data = resp.data;
    voiceDetail = VoiceDetail.fromJson(data);

    Map<String, int> x = await DbHelper().getVoiceRecord(link, idx);

    if (audioPlayer.state == AudioPlayerState.PLAYING) {
      await saveRecord();
      audioPlayer.release();
    }

    setIdx1(x['idx'] == -1 ? 0 : x['idx']);
    String ux = voiceDetail.chapters[idx].link;
    String key = ux + idx.toString();
    var fileFromCache =
        await CustomCacheManager.instanceVoice.getFileFromCache(key);
    var t;
    if (fileFromCache == null) {
      Response resp1 =
          await HttpUtil().http().get(Common.voiceUrl + "?url=$ux");
      url = resp1.data['url'];
      t = url;
    }

    int p = 0;
    if (idx >= 0) {
      p = x['position'];
      position = p.toDouble();
    }

    await initAudio(p, t);
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
//计算赋值
      idx = idx + ix;
      // setIdx(ix);
    } else {
      await saveRecord();
      audioPlayer.release();
//全量赋值
      if (ix < 0 || ix >= voiceDetail.chapters.length) {
        return;
      }
      idx = ix;
      // setIdx1(ix);
    }

    var ux = voiceDetail.chapters[idx].link;
    String key = ux + idx.toString();
    print("load key $key");
    var fileFromCache =
        await CustomCacheManager.instanceVoice.getFileFromCache(key);
    var t;
    if (fileFromCache == null) {
      print("没有缓存");
      Response resp1 =
          await HttpUtil().http().get(Common.voiceUrl + "?url=$ux");
      url = resp1.data['url'];
      t = url;
    }

    await initAudio(0, t);

    notifyListeners();
  }

  initAudio(int p, String u) async {
    loadNext = true;
    if (kIsWeb) {
      return -1;
    }

    String key = voiceDetail.chapters[idx].link + idx.toString();
    int result = 0;
    loading = 1;
    notifyListeners();
    File file;
    try {
      if (u == null) {
        var fileInfo =
            await CustomCacheManager.instanceVoice.getFileFromCache(key);
        file = fileInfo.file;
      } else {
        file =
            await CustomCacheManager.instanceVoice.getSingleFile(u, key: key);
      }
      if (audioPlayer.state == AudioPlayerState.PLAYING) {
        return;
      }
    } catch (e) {
      loading = 0;
      notifyListeners();
    }

    result = await audioPlayer.play(file.path,
        position: Duration(milliseconds: p), stayAwake: true, isLocal: true);
    audioPlayer.setPlaybackRate(playbackRate: fast);
    loading = 0;

    if (result == 1) {
      print("success");
      // eventBus.fire(RollEvent("1"));
      link = link;
      stateImg = 'btv';

      // controller.forward();

      audioPlayer.onDurationChanged.listen((Duration d) {
        if (!getAllTime) {
          len = d.inMilliseconds.toDouble();
          end = DateUtil.formatDateMs(d.inMilliseconds,
              format: DateFormats.h_m_s, isUtc: true);
          getAllTime = true;
        }
      });

      audioPlayer.onAudioPositionChanged.listen((Duration p) {
        change(p.inMilliseconds);
      });

      audioPlayer.onPlayerCompletion.listen((event) {
        // print("next***********************");
        changeUrl(1);
      });
      return 1;
    } else {
      return -1;
    }
  }

  loadVolume(int temp) async {
    print(" start load  ");
    try {
      var ux = voiceDetail.chapters[temp].link;
      String key = ux + temp.toString();
      var fileFromCache =
          await CustomCacheManager.instanceVoice.getFileFromCache(key);
      if (fileFromCache != null) {
        return;
      }

      Response resp1 =
          await HttpUtil().http().get(Common.voiceUrl + "?url=$ux");

      await CustomCacheManager.instanceVoice
          .getSingleFile(resp1.data['url'], key: key);
      print("pre cache $key");
    } on Exception {
      loadNext = true;
    }

    print(" end load  ");
  }

  change(int p) async {
    if (loadNext && (p > ((len / 4) * 3))) {
      loadNext = false;
      await loadVolume(idx + 1);
    }
    position = p.toDouble();
    start = DateUtil.formatDateMs(p, format: DateFormats.h_m_s, isUtc: true);
    notifyListeners();
  }

  toggleState() async {
    if (stateImg == "btw") {
      saveRecord();
      if (url == "" || (voiceDetail?.chapters?.isEmpty ?? true)) {
        await init();
      } else {
        audioPlayer.resume();
        print("restart");
        eventBus.fire(RollEvent("1"));
        setStateImg("btv");
      }
    } else {
      print("stop");

      await saveRecord();
      audioPlayer.pause();
      eventBus.fire(RollEvent("0"));
      setStateImg("btw");
    }
  }

  saveRecord() async {
    if (url.isNotEmpty) {
      print("***************" + url);
      int position = 0;
      try {
        position = await audioPlayer?.getCurrentPosition() ?? 0;
      } catch (e) {}

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
    }
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
    fast = f;
    notifyListeners();
  }

  setIdx1(int i) {
    idx = i;

    notifyListeners();
  }

  getSearch(var k) async {
    voiceMores = [];
    Response resp = await HttpUtil().http().get(Common.voiceSearch + "?key=$k");
    List data = resp.data;
    for (var d in data) {
      voiceMores.add(VoiceMore.fromJson(d));
    }
    isVoiceIdx = false;
    notifyListeners();
  }

  getData() async {
    String k = "voice_idx";
    if (SpUtil.haveKey(k)) {
      List json = SpUtil.getObjectList(k);
      for (var d in json) {
        voiceIdxs.add(VoiceIdx.fromJson(d));
      }
    }
    Response resp = await HttpUtil().http().get(Common.voiceIndex);
    List data = resp.data;
    for (var d in data) {
      voiceIdxs.add(VoiceIdx.fromJson(d));
    }
    notifyListeners();

    SpUtil.putObjectList(k, data);
  }

  @override
  void dispose() {
    print("dispose");
    audioPlayer.release();

    super.dispose();
  }

  saveHis() async {
    await saveRecord();
    if (url.isNotEmpty) {
      SpUtil.putObject(modelJsonKey,
          VoiceModelEntity(voiceDetail?.cover ?? '', link, idx, fast).toJson());
    }
  }
}
