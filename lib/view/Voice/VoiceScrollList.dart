import 'package:book/common/Screen.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/VoiceModel.dart';
import 'package:book/store/Store.dart';
import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class VoiceScrollList extends StatefulWidget {
  @override
  _VoiceScrollListState createState() => _VoiceScrollListState();
}

class _VoiceScrollListState extends State<VoiceScrollList> {
  AutoScrollController controller;
  static const maxCount = 100;
  final scrollDirection = Axis.vertical;
  VoiceModel _voiceModel;
  ColorModel _colorModel;

  @override
  void initState() {
    _voiceModel = Store.value<VoiceModel>(context);
    _colorModel = Store.value<ColorModel>(context);
    controller = AutoScrollController(
        viewportBoundaryGetter: () =>
            Rect.fromLTRB(0, 0, 0, Screen.bottomSafeHeight),
        axis: scrollDirection);
    var widgetsBinding = WidgetsBinding.instance;
    widgetsBinding.addPostFrameCallback((callback) async {
      print("xx ${_voiceModel.idx}");
      await controller.scrollToIndex(_voiceModel.idx,
          preferPosition: AutoScrollPosition.middle);
      controller.highlight(_voiceModel.idx);
    });

    super.initState();
  }

  Widget _getRow(int idx, double height) {
    return _wrapScroollTag(
        idx: idx,
        child: GestureDetector(
          child: Container(
            // padding: EdgeInsets.only(bottom: 20),
            margin: EdgeInsets.symmetric(vertical: 5),
            alignment: Alignment.center,
            height: height,
            decoration: BoxDecoration(
                border:
                    Border.all(color: _voiceModel.idx==idx? _colorModel.theme.primaryColor:Colors.black, width: 1),
                borderRadius: BorderRadius.circular(12)),
            child: Text(_voiceModel.voiceDetail.chapters[idx].name),
          ),
          onTap: () {
            if (_voiceModel.idx != idx) {
              _voiceModel.changeUrl(idx, flag: false);
              Navigator.pop(context);
            }
          },
        ));
  }

  Widget _wrapScroollTag({int idx, Widget child}) => AutoScrollTag(
        key: ValueKey(idx),
        controller: controller,
        index: idx,
        child: child,
        highlightColor: _colorModel.theme.primaryColor.withOpacity(.1),
      );
  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListView.builder(
        controller: controller,
          padding: EdgeInsets.all(8),
          itemBuilder: (BuildContext context, int ix) {
            return _getRow(ix, 60);
          },
          itemCount: _voiceModel.voiceDetail.chapters.length),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
