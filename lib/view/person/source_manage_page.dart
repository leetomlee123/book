import 'package:book/model/source_model.dart';
import 'package:book/store/providers.dart';
import 'package:book/view/person/yckceo_source_page.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 书源管理：导入 / 启用 / 删除 / 导出 / 批量管理
class SourceManagePage extends ConsumerStatefulWidget {
  const SourceManagePage({super.key});

  @override
  ConsumerState<SourceManagePage> createState() => _SourceManagePageState();
}

class _SourceManagePageState extends ConsumerState<SourceManagePage> {
  bool _agreed = false;
  bool _selectMode = false;
  final Set<String> _selected = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sourceModelProvider).load();
    });
  }

  void _exitSelectMode() {
    setState(() {
      _selectMode = false;
      _selected.clear();
    });
  }

  void _enterSelectMode() {
    setState(() {
      _selectMode = true;
      _selected.clear();
    });
  }

  void _selectAll(SourceModel model) {
    setState(() {
      _selected
        ..clear()
        ..addAll(model.sources.map((e) => e.bookSourceUrl));
    });
  }

  void _invertSelection(SourceModel model) {
    setState(() {
      final all = model.sources.map((e) => e.bookSourceUrl).toSet();
      final next = all.difference(_selected);
      _selected
        ..clear()
        ..addAll(next);
    });
  }

  Future<void> _enableSelected(SourceModel model) async {
    if (_selected.isEmpty) {
      BotToast.showText(text: '请先勾选书源');
      return;
    }
    await model.enableMany(_selected.toList());
    BotToast.showText(text: '已启用 ${_selected.length} 个书源');
    _exitSelectMode();
  }

  Future<void> _disableSelected(SourceModel model) async {
    if (_selected.isEmpty) {
      BotToast.showText(text: '请先勾选书源');
      return;
    }
    await model.disableMany(_selected.toList());
    BotToast.showText(text: '已禁用 ${_selected.length} 个书源');
    _exitSelectMode();
  }

  Future<void> _deleteSelected(SourceModel model) async {
    if (_selected.isEmpty) {
      BotToast.showText(text: '请先勾选书源');
      return;
    }
    final n = _selected.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除书源'),
        content: Text('确定删除已选的 $n 个书源？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await model.removeMany(_selected.toList());
    BotToast.showText(text: '已删除 $n 个书源');
    _exitSelectMode();
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(sourceModelProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectMode ? '已选 ${_selected.length}' : '书源管理'),
        leading: _selectMode
            ? IconButton(
                tooltip: '取消',
                icon: const Icon(Icons.close),
                onPressed: _exitSelectMode,
              )
            : null,
        actions: _selectMode
            ? [
                TextButton(
                  onPressed: () => _selectAll(model),
                  child: const Text('全选'),
                ),
                TextButton(
                  onPressed: () => _invertSelection(model),
                  child: const Text('反选'),
                ),
              ]
            : [
                TextButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const YckceoSourcePage(),
                      ),
                    );
                    if (mounted) ref.read(sourceModelProvider).load();
                  },
                  icon: const Icon(Icons.storefront_outlined),
                  label: const Text('源仓库'),
                ),
                if (model.sources.isNotEmpty)
                  IconButton(
                    tooltip: '批量管理',
                    icon: const Icon(Icons.checklist),
                    onPressed: _enterSelectMode,
                  ),
                IconButton(
                  tooltip: '导出',
                  icon: const Icon(Icons.upload_file),
                  onPressed: () async {
                    final json = model.exportAll();
                    await Clipboard.setData(ClipboardData(text: json));
                    BotToast.showText(text: '已复制全部书源 JSON 到剪贴板');
                  },
                ),
                IconButton(
                  tooltip: '导入',
                  icon: const Icon(Icons.add),
                  onPressed: () => _showImport(context, model),
                ),
              ],
      ),
      body: model.loading && model.sources.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : model.sources.isEmpty
              ? _empty(context, model)
              : ListView.separated(
                  itemCount: model.sources.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final s = model.sources[i];
                    final url = s.bookSourceUrl;
                    final selected = _selected.contains(url);
                    return ListTile(
                      onTap: _selectMode
                          ? () {
                              setState(() {
                                if (selected) {
                                  _selected.remove(url);
                                } else {
                                  _selected.add(url);
                                }
                              });
                            }
                          : null,
                      leading: _selectMode
                          ? Checkbox(
                              value: selected,
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _selected.add(url);
                                  } else {
                                    _selected.remove(url);
                                  }
                                });
                              },
                            )
                          : null,
                      title: Text(
                        s.bookSourceName.isEmpty
                            ? s.bookSourceUrl
                            : s.bookSourceName,
                      ),
                      subtitle: Text(
                        [
                          if (s.bookSourceGroup.isNotEmpty) s.bookSourceGroup,
                          s.bookSourceUrl,
                        ].where((e) => e.isNotEmpty).join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: _selectMode
                          ? null
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: s.enabled,
                                  onChanged: (_) => model.toggle(s),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('删除书源'),
                                        content: Text(
                                          '确定删除「${s.bookSourceName}」？',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('取消'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('删除'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (ok == true) await model.remove(s);
                                  },
                                ),
                              ],
                            ),
                    );
                  },
                ),
      bottomNavigationBar: _selectMode
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _enableSelected(model),
                        child: const Text('启用'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _disableSelected(model),
                        child: const Text('禁用'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _deleteSelected(model),
                        child: const Text('删除'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _empty(BuildContext context, SourceModel model) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.library_books_outlined, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('还没有书源', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              '请自行导入 Legado / 阅读 书源 JSON。\n应用不附带任何书源。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showImport(context, model),
              icon: const Icon(Icons.add),
              label: const Text('导入书源'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const YckceoSourcePage()),
                );
                if (mounted) ref.read(sourceModelProvider).load();
              },
              icon: const Icon(Icons.storefront_outlined),
              label: const Text('从源仓库一键导入'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showImport(BuildContext context, SourceModel model) async {
    final textCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    var agreed = _agreed;
    var tab = 0; // 0 paste, 1 url

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSt) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '导入书源',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '书源由用户自行导入，仅供学习交流。请勿导入或使用侵犯他人版权的书源。由此产生的法律责任由用户自行承担。',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        '我已阅读并同意上述声明',
                        style: TextStyle(fontSize: 13),
                      ),
                      value: agreed,
                      onChanged: (v) => setSt(() {
                        agreed = v ?? false;
                        _agreed = agreed;
                      }),
                    ),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('粘贴 JSON'),
                          selected: tab == 0,
                          onSelected: (_) => setSt(() => tab = 0),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('网络 URL'),
                          selected: tab == 1,
                          onSelected: (_) => setSt(() => tab = 1),
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          avatar: const Icon(Icons.storefront_outlined, size: 18),
                          label: const Text('源仓库'),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const YckceoSourcePage(),
                              ),
                            );
                            if (mounted) {
                              ref.read(sourceModelProvider).load();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (tab == 0)
                      TextField(
                        controller: textCtrl,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '粘贴 Legado 书源 JSON（对象或数组）',
                        ),
                      )
                    else
                      TextField(
                        controller: urlCtrl,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'https://example.com/sources.json',
                        ),
                      ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: !agreed
                          ? null
                          : () async {
                              try {
                                if (tab == 0) {
                                  await model.importJsonText(
                                    textCtrl.text,
                                    agreed: agreed,
                                  );
                                } else {
                                  await model.importFromUrl(
                                    urlCtrl.text.trim(),
                                    agreed: agreed,
                                  );
                                }
                                if (ctx.mounted) Navigator.pop(ctx);
                              } catch (e) {
                                BotToast.showText(text: e.toString());
                              }
                            },
                      child: const Text('导入'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
