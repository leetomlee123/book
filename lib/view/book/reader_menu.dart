import 'dart:convert';

import 'package:book/common/read_setting.dart';
import 'package:book/common/app_colors.dart';
import 'package:book/entity/book_info.dart';
import 'package:book/event/event.dart';
import 'package:book/model/color_model.dart';
import 'package:book/model/read_model.dart';
import 'package:book/route/routes.dart';
import 'package:book/store/providers.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReaderMenu extends ConsumerStatefulWidget {
  const ReaderMenu({super.key});

  @override
  ConsumerState<ReaderMenu> createState() => _MenuState();
}

enum Type { SLIDE, MORE_SETTING, DOWNLOAD, LAYOUT }

class _MenuState extends ConsumerState<ReaderMenu> {
  Type type = Type.SLIDE;
  late ReadModel _readModel;
  late ColorModel _colorModel;

  @override
  void initState() {
    super.initState();
    _readModel = ref.read(readModelProvider);
    _colorModel = ref.read(colorModelProvider);
  }

  Color get _panelBg =>
      _colorModel.dark ? AppColors.surfaceDark : AppColors.surface;

  Color get _fg =>
      _colorModel.dark ? AppColors.textOnDark : AppColors.textPrimary;

  Color get _muted => AppColors.textSecondary;

  Color get _divider =>
      _colorModel.dark ? AppColors.dividerDark : AppColors.divider;

  Color get _chipBg =>
      _colorModel.dark ? const Color(0xFF2A2A2A) : const Color(0xFFF2F2F2);

  // ---------------------------------------------------------------------------
  // Top bar
  // ---------------------------------------------------------------------------

  Widget head() {
    return SafeArea(
      bottom: false,
      child: Container(
        decoration: BoxDecoration(
          color: _panelBg,
          boxShadow: AppShadows.softBar,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new, size: 18, color: _fg),
              onPressed: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: Text(
                _readModel.book?.name ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: _fg,
                ),
              ),
            ),
            IconButton(
              tooltip: '刷新',
              icon: Icon(Icons.refresh, size: 22, color: _fg),
              onPressed: () => _readModel.reloadCurrentPage(),
            ),
            // IconButton(
            //   tooltip: '换源',
            //   icon: Icon(Icons.swap_horiz, size: 22, color: _fg),
            //   onPressed: () {
            //     showModalBottomSheet(
            //       context: context,
            //       isScrollControlled: true,
            //       backgroundColor: Colors.transparent,
            //       builder: (_) => SourceSwitchSheet(readModel: _readModel),
            //     );
            //   },
            // ),
            IconButton(
              tooltip: '详情',
              icon: Icon(Icons.info_outline, size: 22, color: _fg),
              onPressed: () async {
                final b = _readModel.book;
                if (b == null) return;
                final info = BookInfo(
                  id: b.id,
                  name: b.name,
                  author: b.author,
                  coverUrl: b.coverUrl,
                  category: b.category,
                  description: b.description,
                  latestChapter: b.latestChapter,
                  updatedAt: b.updatedAt,
                  sourceUrl: b.sourceUrl,
                  bookUrl: b.bookUrl,
                  originName: b.originName,
                  tocUrl: b.tocUrl,
                );
                Routes.navigateTo(context, Routes.detail,
                    params: {"detail": jsonEncode(info)}, replace: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget midTransparent() {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _dismissMenu,
        child: const ColoredBox(color: Colors.transparent),
      ),
    );
  }

  void _dismissMenu() {
    type = Type.SLIDE;
    if (_readModel.showMenu) {
      _readModel.toggleShowMenu();
    }
  }

  // ---------------------------------------------------------------------------
  // Chapter slider panel
  // ---------------------------------------------------------------------------

  Widget chapterSlide() {
    final max = (_readModel.chapters.isEmpty)
        ? 0.0
        : (_readModel.chapters.length - 1).toDouble();
    final cur = (_readModel.book?.chapterIndex ?? 0).toDouble().clamp(0.0, max);
    final chapterName = (_readModel.book?.chapterIndex != null &&
            _readModel.book!.chapterIndex >= 0 &&
            _readModel.book!.chapterIndex < _readModel.chapters.length)
        ? _readModel.chapters[_readModel.book!.chapterIndex].title
        : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (chapterName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                chapterName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: _muted),
              ),
            ),
          Row(
              children: <Widget>[
              _miniTextBtn('上一章', () async {
                if ((_readModel.book!.chapterIndex - 1) < 0) {
                  BotToast.showText(text: '已经是第一章');
                  return;
                }
                _readModel.book!.chapterIndex -= 1;
                await _readModel.initPageContent(_readModel.book!.chapterIndex, true);
                _readModel.scheduleProgressSave(delay: Duration.zero);
                setState(() {});
              }),
              Expanded(
                child: SliderTheme(
                  data: _sliderTheme(),
                  child: Slider(
                    value: cur,
                    max: max <= 0 ? 1 : max,
                    min: 0.0,
                    onChanged: max <= 0
                        ? null
                        : (newValue) {
                            _readModel.book!.chapterIndex = newValue.round();
                            setState(() {});
                          },
                    onChangeEnd: max <= 0
                        ? null
                        : (newValue) {
                            _readModel.initPageContent(newValue.round(), true);
                            _readModel.scheduleProgressSave(
                                delay: Duration.zero);
                          },
                  ),
                ),
              ),
              _miniTextBtn('下一章', () async {
                if ((_readModel.book!.chapterIndex + 1) >= _readModel.chapters.length) {
                  BotToast.showText(text: '已经是最后一章');
                  return;
                }
                _readModel.book!.chapterIndex += 1;
                await _readModel.initPageContent(_readModel.book!.chapterIndex, true);
                _readModel.scheduleProgressSave(delay: Duration.zero);
                setState(() {});
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniTextBtn(String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: _fg,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }

  // ---------------------------------------------------------------------------
  // Download panel
  // ---------------------------------------------------------------------------

  Widget downloadWidget() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _filledOutlineBtn('从当前缓存', () {
              BotToast.showText(text: '从当前章节开始下载…');
              _readModel.downloadAll(_readModel.book!.chapterIndex);
            }),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _filledOutlineBtn('全本缓存', () {
              BotToast.showText(text: '开始全本下载…');
              _readModel.downloadAll(0);
            }),
          ),
        ],
      ),
    );
  }

