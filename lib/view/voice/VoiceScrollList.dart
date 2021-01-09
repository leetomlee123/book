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
  ScrollController controller;
  static double itemHeight = 50.0;
  final scrollDirection = Axis.vertical;
  VoiceModel _voiceModel;
  ColorModel _colorModel;

  @override
  void initState() {
    _voiceModel = Store.value<VoiceModel>(context);
    _colorModel = Store.value<ColorModel>(context);
    print("ok");
    controller =
        AutoScrollController(initialScrollOffset: (_voiceModel.idx-3) * (itemHeight+10));

    super.initState();
  }

  Widget _getRow(int idx) {
    return GestureDetector(
      child: Container(
        // padding: EdgeInsets.only(bottom: 20),
        margin: EdgeInsets.symmetric(vertical: 5),
        alignment: Alignment.center,
        height: itemHeight,
        decoration: BoxDecoration(
            border: Border.all(
                color: idx == _voiceModel.idx
                    ? _colorModel.theme.primaryColor
                    : Colors.black,
                width: 2),
            borderRadius: BorderRadius.circular(12)),
        child: Text(_voiceModel.voiceDetail.chapters[idx].name,style: TextStyle(    color: idx == _voiceModel.idx
            ? _colorModel.theme.primaryColor
            : Colors.black,),),
      ),
      onTap: () {
        if (_voiceModel.idx != idx) {
          _voiceModel.changeUrl(idx, flag: false);
          Navigator.pop(context);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListView.builder(
          controller: controller,
          padding: EdgeInsets.all(8),
          itemBuilder: (BuildContext context, int ix) {
            return _getRow(ix);
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