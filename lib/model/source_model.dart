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

  Future<void> enableMany(List<String> urls) async {
    if (urls.isEmpty) return;
    await _sources.setEnabledMany(urls, true);
    final set = urls.toSet();
    for (final s in sources) {
      if (set.contains(s.bookSourceUrl)) s.enabled = true;
    }
    notifyListeners();
  }

  Future<void> disableMany(List<String> urls) async {
    if (urls.isEmpty) return;
    await _sources.setEnabledMany(urls, false);
    final set = urls.toSet();
    for (final s in sources) {
      if (set.contains(s.bookSourceUrl)) s.enabled = false;
    }
    notifyListeners();
  }

  Future<void> removeMany(List<String> urls) async {
    if (urls.isEmpty) return;
    await _sources.deleteMany(urls);
    final set = urls.toSet();
    sources.removeWhere((e) => set.contains(e.bookSourceUrl));
    notifyListeners();
  }

  String _importToast(
    SourceUpsertStats stats, {
    int skipped = 0,
    int duplicatesInBatch = 0,
  }) {
    final parts = <String>[
      '成功导入 ${stats.total} 个书源（新增 ${stats.inserted}，更新 ${stats.updated}）',
    ];
    if (duplicatesInBatch > 0) {
      parts.add('合并重复 $duplicatesInBatch');
    }
    if (skipped > 0) {
      parts.add('跳过 $skipped');
    }
    return parts.join('，');
  }

  Future<int> importJsonText(String text, {bool agreed = false}) async {
    if (!agreed) {
      throw StateError('请先确认书源使用声明');
    }
    final parsed = SourceImporter.parseJson(text);
    if (parsed.sources.isEmpty) {
      BotToast.showText(text: '未解析到有效书源');
      return 0;
    }
    final base = sources.length;
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < parsed.sources.length; i++) {
      parsed.sources[i].customOrder = base + i;
      parsed.sources[i].lastUpdateTime = now;
    }
    final stats = await _sources.upsertAllWithStats(parsed.sources);
    await load();
    BotToast.showText(
      text: _importToast(
        stats,
        skipped: parsed.skipped,
        duplicatesInBatch: parsed.duplicatesInBatch,
      ),
    );
    return stats.total;
  }

  Future<int> importFromUrl(String url, {bool agreed = false}) async {
    if (!agreed) {
      throw StateError('请先确认书源使用声明');
    }
    BotToast.showText(text: '正在下载书源…');
    final parsed = await SourceImporter.fromUrl(url);
    if (parsed.sources.isEmpty) {
      BotToast.showText(text: '未解析到有效书源');
      return 0;
    }
    final base = sources.length;
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < parsed.sources.length; i++) {
      parsed.sources[i].customOrder = base + i;
      parsed.sources[i].lastUpdateTime = now;
    }
    final stats = await _sources.upsertAllWithStats(parsed.sources);
    await load();
    BotToast.showText(
      text: _importToast(
        stats,
        skipped: parsed.skipped,
        duplicatesInBatch: parsed.duplicatesInBatch,
      ),
    );
    return stats.total;
  }

  String exportAll() => SourceImporter.exportJson(sources);

  Future<BookSource?> findByUrl(String url) => _sources.getByUrl(url);
}