  Widget _filledOutlineBtn(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: _fg,
        side: BorderSide(color: _divider),
        backgroundColor: _chipBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }

  // ---------------------------------------------------------------------------
  // Settings L1: 字号 + 入口；L2: 行距/段距/边距
  // ---------------------------------------------------------------------------

  /// 设置一级：字号、背景、更多入口（含排版二级）
  Widget moreSetting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _sectionLabel('字号'),
          const SizedBox(height: 8),
          _stepperRow(
            label: '字号',
            valueText: ReadSetting.getFontSize().round().toString(),
            onMinus: () {
              ReadSetting.calcFontSize(-1);
              _readModel.relayoutPages();
              setState(() {});
            },
            onPlus: () {
              ReadSetting.calcFontSize(1);
              _readModel.relayoutPages();
              setState(() {});
            },
            child: _buildSlider(
              value: ReadSetting.getFontSize(),
              min: 10,
              max: 60,
              onChanged: (v) {
                ReadSetting.setFontSize(v);
                _readModel.relayoutPages();
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 14),
          _sectionLabel('背景'),
          const SizedBox(height: 10),
          _paperSwatchRow(),
          const SizedBox(height: 16),
          _sectionLabel('翻页'),
          const SizedBox(height: 10),
          _pageTurnModeRow(),
          const SizedBox(height: 16),
          _sectionLabel('更多'),
          const SizedBox(height: 10),
          _settingTile(
            icon: Icons.format_line_spacing,
            title: '行距 · 段距 · 边距',
            onTap: () => setState(() => type = Type.LAYOUT),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _settingTile(
                  icon: Icons.font_download_outlined,
                  title: '字体',
                  onTap: () => Routes.navigateTo(context, Routes.fontSet),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _settingTile(
                  icon: Icons.touch_app_outlined,
                  title: '单手模式',
                  trailing: SizedBox(
                    height: 24,
                    child: Switch.adaptive(
                      value: _readModel.tapLeftToAdvance,
                      activeTrackColor: AppColors.brand,
                      onChanged: (_) {
                        _readModel.toggleTapLeftToAdvance();
                        setState(() {});
                      },
                    ),
                  ),
                  onTap: () {
                    _readModel.toggleTapLeftToAdvance();
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pageTurnModeRow() {
    const modes = <(int, String, IconData)>[
      (0, '无动画', Icons.flash_on_outlined),
      (2, '覆盖', Icons.layers_outlined),
      (1, '仿真', Icons.auto_stories_outlined),
      (3, '滚动', Icons.swap_vert),
    ];
    final current = _readModel.currentAnimationMode;
    return Row(
      children: modes.map((m) {
        final selected = current == m.$1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Material(
              color: selected ? AppColors.brandSoft : _chipBg,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  _readModel.setAnimationMode(m.$1);
                  setState(() {});
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      Icon(
                        m.$3,
                        size: 18,
                        color: selected ? AppColors.brand : _fg,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        m.$2,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? AppColors.brand : _fg,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 设置二级：行距 / 段距 / 边距
  Widget layoutSetting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: '返回',
                icon: Icon(Icons.arrow_back_ios_new, size: 16, color: _fg),
                onPressed: () => setState(() => type = Type.MORE_SETTING),
              ),
              Text(
                '排版',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _fg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _stepperRow(
            label: '行距',
            valueText: ReadSetting.getLineHeight().toStringAsFixed(1),
            onMinus: () {
              ReadSetting.subLineHeight();
              _readModel.relayoutPages();
              setState(() {});
            },
            onPlus: () {
              ReadSetting.addLineHeight();
              _readModel.relayoutPages();
              setState(() {});
            },
            child: _buildSlider(
              value: ReadSetting.getLineHeight(),
              min: 0.1,
              max: 4.0,
              onChanged: (v) {
                ReadSetting.setLineHeight(v);
                _readModel.relayoutPages();
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 4),
          _stepperRow(
            label: '段距',
            valueText: ReadSetting.getParagraph().toStringAsFixed(1),
            onMinus: () {
              ReadSetting.subParagraph();
              _readModel.relayoutPages();
              setState(() {});
            },
            onPlus: () {
              ReadSetting.addParagraph();
              _readModel.relayoutPages();
              setState(() {});
            },
            child: _buildSlider(
              value: ReadSetting.getParagraph(),
              min: 0.1,
              max: 2.0,
              onChanged: (v) {
                ReadSetting.setParagraph(v);
                _readModel.relayoutPages();
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 4),
          _stepperRow(
            label: '边距',
            valueText: '${ReadSetting.getPageDis()}',
            onMinus: () {
              ReadSetting.calcPageDis(-1);
              _readModel.relayoutPages();
              setState(() {});
            },
            onPlus: () {
              ReadSetting.calcPageDis(1);
              _readModel.relayoutPages();
              setState(() {});
            },
            child: _buildSlider(
              value: ReadSetting.getPageDis().toDouble(),
              min: 0,
              max: 50,
              onChanged: (v) {
                ReadSetting.setPageDis(v.toInt());
                _readModel.relayoutPages();
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: _muted,
        letterSpacing: 0.4,
      ),
    );
  }

  /// Label | − | slider | + | value
  Widget _stepperRow({
    required String label,
    required String valueText,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
    required Widget child,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(label, style: TextStyle(fontSize: 13, color: _fg)),
        ),
        _roundIconBtn(Icons.remove, onMinus),
        Expanded(child: child),
        _roundIconBtn(Icons.add, onPlus),
        SizedBox(
          width: 32,
          child: Text(
            valueText,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              color: _muted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _roundIconBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _chipBg,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: _fg),
      ),
    );
  }

  SliderThemeData _sliderTheme() {
    return SliderTheme.of(context).copyWith(
      trackHeight: 3,
      activeTrackColor: AppColors.brand,
      inactiveTrackColor: _divider,
      thumbColor: AppColors.brand,
      overlayColor: AppColors.brandSoft,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
    );
  }

  Widget _buildSlider({
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return SliderTheme(
      data: _sliderTheme(),
      child: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        onChanged: onChanged,
      ),
    );
  }

  Widget _paperSwatchRow() {
    final current = ReadSetting.getPaperTheme();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: ReadSetting.solidPapers.map((t) {
        final selected = current == t;
        return GestureDetector(
          onTap: () async {
            final wasDark = _colorModel.dark;
            await _readModel.setPaperTheme(t);
            final nowDark = t == PaperTheme.night;
            if (wasDark != nowDark) {
              _colorModel.switchModel();
            }
            setState(() {});
          },
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ReadSetting.paperColor(t),
                  shape: BoxShape.circle,
                  border: Border.all(
                    width: selected ? 2.5 : 1,
                    color: selected ? AppColors.brand : _divider,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.brand.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: selected
                    ? Icon(
                        Icons.check,
                        size: 18,
                        color: t == PaperTheme.night
                            ? Colors.white70
                            : AppColors.brand,
                      )
                    : null,
              ),
              const SizedBox(height: 6),
              Text(
                ReadSetting.paperLabel(t),
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? AppColors.brand : _muted,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _chipBg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: _fg),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 13, color: _fg),
                ),
              ),
              trailing ??
                  Icon(Icons.chevron_right, size: 18, color: _muted),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Panel switcher + bottom tabs
  // ---------------------------------------------------------------------------

  Widget bottomHead() {
    switch (type) {
      case Type.MORE_SETTING:
        return moreSetting();
      case Type.LAYOUT:
        return layoutSetting();
      case Type.DOWNLOAD:
        return downloadWidget();
      default:
        return chapterSlide();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when theme or reader chrome-relevant fields change.
    _colorModel = ref.watch(colorModelProvider);
    ref.watch(readModelProvider.select((m) => (
          m.book?.chapterIndex,
          m.book?.name,
          m.tapLeftToAdvance,
          m.paperTheme,
          m.currentAnimationMode,
          m.chapters.length,
        )));
    _readModel = ref.read(readModelProvider);

    // Full-screen stack: dimmed/tap-to-dismiss layer under chrome, so the
    // blank reading area always closes the menu (including when settings is open).
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Catch taps on the reading area.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _dismissMenu,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          // Top chrome
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: head(),
          ),
          // Bottom panel (settings / chapter / download)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: _panelBg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x1A000000),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                clipBehavior: Clip.antiAlias,
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 2),
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _divider,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      bottomHead(),
                      Divider(height: 1, color: _divider),
                      buildBottomMenus(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBottomMenus() {
    final isNight = _colorModel.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
      child: Row(
        children: <Widget>[
          _bottomTab(
            label: '目录',
            icon: Icons.menu,
            active: false,
            onTap: () {
              eventBus.fire(OpenChapters('dd'));
              _readModel.toggleShowMenu();
            },
          ),
          _bottomTab(
            label: isNight ? '日间' : '夜间',
            icon: isNight ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            active: false,
            onTap: () async {
              ref.read(colorModelProvider).switchModel();
              final night = ref.read(colorModelProvider).dark;
              await _readModel.setPaperTheme(
                night ? PaperTheme.night : PaperTheme.cream,
              );
              setState(() {});
            },
          ),
          _bottomTab(
            label: '缓存',
            icon: Icons.cloud_download_outlined,
            active: type == Type.DOWNLOAD,
            onTap: () {
              setState(() {
                type = type == Type.DOWNLOAD ? Type.SLIDE : Type.DOWNLOAD;
              });
            },
          ),
          _bottomTab(
            label: '设置',
            icon: Icons.tune,
            active: type == Type.MORE_SETTING,
            onTap: () {
              setState(() {
                type =
                    type == Type.MORE_SETTING ? Type.SLIDE : Type.MORE_SETTING;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _bottomTab({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    final color = active ? AppColors.brand : _fg;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
