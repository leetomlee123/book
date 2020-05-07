import 'dart:convert';

import 'package:book/entity/MRecords.dart';
import 'package:flustars/flustars.dart';

import 'common.dart';

class FunUtil {
  static saveMoviesRecord(var cover, var name, var cid, var cname, var list) {
    List<MRecords> mrds = [];
    if (SpUtil.haveKey(Common.movies_record)) {
      List stringList = jsonDecode(SpUtil.getString(Common.movies_record));

      mrds = stringList.map((f) => MRecords.fromJson(f)).toList();
    }
    MRecords mRecords = MRecords(cover, name, cid, cname, list);
    if (!mrds.contains(mRecords)) {
      mrds.add(mRecords);
    }
    SpUtil.putString(Common.movies_record, jsonEncode(mrds));
  }
}
