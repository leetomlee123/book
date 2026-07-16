import 'dart:convert';

import 'package:book/common/ReadSetting.dart';
import 'package:book/common/app_colors.dart';
import 'package:book/entity/BookInfo.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/ReadModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/book/SourceSwitchSheet.dart';
import 'package:book/view/system/MenuConfig.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

class Menu extends StatefulWidget {
  @override
  _MenuState createState() => _MenuState();
}

enum Type { SLIDE, MORE_SETTING, DOWNLOAD }

class _MenuState extends State<Menu> {
  Type type = Type.SLIDE;
  late ReadModel _readModel;
  late ColorModel _colorModel;

  double settingH = 360;

  @override
  void initState() {
    super.initState();
    _readModel = Store.value<ReadModel>(context);
    _colorModel = Store.value<ColorModel>(context);
  }

  Color get _panelBg =>
      _colorModel.dark ? AppColors.surfaceDark : AppColors.surface;

  Color get _fg =>
      _colorModel.dark ? AppColors.textOnDark : AppColors.textPrimary;

  Widget head() {
    return SafeArea(
      bottom: false,
      child: Container(
        decoration: BoxDecoration(
          color: _panelBg,
          boxShadow: AppShadows.softBar,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new, size: 18, color: _fg),
              onPressed: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: Text(
                _readModel.book?.Name ?? '',
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
              icon: Icon(Icons.refresh, color: _fg),
              onPressed: () => _readModel.reloadCurrentPage(),
            ),
            IconButton(
              tooltip: '换源',
              icon: Icon(Icons.swap_horiz, color: _fg),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => SourceSwitchSheet(readModel: _readModel),
                );
              },
            ),
            IconButton(
              tooltip: '详情',
              icon: Icon(Icons.info_outline, color: _fg),
              onPressed: () async {
                final b = _readModel.book;
                if (b == null) return;
                final info = BookInfo(
                  0,
                  b.Author,
                  '',
                  b.CId,
                  b.CName,
                  b.Id,
                  b.Name,
                  b.Img,
                  0,
                  b.Desc,
                  b.LastChapterId,
                  b.LastChapter,
                  '',
                  b.UTime,
                  const [],
                  sourceUrl: b.sourceUrl,
                  bookUrl: b.bookUrl,
                  originName: b.originName,
                  tocUrl: b.tocUrl,
                );
                Routes.navigateTo(context, Routes.detail,
                    params: {"detail": jsonEncode(info)}, replace: true);
              },
            )
          ],
        ),
      ),
    );
  }

  Widget midTransparent() {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        child: Container(color: Colors.transparent),
        onTap: () {
          type = Type.SLIDE;
          _readModel.toggleShowMenu();
        },
      ),
    );
  }

  Widget chapterSlide() {
    final max = (_readModel.chapters.isEmpty)
        ? 0.0
        : (_readModel.chapters.length - 1).toDouble();
    final cur = (_readModel.book?.cur ?? 0).toDouble().clamp(0.0, max);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: <Widget>[
          TextButton(
              onPressed: () async {
                if ((_readModel.book!.cur - 1) < 0) {
                  BotToast.showText(text: '已经是第一章');
                  return;
                }
                _readModel.book!.cur -= 1;
                await _readModel.initPageContent(_readModel.book!.cur, true);
              },
              child: const Text('上一章', style: TextStyle(fontSize: 13))),
          Expanded(
            child: Slider(
              value: cur,
              max: max <= 0 ? 1 : max,
              min: 0.0,
              onChanged: max <= 0
                  ? null
                  : (newValue) {
                      _readModel.book!.cur = newValue.round();
                      setState(() {});
                    },
              onChangeEnd: max <= 0
                  ? null
                  : (newValue) {
                      _readModel.initPageContent(newValue.round(), true);
                    },
            ),
          ),
          TextButton(
              onPressed: () async {
                if ((_readModel.book!.cur + 1) >= _readModel.chapters.length) {
                  BotToast.showText(text: "已经是最后一章");
                  return;
                }
                _readModel.book!.cur += 1;
                await _readModel.initPageContent(_readModel.book!.cur, true);
              },
              child: const Text('下一章', style: TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget downloadWidget() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          Expanded(child: _cacheBtn('从当前章节缓存', () {
            BotToast.showText(text: '从当前章节开始下载...');
            _readModel.downloadAll(_readModel.book!.cur);
          })),
          const SizedBox(width: 12),
          Expanded(child: _cacheBtn('全本缓存', () {
            BotToast.showText(text: '开始全本下载...');
            _readModel.downloadAll(0);
          })),
        ],
      ),
    );
  }

  Widget _cacheBtn(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: _fg.withValues(alpha: 0.35)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(label, style: TextStyle(color: _fg, fontSize: 13)),
    );
  }

  Widget moreSetting() {
    return Container(
      height: settingH,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          MenuConfig(
            () {
              ReadSetting.calcFontSize(-1);
              _readModel.updPage();
            },
            () {
              ReadSetting.calcFontSize(1);
              _readModel.updPage();
            },
            (v) {
              ReadSetting.setFontSize(v);
              _readModel.updPage();
            },
            ReadSetting.getFontSize(),
            "字号",
            min: 10,
            max: 60,
          ),
          _sliderRow(
            '行距',
            ReadSetting.getLineHeight(),
            0.1,
            4.0,
            (v) {
              ReadSetting.setLineHeight(v);
              _readModel.updPage();
            },
            () {
              ReadSetting.subLineHeight();
              _readModel.updPage();
            },
            () {
              ReadSetting.addLineHeight();
              _readModel.updPage();
            },
          ),
          _sliderRow(
            '段距',
            ReadSetting.getParagraph(),
            0.1,
            2.0,
            (v) {
              ReadSetting.setParagraph(v);
              _readModel.updPage();
            },
            () {
              ReadSetting.subParagraph();
              _readModel.updPage();
            },
            () {
              ReadSetting.addParagraph();
              _readModel.updPage();
            },
          ),
          _sliderRow(
            '页距',
            ReadSetting.getPageDis().toDouble(),
            0,
            50,
            (v) {
              ReadSetting.setPageDis(v.toInt());
              _readModel.updPage();
            },
            () {
              ReadSetting.calcPageDis(-1);
              _readModel.updPage();
            },
            () {
              ReadSetting.calcPageDis(1);
              _readModel.updPage();
            },
          ),
          const SizedBox(height: 8),
          Text('背景', style: TextStyle(fontSize: 13, color: _fg)),
          const SizedBox(height: 8),
          Row(children: solidPaperSwatches()),
          const Spacer(),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                      side: BorderSide(
                        width: 1.5,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    onPressed: () {
                      Routes.navigateTo(context, Routes.fontSet);
                    },
                    child: const Text('字体')),
              ),
              const Spacer(flex: 1),
              Expanded(
                flex: 3,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _readModel.leftClickNext,
                  onChanged: (value) {
                    _readModel.switchClickNextPage();
                  },
                  title: Text(
                    '单手模式',
                    style: TextStyle(fontSize: 13, color: _fg),
                  ),
                  selected: _readModel.leftClickNext,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sliderRow(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    VoidCallback onMinus,
    VoidCallback onPlus,
  ) {
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: 13.0, color: _fg)),
        IconButton(
            onPressed: onMinus, icon: const Icon(Icons.remove, size: 18)),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 1,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: value.clamp(min, max),
              onChanged: onChanged,
              min: min,
              max: max,
            ),
          ),
        ),
        IconButton(onPressed: onPlus, icon: const Icon(Icons.add, size: 18)),
      ],
    );
  }

  List<Widget> solidPaperSwatches() {
    final current = ReadSetting.getPaperTheme();
    return ReadSetting.solidPapers.map((t) {
      final selected = current == t;
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: GestureDetector(
          onTap: () async {
            final wasDark = _colorModel.dark;
            await _readModel.switchPaperTheme(t);
            final nowDark = t == PaperTheme.night;
            if (wasDark != nowDark) {
              _colorModel.switchModel();
            }
            setState(() {});
          },
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: ReadSetting.paperColor(t),
                  shape: BoxShape.circle,
                  border: Border.all(
                    width: selected ? 2 : 1,
                    color: selected
                        ? Theme.of(context).primaryColor
                        : AppColors.divider,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ReadSetting.paperLabel(t),
                style: TextStyle(fontSize: 11, color: _fg),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget bottomHead() {
    switch (type) {
      case Type.MORE_SETTING:
        return moreSetting();
      case Type.DOWNLOAD:
        return downloadWidget();
      default:
        return chapterSlide();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        children: <Widget>[
          head(),
          midTransparent(),
          Container(
            decoration: BoxDecoration(
              color: _panelBg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              boxShadow: AppShadows.softBar,
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[bottomHead(), buildBottomMenus()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBottomMenus() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          buildBottomItem('目录', Icons.menu),
          TextButton(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    _colorModel.dark ? Icons.light_mode : Icons.dark_mode,
                    color: _fg,
                  ),
                  const SizedBox(height: 4),
                  Text(_colorModel.dark ? '日间' : '夜间',
                      style: TextStyle(fontSize: 11, color: _fg)),
                ],
              ),
              onPressed: () async {
                Store.value<ColorModel>(context).switchModel();
                final night = Store.value<ColorModel>(context).dark;
                await _readModel.switchPaperTheme(
                    night ? PaperTheme.night : PaperTheme.cream);
                setState(() {});
              }),
          buildBottomItem('缓存', Icons.cloud_download),
          buildBottomItem('设置', Icons.settings),
        ],
      ),
    );
  }

  Widget buildBottomItem(String title, IconData iconData) {
    return TextButton(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(iconData, color: _fg),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 11, color: _fg)),
        ],
      ),
      onPressed: () {
        switch (title) {
          case '目录':
            {
              eventBus.fire(OpenChapters("dd"));
              _readModel.toggleShowMenu();
            }
            break;
          case '缓存':
            {
              setState(() {
                type = type == Type.DOWNLOAD ? Type.SLIDE : Type.DOWNLOAD;
              });
            }
            break;
          case '设置':
            {
              setState(() {
                type =
                    type == Type.MORE_SETTING ? Type.SLIDE : Type.MORE_SETTING;
              });
            }
            break;
        }
      },
    );
  }
}
