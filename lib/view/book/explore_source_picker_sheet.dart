import 'package:book/common/app_colors.dart';
import 'package:book/source/model/book_source.dart';
import 'package:flutter/material.dart';

/// One group of explore sources for the picker list.
class ExploreSourceSection {
  final String title;
  final List<BookSource> items;

  const ExploreSourceSection({required this.title, required this.items});
}

/// Case-insensitive match on name / group / url.
List<BookSource> filterExploreSources(List<BookSource> all, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return List<BookSource>.of(all);
  return all.where((s) {
    final name = s.bookSourceName.toLowerCase();
    final group = s.bookSourceGroup.toLowerCase();
    final url = s.bookSourceUrl.toLowerCase();
    return name.contains(q) || group.contains(q) || url.contains(q);
  }).toList();
}

/// Group by [BookSource.bookSourceGroup]. Empty → trailing「未分组」.
/// Encounter order from the (already sorted) list is preserved.
List<ExploreSourceSection> groupExploreSources(List<BookSource> sources) {
  final order = <String>[];
  final buckets = <String, List<BookSource>>{};
  final ungrouped = <BookSource>[];

  for (final s in sources) {
    final g = s.bookSourceGroup.trim();
    if (g.isEmpty) {
      ungrouped.add(s);
      continue;
    }
    if (!buckets.containsKey(g)) {
      order.add(g);
      buckets[g] = <BookSource>[];
    }
    buckets[g]!.add(s);
  }

  final sections = <ExploreSourceSection>[
    for (final g in order)
      ExploreSourceSection(title: g, items: buckets[g]!),
  ];
  if (ungrouped.isNotEmpty) {
    sections.add(
      ExploreSourceSection(title: '未分组', items: ungrouped),
    );
  }
  return sections;
}

sealed class _PickerRow {}

class _HeaderRow extends _PickerRow {
  final String title;
  final int count;
  _HeaderRow(this.title, this.count);
}

class _SourceRow extends _PickerRow {
  final BookSource source;
  _SourceRow(this.source);
}

List<_PickerRow> _buildRows(List<ExploreSourceSection> sections) {
  final rows = <_PickerRow>[];
  for (final sec in sections) {
    rows.add(_HeaderRow(sec.title, sec.items.length));
    for (final s in sec.items) {
      rows.add(_SourceRow(s));
    }
  }
  return rows;
}

/// Bottom sheet: search + grouped list of explore-capable sources.
class ExploreSourcePickerSheet extends StatefulWidget {
  final List<BookSource> sources;
  final String? activeUrl;
  final ValueChanged<BookSource> onSelected;

  const ExploreSourcePickerSheet({
    super.key,
    required this.sources,
    required this.activeUrl,
    required this.onSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required List<BookSource> sources,
    required String? activeUrl,
    required ValueChanged<BookSource> onSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExploreSourcePickerSheet(
        sources: sources,
        activeUrl: activeUrl,
        onSelected: onSelected,
      ),
    );
  }

  @override
  State<ExploreSourcePickerSheet> createState() =>
      _ExploreSourcePickerSheetState();
}

class _ExploreSourcePickerSheetState extends State<ExploreSourcePickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  late List<_PickerRow> _rows;

  @override
  void initState() {
    super.initState();
    _rows = _buildRows(groupExploreSources(widget.sources));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String _) {
    final filtered = filterExploreSources(widget.sources, _searchCtrl.text);
    setState(() {
      _rows = _buildRows(groupExploreSources(filtered));
    });
  }

  void _clearSearch() {
    if (_searchCtrl.text.isEmpty) return;
    _searchCtrl.clear();
    _onQueryChanged('');
  }

  void _pick(BookSource source) {
    final isCurrent = source.bookSourceUrl == widget.activeUrl;
    Navigator.pop(context);
    if (!isCurrent) {
      widget.onSelected(source);
    }
  }

  String _displayName(BookSource s) =>
      s.bookSourceName.trim().isEmpty ? s.bookSourceUrl : s.bookSourceName;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? AppColors.surfaceDark : AppColors.surface;
    final primary = dark ? AppColors.textOnDark : AppColors.textPrimary;
    final secondary = AppColors.textSecondary;
    final divider = dark ? AppColors.dividerDark : AppColors.divider;
    final accent = AppColors.accentOf(context);
    final fieldBg = dark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F3F3);

    return Material(
      color: surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '选择书源',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: primary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '关闭',
                      icon: Icon(Icons.close, color: secondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onQueryChanged,
                  textInputAction: TextInputAction.search,
                  style: TextStyle(fontSize: 14, color: primary),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '搜索名称 / 分组 / URL',
                    hintStyle: TextStyle(fontSize: 14, color: secondary),
                    prefixIcon: Icon(Icons.search, size: 20, color: secondary),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 36,
                    ),
                    suffixIcon: _searchCtrl.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: '清空',
                            icon: Icon(Icons.clear, size: 18, color: secondary),
                            onPressed: _clearSearch,
                          ),
                    filled: true,
                    fillColor: fieldBg,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Divider(height: 1, color: divider),
              Expanded(
                child: _rows.isEmpty
                    ? Center(
                        child: Text(
                          '未找到匹配书源',
                          style: TextStyle(fontSize: 14, color: secondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _rows.length,
                        itemBuilder: (context, i) {
                          final row = _rows[i];
                          if (row is _HeaderRow) {
                            return Container(
                              color: dark
                                  ? const Color(0xFF161616)
                                  : const Color(0xFFF7F7F7),
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                              child: Text(
                                '${row.title} · ${row.count}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: secondary,
                                ),
                              ),
                            );
                          }
                          final source = (row as _SourceRow).source;
                          final selected =
                              source.bookSourceUrl == widget.activeUrl;
                          final group = source.bookSourceGroup.trim();
                          final subtitle = group.isEmpty
                              ? source.bookSourceUrl
                              : '$group · ${source.bookSourceUrl}';
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            title: Text(
                              _displayName(source),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    selected ? FontWeight.w600 : FontWeight.w400,
                                color: selected ? accent : primary,
                              ),
                            ),
                            subtitle: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: secondary),
                            ),
                            trailing: selected
                                ? Text(
                                    '当前',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: accent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : null,
                            onTap: () => _pick(source),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
