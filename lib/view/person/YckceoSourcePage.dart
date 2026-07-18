import 'package:book/source/repo/yckceo_repo.dart';
import 'package:book/store/Store.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// 源仓库（yckceo）书源 / 合集浏览，支持多选一键导入。
///
/// 站点「订阅源」(`/yuedu/rss/`) 与本 App 阅读引擎不匹配；
/// 本页导入「书源」(`/yuedu/shuyuan/`) 与「书源合集」。
class YckceoSourcePage extends ConsumerStatefulWidget {
  const YckceoSourcePage({super.key});

  @override
  ConsumerState<YckceoSourcePage> createState() => _YckceoSourcePageState();
}

class _YckceoSourcePageState extends ConsumerState<YckceoSourcePage>
    with SingleTickerProviderStateMixin {
  final _repo = YckceoRepo();
  late final TabController _tabs;
  late final List<_TabState> _tabsState;

  bool _agreed = false;

  @override
  void initState() {
    super.initState();
    _tabsState = [
      _TabState(isCollection: false),
      _TabState(isCollection: true),
    ];
    _tabs = TabController(length: _tabsState.length, vsync: this);
    // 首帧后拉列表，避免和 Tab 动画打架
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTab(0, refresh: true);
    });
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) return;
      final i = _tabs.index;
      if (_tabsState[i].items.isEmpty && !_tabsState[i].loading) {
        _loadTab(i, refresh: true);
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (final t in _tabsState) {
      t.searchCtrl.dispose();
    }
    super.dispose();
  }

  _TabState get _cur => _tabsState[_tabs.index];

  Future<void> _loadTab(int index, {bool refresh = false}) async {
    final tab = _tabsState[index];
    if (tab.loading || tab.loadingMore) return;
    if (refresh) {
      tab.page = 1;
      tab.error = null;
      setState(() => tab.loading = true);
    } else {
      if (!tab.hasMore) return;
      setState(() => tab.loadingMore = true);
    }

    try {
      final page = refresh ? 1 : tab.page + 1;
      final keys = tab.searchCtrl.text.trim();
      final res = tab.isCollection
          ? await _repo.fetchCollections(page: page, keys: keys)
          : await _repo.fetchSources(page: page, keys: keys);
      if (!mounted) return;
      setState(() {
        tab.page = page;
        tab.total = res.total;
        if (refresh) {
          tab.items = res.items;
          tab.selected.clear();
        } else {
          final seen = tab.items.map((e) => e.id).toSet();
          for (final it in res.items) {
            if (seen.add(it.id)) tab.items.add(it);
          }
        }
        tab.loading = false;
        tab.loadingMore = false;
        tab.error = null;
      });
    } catch (e, st) {
      debugPrint('Yckceo load failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        tab.loading = false;
        tab.loadingMore = false;
        tab.error = e.toString();
      });
      if (!refresh) {
        BotToast.showText(text: '加载失败：$e');
      }
    }
  }

  Future<void> _importSelected() async {
    if (!_agreed) {
      BotToast.showText(text: '请先确认书源使用声明');
      return;
    }
    final tab = _cur;
    if (tab.selected.isEmpty) {
      BotToast.showText(text: '请先勾选要导入的项');
      return;
    }
    final model = ref.read(sourceModelProvider);
    final selectedItems =
        tab.items.where((e) => tab.selected.contains(e.id)).toList();
    try {
      if (tab.isCollection) {
        var total = 0;
        for (var i = 0; i < selectedItems.length; i++) {
          final it = selectedItems[i];
          BotToast.showText(
            text: '正在导入合集 ${i + 1}/${selectedItems.length}：${it.title}',
          );
          total += await model.importFromUrl(it.jsonUrl, agreed: true);
        }
        BotToast.showText(
          text: total == 0 ? '未解析到有效书源' : '完成，共写入 $total 个书源（含更新）',
        );
      } else {
        const batch = 30;
        var total = 0;
        final ids = selectedItems.map((e) => e.id).toList();
        for (var i = 0; i < ids.length; i += batch) {
          final end = (i + batch > ids.length) ? ids.length : i + batch;
          final chunk = ids.sublist(i, end);
          BotToast.showText(text: '正在导入书源 ${i + 1}-$end/${ids.length}…');
          total += await model.importFromUrl(
            YckceoRepo.multiSourceJsonUrl(chunk),
            agreed: true,
          );
        }
        if (total == 0) BotToast.showText(text: '未解析到有效书源');
      }
      if (mounted) setState(() => tab.selected.clear());
    } catch (e) {
      BotToast.showText(text: '导入失败：$e');
    }
  }

  Future<void> _importOne(YckItem item) async {
    if (!_agreed) {
      BotToast.showText(text: '请先确认书源使用声明');
      return;
    }
    try {
      await ref
          .read(sourceModelProvider)
          .importFromUrl(item.jsonUrl, agreed: true);
    } catch (e) {
      BotToast.showText(text: '导入失败：$e');
    }
  }

  Future<void> _openSite() async {
    final uri = Uri.parse(
      _cur.isCollection
          ? YckceoRepo.shuyuansIndexUrl
          : YckceoRepo.shuyuanIndexUrl,
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      BotToast.showText(text: '无法打开浏览器');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tab = _cur;
    return Scaffold(
      appBar: AppBar(
        title: const Text('源仓库'),
        actions: [
          TextButton(onPressed: _openSite, child: const Text('网页')),
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: tab.loading ? null : () => _loadTab(_tabs.index, refresh: true),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: '书源'),
            Tab(text: '合集'),
          ],
        ),
      ),
      body: Column(
        children: [
          Material(
            color: theme.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '来自 yckceo 源仓库 · 仅导入书源（非订阅源）',
                    style: TextStyle(fontSize: 12, color: theme.hintColor),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    title: const Text('我已阅读并同意：书源自行导入、责任自负',
                        style: TextStyle(fontSize: 13)),
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: tab.searchCtrl,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText:
                                tab.isCollection ? '搜索合集' : '搜索书源',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                          ),
                          onSubmitted: (_) =>
                              _loadTab(_tabs.index, refresh: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: tab.loading
                            ? null
                            : () => _loadTab(_tabs.index, refresh: true),
                        child: const Text('搜索'),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        tab.loading && tab.items.isEmpty
                            ? '加载中…'
                            : '已加载 ${tab.items.length}'
                                '${tab.total > 0 ? ' / ${tab.total}' : ''}'
                                ' · 已选 ${tab.selected.length}',
                        style:
                            TextStyle(fontSize: 12, color: theme.hintColor),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: tab.items.isEmpty
                            ? null
                            : () => setState(() {
                                  for (final it in tab.items) {
                                    tab.selected.add(it.id);
                                  }
                                }),
                        child: const Text('全选'),
                      ),
                      TextButton(
                        onPressed: tab.selected.isEmpty
                            ? null
                            : () => setState(() => tab.selected.clear()),
                        child: const Text('清空'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                for (var i = 0; i < _tabsState.length; i++)
                  _buildList(i),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: FilledButton.icon(
            onPressed: (!_agreed || tab.selected.isEmpty)
                ? null
                : _importSelected,
            icon: const Icon(Icons.download_done),
            label: Text(
              tab.selected.isEmpty
                  ? '勾选后一键导入'
                  : '一键导入已选 ${tab.selected.length} 项',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(int index) {
    final tab = _tabsState[index];
    if (tab.loading && tab.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (tab.error != null && tab.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text('加载失败', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(tab.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _loadTab(index, refresh: true),
                child: const Text('重试'),
              ),
              TextButton(
                onPressed: _openSite,
                child: const Text('浏览器打开源仓库'),
              ),
            ],
          ),
        ),
      );
    }
    if (tab.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('没有匹配的结果'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => _loadTab(index, refresh: true),
              child: const Text('重新加载'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadTab(index, refresh: true),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels >= n.metrics.maxScrollExtent - 240) {
            _loadTab(index, refresh: false);
          }
          return false;
        },
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 8),
          itemCount: tab.items.length + (tab.loadingMore ? 1 : 0),
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (ctx, i) {
            if (i >= tab.items.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            final it = tab.items[i];
            final selected = tab.selected.contains(it.id);
            final sub = [
              if (it.host != null && it.host!.isNotEmpty) it.host!,
              if (it.updated != null && it.updated!.isNotEmpty) it.updated!,
              if (it.downloads != null) '↓${it.downloads}',
              if (it.isCollection) '合集',
            ].join(' · ');
            return CheckboxListTile(
              value: selected,
              onChanged: (_) {
                setState(() {
                  if (selected) {
                    tab.selected.remove(it.id);
                  } else {
                    tab.selected.add(it.id);
                  }
                });
              },
              title: Text(
                it.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: sub.isEmpty
                  ? null
                  : Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis),
              secondary: IconButton(
                tooltip: '单独导入',
                icon: const Icon(Icons.download_outlined),
                onPressed: () => _importOne(it),
              ),
              controlAffinity: ListTileControlAffinity.leading,
            );
          },
        ),
      ),
    );
  }
}

class _TabState {
  _TabState({required this.isCollection});

  final bool isCollection;
  final searchCtrl = TextEditingController();
  final selected = <String>{};
  List<YckItem> items = [];
  int page = 1;
  int total = 0;
  bool loading = false;
  bool loadingMore = false;
  String? error;

  bool get hasMore => total <= 0 || items.length < total;
}
