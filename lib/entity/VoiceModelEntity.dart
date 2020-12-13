import 'package:book/entity/VoiceDetail.dart';
import 'package:flustars/flustars.dart';

class VoiceModelEntity {
  bool hasEntity=false;
  bool showMenu = false;
  bool getAllTime = false;
  VoiceDetail voiceDetail;

  String link = '';
  String url = '';
  double fast = SpUtil.getDouble("voiceFast", defValue: 1.0);
  double position = 0.1;
  String start = "00:00";
  String end = "00:00";
  double len = 100.0;
  String stateImg = "btw";
  int idx = 0;
}
