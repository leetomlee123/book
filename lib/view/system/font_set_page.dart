import 'dart:io';

import 'package:book/common/app_colors.dart';
import 'package:book/common/font_catalog.dart';
import 'package:book/common/local_store.dart';
import 'package:book/model/color_model.dart';
import 'package:book/service/custom_cache_manager.dart';
import 'package:book/store/providers.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:book/common/common.dart';

/// Reader font picker: built-in CDN fonts + local TTF/OTF import.
/// WeChat Reading–style layout (preview card + section lists).
class FontSet extends ConsumerStatefulWidget {
  const FontSet({super.key});

  @override
  ConsumerState<FontSet> createState() => _FontSetState();
}

class _FontSetState extends ConsumerState<FontSet> {
  final List<_FontRow> _rows = [];
  bool _loading = true;
  bool _downloading = false;
  String? _downloadingKey;
  double _downloadProgress = 0;
  bool _importing = false;

  bool get _dark => SpUtil.getBool(PrefsKeys.dark);
  Color get _scaffold => _dark ? AppColors.scaffoldDark : AppColors.scaffold;
  Color get _surface => _dark ? AppColors.surfaceDark : AppColors.surface;
  Color get _primary => _dark ? AppColors.textOnDark : AppColors.textPrimary;
  Color get _secondary => AppColors.textSecondary;
  Color get _divider => _dark ? AppColors.dividerDark : AppColors.divider;
  Color get _previewPaper =>
      _dark ? AppColors.paperNight : AppColors.paperCream;
  Color get _previewInk =>
      _dark ? AppColors.inkOnNight : AppColors.inkOnLight;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    final colorModel = ref.read(colorModelProvider);
    colorModel.reloadFontMap();
    final fonts = colorModel.fonts();
    final next = <_FontRow>[];
    for (final e in fonts.entries) {
      final key = e.key.toString();
      final isLocal = key.startsWith(FontCatalog.localPrefix);
      final url = isLocal ? '' : FontCatalog.downloadUrl(key);
      final ready = await FontCatalog.isReady(key);
      next.add(_FontRow(
        key: key,
        urlOrPath: isLocal ? (e.value?.toString() ?? '') : url,
        ready: ready,
      ));
    }
    next.sort((a, b) {
      int rank(_FontRow r) {
        if (r.key == 'Roboto') return 0;
        if (r.key.startsWith(FontCatalog.localPrefix)) return 2;
        return 1;
      }

      final c = rank(a).compareTo(rank(b));
      if (c != 0) return c;
      return FontCatalog.displayName(a.key)
          .compareTo(FontCatalog.displayName(b.key));
    });
    if (!mounted) return;
    setState(() {
      _rows
        ..clear()
        ..addAll(next);
      _loading = false;
    });
  }

  List<_FontRow> get _systemRows =>
      _rows.where((r) => r.key == 'Roboto').toList();

  List<_FontRow> get _onlineRows => _rows
      .where((r) =>
          r.key != 'Roboto' && !r.key.startsWith(FontCatalog.localPrefix))
      .toList();

  List<_FontRow> get _localRows =>
      _rows.where((r) => r.key.startsWith(FontCatalog.localPrefix)).toList();

  Future<void> _applyFont(String key) async {
    final colorModel = ref.read(colorModelProvider);
    final readModel = ref.read(readModelProvider);
    final ok = await colorModel.setFontFamily(key);
    if (!ok) {
      BotToast.showText(text: '字体加载失败，请重新下载或导入');
      return;
    }
    await readModel.relayoutPages();
    if (mounted) setState(() {});
  }

  Future<void> _downloadAndUse(_FontRow row) async {
    final url = row.urlOrPath.isNotEmpty
        ? row.urlOrPath
        : FontCatalog.downloadUrl(row.key);
    if (url.isEmpty) {
      BotToast.showText(text: '无可用下载地址');
      return;
    }
    if (mounted) {
      setState(() {
        _downloading = true;
        _downloadingKey = row.key;
        _downloadProgress = 0;
      });
    }
    try {
      final stream = CustomCacheManager.instanceFont.getFileStream(
        url,
        key: row.key,
        withProgress: true,
      );
      await for (final event in stream) {
        if (event is DownloadProgress) {
          final v = NumUtil.getNumByValueDouble(event.progress, 2)?.toDouble() ??
              0.0;
          if (mounted) setState(() => _downloadProgress = v.clamp(0.0, 1.0));
        } else if (event is FileInfo) {
          await FontCatalog.persistDownloaded(row.key, event.file);
          final i = _rows.indexWhere((e) => e.key == row.key);
          if (mounted && i >= 0) {
            setState(() {
              _rows[i] = row.copyWith(ready: true);
              _downloading = false;
              _downloadingKey = null;
              _downloadProgress = 1;
            });
          }
          await _applyFont(row.key);
          return;
        }
      }
      final path = await FontCatalog.resolvePath(row.key);
      if (path.isEmpty) {
        BotToast.showText(text: '下载未完成，请重试');
        return;
      }
      final i = _rows.indexWhere((e) => e.key == row.key);
      if (mounted && i >= 0) {
        setState(() => _rows[i] = row.copyWith(ready: true));
      }
      await _applyFont(row.key);
    } catch (e) {
      BotToast.showText(text: '下载失败：$e');
    } finally {
      if (mounted) {
        setState(() {
          _downloading = false;
          _downloadingKey = null;
        });
      }
    }
  }

  Future<void> _onTapRow(_FontRow row) async {
    if (_downloading) return;
    if (row.key == 'Roboto') {
      await _applyFont('Roboto');
      return;
    }
    if (row.key.startsWith(FontCatalog.localPrefix)) {
      if (!row.ready) {
        BotToast.showText(text: '本地字体文件不存在');
        return;
      }
      await _applyFont(row.key);
      return;
    }
    final ready = row.ready || await FontCatalog.isReady(row.key);
    if (!ready) {
      await _downloadAndUse(row);
    } else {
      final i = _rows.indexWhere((e) => e.key == row.key);
      if (!row.ready && mounted && i >= 0) {
        setState(() => _rows[i] = row.copyWith(ready: true));
      }
      await _applyFont(row.key);
    }
  }

  Future<void> _importLocal() async {
    if (_importing || _downloading) return;
    setState(() => _importing = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['ttf', 'otf', 'ttc', 'otc'],
        withData: false,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final picked = result.files.single;
      final path = picked.path;
      if (path == null || path.isEmpty) {
        BotToast.showText(text: '无法读取所选文件');
        return;
      }
      final src = File(path);
      if (!await src.exists()) {
        BotToast.showText(text: '文件不存在');
        return;
      }
      final ext = p.extension(path).toLowerCase();
      if (!const {'.ttf', '.otf', '.ttc', '.otc'}.contains(ext)) {
        BotToast.showText(text: '仅支持 ttf / otf 字体文件');
        return;
      }
      final key = await FontCatalog.importLocalFile(
        src,
        name: p.basenameWithoutExtension(path),
      );
      ref.read(colorModelProvider).reloadFontMap();
      await _applyFont(key);
      await _reload();
      BotToast.showText(text: '已导入 ${FontCatalog.displayName(key)}');
    } catch (e) {
      BotToast.showText(text: '导入失败：$e');
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _deleteLocal(_FontRow row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        title: Text('删除字体', style: TextStyle(color: _primary)),
        content: Text(
          '确定删除「${FontCatalog.displayName(row.key)}」？',
          style: TextStyle(color: _secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('取消', style: TextStyle(color: _secondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final colorModel = ref.read(colorModelProvider);
    final wasCurrent = colorModel.font == row.key;
    await FontCatalog.removeLocal(row.key);
    colorModel.reloadFontMap();
    if (wasCurrent) await _applyFont('Roboto');
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final colorModel = ref.watch(colorModelProvider);
    final currentName = FontCatalog.displayName(
      colorModel.font.isEmpty ? 'Roboto' : colorModel.font,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _scaffold,
        appBar: AppBar(
          backgroundColor: _scaffold,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: _primary),
          title: Text(
            '字体',
            style: TextStyle(
              color: _primary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: (_importing || _downloading) ? null : _importLocal,
              child: _importing
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.brand,
                      ),
                    )
                  : Text(
                      '导入',
                      style: TextStyle(
                        color: AppColors.brand,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.brand),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                children: [
                  _previewCard(colorModel, currentName),
                  const SizedBox(height: 20),
                  if (_systemRows.isNotEmpty) ...[
                    _sectionHeader('系统'),
                    const SizedBox(height: 8),
                    _sectionCard(
                      _systemRows
                          .map((r) => _fontTile(r, colorModel))
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (_onlineRows.isNotEmpty) ...[
                    _sectionHeader('在线字体'),
                    const SizedBox(height: 8),
                    _sectionCard(
                      _onlineRows
                          .map((r) => _fontTile(r, colorModel))
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                  ],
                  _sectionHeader('本地字体'),
                  const SizedBox(height: 8),
                  if (_localRows.isEmpty)
                    _emptyLocalCard()
                  else
                    _sectionCard(
                      _localRows
                          .map((r) => _fontTile(r, colorModel, canDelete: true))
                          .toList(),
                    ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      '支持 ttf / otf · 本地字体可长按删除',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Preview
  // ---------------------------------------------------------------------------

  Widget _previewCard(ColorModel colorModel, String currentName) {
    final family = colorModel.font == 'Roboto' || colorModel.font.isEmpty
        ? null
        : colorModel.font;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: _previewPaper,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        boxShadow: AppShadows.softBar,
      ),
      child: Column(
        children: [
          Text(
            '问刘十九',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: family,
              fontWeight: FontWeight.w400,
              fontSize: 20,
              height: 1.5,
              color: _previewInk,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '绿蚁新醅酒，红泥小火炉。\n晚来天欲雪，能饮一杯无？',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: family,
              fontWeight: FontWeight.w400,
              fontSize: 16,
              height: 1.85,
              color: _previewInk.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _dark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '当前 · $currentName',
              style: TextStyle(
                fontSize: 12,
                color: _secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sections
  // ---------------------------------------------------------------------------

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: _secondary,
        ),
      ),
    );
  }

  Widget _sectionCard(List<Widget> children) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i != children.length - 1) {
        items.add(Divider(
          height: 1,
          thickness: 0.5,
          indent: 16,
          endIndent: 16,
          color: _divider,
        ));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: items),
    );
  }

  Widget _emptyLocalCard() {
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        onTap: (_importing || _downloading) ? null : _importLocal,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          child: Column(
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 28,
                color: AppColors.brand,
              ),
              const SizedBox(height: 10),
              Text(
                '从文件导入字体',
                style: TextStyle(
                  fontSize: 15,
                  color: _primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '支持 ttf / otf',
                style: TextStyle(fontSize: 12, color: _secondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tile
  // ---------------------------------------------------------------------------

  Widget _fontTile(
    _FontRow row,
    ColorModel colorModel, {
    bool canDelete = false,
  }) {
    final selected = colorModel.font == row.key;
    final isLocal = row.key.startsWith(FontCatalog.localPrefix);
    final downloading = _downloading && _downloadingKey == row.key;
    final family = selected &&
            row.key != 'Roboto' &&
            colorModel.isFontLoaded(row.key)
        ? row.key
        : null;

    String statusLabel;
    if (row.key == 'Roboto') {
      statusLabel = '系统';
    } else if (isLocal) {
      statusLabel = '本地';
    } else if (row.ready) {
      statusLabel = '已下载';
    } else {
      statusLabel = '未下载';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: downloading ? null : () => _onTapRow(row),
        onLongPress: canDelete ? () => _deleteLocal(row) : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      FontCatalog.displayName(row.key),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: family,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: selected ? AppColors.brand : _primary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (downloading)
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: _downloadProgress > 0
                                    ? _downloadProgress
                                    : null,
                                minHeight: 3,
                                backgroundColor: _divider,
                                color: AppColors.brand,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${(_downloadProgress.clamp(0.0, 1.0) * 100).toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: _secondary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        statusLabel,
                        style: TextStyle(fontSize: 12, color: _secondary),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (selected)
                const Icon(Icons.check_circle, size: 20, color: AppColors.brand)
              else if (!downloading && !row.ready && !isLocal)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    '下载',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.brand,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else if (!downloading)
                Icon(Icons.chevron_right, size: 20, color: _secondary),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    super.dispose();
  }
}

class _FontRow {
  final String key;
  final String urlOrPath;
  final bool ready;

  const _FontRow({
    required this.key,
    required this.urlOrPath,
    this.ready = false,
  });

  _FontRow copyWith({
    String? key,
    String? urlOrPath,
    bool? ready,
  }) {
    return _FontRow(
      key: key ?? this.key,
      urlOrPath: urlOrPath ?? this.urlOrPath,
      ready: ready ?? this.ready,
    );
  }
}
