import 'package:book/model/SourceModel.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/person/YckceoSourcePage.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 书源管理：导入 / 启用 / 删除 / 导出
class SourceManagePage extends ConsumerStatefulWidget {
  @override
  ConsumerState<SourceManagePage> createState() => _SourceManagePageState();
}

class _SourceManagePageState extends ConsumerState<SourceManagePage> {
  bool _agreed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sourceModelProvider).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(sourceModelProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('书源管理'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const YckceoSourcePage()),
              );
              if (mounted) ref.read(sourceModelProvider).load();
            },
            icon: Icon(Icons.storefront_outlined),
            label: Text('源仓库'),
          ),
          IconButton(
            tooltip: '导出',
            icon: Icon(Icons.upload_file),
            onPressed: () async {
              final json = model.exportAll();
              await Clipboard.setData(ClipboardData(text: json));
              BotToast.showText(text: '已复制全部书源 JSON 到剪贴板');
            },
          ),
          IconButton(
            tooltip: '导入',
            icon: Icon(Icons.add),
            onPressed: () => _showImport(context, model),
          ),
        ],
      ),
      body: model.loading && model.sources.isEmpty
          ? Center(child: CircularProgressIndicator())
          : model.sources.isEmpty
              ? _empty(context, model)
              : ListView.separated(
                  itemCount: model.sources.length,
                  separatorBuilder: (_, __) => Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final s = model.sources[i];
                    return ListTile(
                      title: Text(s.bookSourceName.isEmpty
                          ? s.bookSourceUrl
                          : s.bookSourceName),
                      subtitle: Text(
                        [
                          if (s.bookSourceGroup.isNotEmpty) s.bookSourceGroup,
                          s.bookSourceUrl,
                        ].where((e) => e.isNotEmpty).join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: s.enabled,
                            onChanged: (_) => model.toggle(s),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline),
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text('删除书源'),
                                  content: Text(
                                      '确定删除「${s.bookSourceName}」？'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text('取消'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: Text('删除'),
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
    );
  }

  Widget _empty(BuildContext context, SourceModel model) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.library_books_outlined, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text('还没有书源', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text(
              '请自行导入 Legado / 阅读 书源 JSON。\n应用不附带任何书源。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showImport(context, model),
              icon: Icon(Icons.add),
              label: Text('导入书源'),
            ),
            SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const YckceoSourcePage()),
                );
                if (mounted) ref.read(sourceModelProvider).load();
              },
              icon: Icon(Icons.storefront_outlined),
              label: Text('从源仓库一键导入'),
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
                    Text('导入书源',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),
                    Text(
                      '书源由用户自行导入，仅供学习交流。请勿导入或使用侵犯他人版权的书源。由此产生的法律责任由用户自行承担。',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('我已阅读并同意上述声明', style: TextStyle(fontSize: 13)),
                      value: agreed,
                      onChanged: (v) => setSt(() {
                        agreed = v ?? false;
                        _agreed = agreed;
                      }),
                    ),
                    Row(
                      children: [
                        ChoiceChip(
                          label: Text('粘贴 JSON'),
                          selected: tab == 0,
                          onSelected: (_) => setSt(() => tab = 0),
                        ),
                        SizedBox(width: 8),
                        ChoiceChip(
                          label: Text('网络 URL'),
                          selected: tab == 1,
                          onSelected: (_) => setSt(() => tab = 1),
                        ),
                        SizedBox(width: 8),
                        ActionChip(
                          avatar: Icon(Icons.storefront_outlined, size: 18),
                          label: Text('源仓库'),
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
                    SizedBox(height: 8),
                    if (tab == 0)
                      TextField(
                        controller: textCtrl,
                        maxLines: 8,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '粘贴 Legado 书源 JSON（对象或数组）',
                        ),
                      )
                    else
                      TextField(
                        controller: urlCtrl,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'https://example.com/sources.json',
                        ),
                      ),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: !agreed
                          ? null
                          : () async {
                              try {
                                if (tab == 0) {
                                  await model.importJsonText(textCtrl.text,
                                      agreed: agreed);
                                } else {
                                  await model.importFromUrl(urlCtrl.text.trim(),
                                      agreed: agreed);
                                }
                                if (ctx.mounted) Navigator.pop(ctx);
                              } catch (e) {
                                BotToast.showText(text: e.toString());
                              }
                            },
                      child: Text('导入'),
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
