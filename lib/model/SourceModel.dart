import 'package:book/source/db/source_dao.dart';
import 'package:book/source/import/source_importer.dart';
import 'package:book/source/model/book_source.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

class SourceModel with ChangeNotifier {
  final SourceDao _dao = SourceDao.instance;
  List<BookSource> sources = [];
  bool loading = false;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      sources = await _dao.getAll();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<List<BookSource>> enabledSources() => _dao.getEnabled();

  Future<int> enabledCount() async {
    final list = await _dao.getEnabled();
    return list.length;
  }

  Future<void> toggle(BookSource s) async {
    s.enabled = !s.enabled;
    await _dao.setEnabled(s.bookSourceUrl, s.enabled);
    notifyListeners();
  }

  Future<void> remove(BookSource s) async {
    await _dao.delete(s.bookSourceUrl);
    sources.removeWhere((e) => e.bookSourceUrl == s.bookSourceUrl);
    notifyListeners();
  }

  Future<int> importJsonText(String text, {bool agreed = false}) async {
    if (!agreed) {
      throw StateError('请先确认书源使用声明');
    }
    final list = SourceImporter.parseJson(text);
    if (list.isEmpty) {
      BotToast.showText(text: '未解析到有效书源');
      return 0;
    }
    // preserve order
    final base = sources.length;
    for (var i = 0; i < list.length; i++) {
      list[i].customOrder = base + i;
      list[i].lastUpdateTime = DateTime.now().millisecondsSinceEpoch;
    }
    await _dao.upsertAll(list);
    await load();
    BotToast.showText(text: '成功导入 ${list.length} 个书源');
    return list.length;
  }

  Future<int> importFromUrl(String url, {bool agreed = false}) async {
    if (!agreed) {
      throw StateError('请先确认书源使用声明');
    }
    BotToast.showText(text: '正在下载书源…');
    final list = await SourceImporter.fromUrl(url);
    if (list.isEmpty) {
      BotToast.showText(text: '未解析到有效书源');
      return 0;
    }
    final base = sources.length;
    for (var i = 0; i < list.length; i++) {
      list[i].customOrder = base + i;
      list[i].lastUpdateTime = DateTime.now().millisecondsSinceEpoch;
    }
    await _dao.upsertAll(list);
    await load();
    BotToast.showText(text: '成功导入 ${list.length} 个书源');
    return list.length;
  }

  String exportAll() => SourceImporter.exportJson(sources);

  Future<BookSource?> findByUrl(String url) => _dao.getByUrl(url);
}
