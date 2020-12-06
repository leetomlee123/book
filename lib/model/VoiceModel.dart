import 'package:book/entity/VoiceDetail.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class VoiceModel with ChangeNotifier {
  VoiceDetail voiceDetail;
  double fast = 1.0;
  double position = 0.1;
  String start = "00:00";
  int idx = 0;
  change(String s, double p) {
    position = p;
    start = s;
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

  @override
  void dispose() {
    super.dispose();
  }
}
