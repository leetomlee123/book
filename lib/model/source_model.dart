import 'package:book/data/repositories/source_repository.dart';
import 'package:book/source/import/source_importer.dart';
import 'package:book/source/model/book_source.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

class SourceModel with ChangeNotifier {
  final SourceRepository _sources = SourceRepository.instance;
  List<BookSource> sources = [];
  bool loading = false;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      sources = await _sources.getAll();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<List<BookSource>> enabledSources() => _sources.getEnabled();

  Future<int> enabledCount() async {
    final list = await _sources.getEnabled();
    return list.length;
  }

  Future<void> toggle(BookSource source) async {
    source.enabled = !source.enabled;
    await _sources.setEnabled(source.bookSourceUrl, source.enabled);
    notifyListeners();
  }

  Future<void> remove(BookSource source) async {
    await _sources.delete(source.bookSourceUrl);
    sources.removeWhere((e) => e.bookSourceUrl == source.bookSourceUrl);
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
    await _sources.upsertAll(list);
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
    await _sources.upsertAll(list);
    await load();
    BotToast.showText(text: '成功导入 ${list.length} 个书源');
    return list.length;
  }

  String exportAll() => SourceImporter.exportJson(sources);

  Future<BookSource?> findByUrl(String url) => _sources.getByUrl(url);
}
