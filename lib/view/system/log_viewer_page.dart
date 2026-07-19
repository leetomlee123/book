import 'package:book/common/app_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Simple in-app log viewer for diagnosing reader / source issues.
class LogViewer extends StatefulWidget {
  const LogViewer({super.key});

  @override
  State<LogViewer> createState() => _LogViewerState();
}

class _LogViewerState extends State<LogViewer> {
  final ScrollController _scroll = ScrollController();
  VoidCallback? _unsub;
  List<String> _lines = [];
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _lines = AppLog.entries;
    _unsub = AppLog.addListener((line) {
      if (!mounted) return;
      setState(() {
        _lines = AppLog.entries;
      });
      if (_autoScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) {
            _scroll.jumpTo(_scroll.position.maxScrollExtent);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _unsub?.call();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _copyAll() async {
    final text = AppLog.dump();
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('日志已复制到剪贴板')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('运行日志 (${_lines.length})'),
        actions: [
          IconButton(
            tooltip: _autoScroll ? '关闭自动滚动' : '开启自动滚动',
            icon: Icon(_autoScroll ? Icons.vertical_align_bottom : Icons.pause),
            onPressed: () => setState(() => _autoScroll = !_autoScroll),
          ),
          IconButton(
            tooltip: '复制全部',
            icon: const Icon(Icons.copy),
            onPressed: _copyAll,
          ),
          IconButton(
            tooltip: '清空',
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              AppLog.clear();
              setState(() => _lines = []);
            },
          ),
        ],
      ),
      body: _lines.isEmpty
          ? const Center(child: Text('暂无日志'))
          : ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: _lines.length,
              itemBuilder: (_, i) {
                final line = _lines[i];
                final color = line.contains(' E/')
                    ? Colors.red.shade700
                    : line.contains(' W/')
                        ? Colors.orange.shade800
                        : null;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: SelectableText(
                    line,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: color,
                      height: 1.3,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
