import 'package:book/model/read_model.dart';
import 'package:book/source/engine/book_source_engine.dart';
import 'package:book/source/model/book_source.dart';
import 'package:book/source/model/search_book.dart';
import 'package:book/store/providers.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom sheet: search enabled sources for the current book and switch.
class SourceSwitchSheet extends ConsumerStatefulWidget {
  final ReadModel readModel;
  const SourceSwitchSheet({super.key, required this.readModel});

  @override
  ConsumerState<SourceSwitchSheet> createState() => _SourceSwitchSheetState();
}

class _SourceSwitchSheetState extends ConsumerState<SourceSwitchSheet> {
  final BookSourceEngine _engine = BookSourceEngine();
  bool loading = true;
  final List<_Candidate> candidates = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final book = widget.readModel.book;
    if (book == null) {
      setState(() => loading = false);
      return;
    }
    final key = book.name.isNotEmpty ? book.name : book.author;
    if (key.isEmpty) {
      setState(() => loading = false);
      return;
    }
    final sources = await ref.read(sourceModelProvider).enabledSources();
    final list = <_Candidate>[];
    const pool = 5;
    for (var i = 0; i < sources.length; i += pool) {
      final chunk = sources.skip(i).take(pool);
      final futures = chunk.map((s) async {
        try {
          final hits = await _engine
              .search(s, key, 1)
              .timeout(BookSourceEngine.sourceTimeout);
          return hits
              .where((h) {
                if (book.author.isEmpty) return true;
                return h.author.contains(book.author) ||
                    book.author.contains(h.author) ||
                    h.name.contains(book.name);
              })
              .map((h) => _Candidate(s, h))
              .toList();
        } catch (_) {
          return <_Candidate>[];
        }
      });
      final parts = await Future.wait(futures);
      for (final p in parts) {
        list.addAll(p);
      }
    }
    // Prefer exact name matches first
    list.sort((a, b) {
      final an = a.hit.name == book.name ? 0 : 1;
      final bn = b.hit.name == book.name ? 0 : 1;
      if (an != bn) return an - bn;
      return a.source.bookSourceName.compareTo(b.source.bookSourceName);
    });
    if (!mounted) return;
    setState(() {
      candidates
        ..clear()
        ..addAll(list);
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.readModel.book;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '换源 · ${book?.name ?? ''}',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
            ),
            if (book?.originName.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('当前：${book!.originName}',
                      style: TextStyle(color: Colors.grey[600])),
                ),
              ),
            Expanded(
              child: loading
                  ? Center(child: CircularProgressIndicator())
                  : candidates.isEmpty
                      ? Center(child: Text('未找到其它可用书源'))
                      : ListView.separated(
                          itemCount: candidates.length,
                          separatorBuilder: (_, _) => Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final c = candidates[i];
                            final current = c.source.bookSourceUrl ==
                                book?.sourceUrl;
                            return ListTile(
                              title: Text(c.hit.name),
                              subtitle: Text(
                                [
                                  c.source.bookSourceName,
                                  if (c.hit.author.isNotEmpty) c.hit.author,
                                  if (c.hit.lastChapter.isNotEmpty)
                                    c.hit.lastChapter,
                                ].join(' · '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: current
                                  ? Text('当前',
                                      style: TextStyle(color: Colors.green))
                                  : Icon(Icons.chevron_right),
                              onTap: current
                                  ? null
                                  : () async {
                                      final ok = await widget.readModel
                                          .switchSource(c.source, c.hit);
                                      if (!context.mounted) return;
                                      if (ok) {
                                        Navigator.pop(context);
                                      } else {
                                        BotToast.showText(text: '换源失败');
                                      }
                                    },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Candidate {
  final BookSource source;
  final SearchBook hit;
  _Candidate(this.source, this.hit);
}
