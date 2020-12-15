import 'package:book/entity/VoiceOV.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/VoiceModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/voice/VoiceDance.dart';
import 'package:book/widgets/SAppBarSearch.dart';
import 'package:flutter/material.dart';

class VoiceBook extends StatefulWidget {
  @override
  _VoiceBookState createState() => _VoiceBookState();
}

class _VoiceBookState extends State<VoiceBook> with WidgetsBindingObserver {
  ColorModel _colorModel;
  VoiceModel _voiceModel;

  @override
  void initState() {
    _colorModel = Store.value<ColorModel>(context);
    _voiceModel = Store.value<VoiceModel>(context);
    _voiceModel.getData();
    super.initState();
  }

  void search(var key) {
    _voiceModel.getSearch(key);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        child: SAppBarSearch(
          onSearch: search,
        ),
        preferredSize: Size.fromHeight(83),
      ),
      body:
      Store.connect<VoiceModel>(builder: (context,VoiceModel model,child){
        return  model.isVoiceIdx
            ? Stack(
          children: [
            Container(
              child: ListView(
                  children: _voiceModel.voiceIdxs
                      .map((e) => item(e.cate, e.link, e.voices))
                      .toList()),
            ),
            VoiceDance()
          ],
        )
            : model.voiceMores.isEmpty
            ? Center(
          child: Text("空空如也"),
        )
            : ListView(
            children: model.voiceMores
                .map((e) => ListTile(
              title: Text(e.title),
              trailing: Text(e.date),
              onTap: () {
                Routes.navigateTo(context, Routes.voiceDetail,
                    params: {"link": e.href, "idx": "0"});
              },
            ))
                .toList());
      }),

    );
  }

  Widget item(String title, String link, List<VoiceOV> bks) {
    return Container(
      child: ListView(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: <Widget>[
          SizedBox(
            height: 5.0,
          ),
          Row(
            children: <Widget>[
              Padding(
                child: Container(
                  width: 4,
                  height: 20,
                  color: _colorModel.dark
                      ? Colors.white
                      : _colorModel.theme.primaryColor,
                ),
                padding: EdgeInsets.only(left: 5.0, right: 3.0),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.0,
                ),
              ),
              Expanded(
                child: Container(),
              ),
              GestureDetector(
                child: Row(
                  children: <Widget>[
                    Text(
                      "更多",
                      style: TextStyle(color: Colors.grey, fontSize: 11.0),
                    ),
                    Icon(
                      Icons.keyboard_arrow_right,
                      color: Colors.grey,
                    )
                  ],
                ),
                onTap: () {
                  Routes.navigateTo(context, Routes.voices,
                      params: {"url": link});
                },
              )
            ],
          ),
          Column(
            children: bks
                .map((e) => ListTile(
                      title: Text(e.name),
                      trailing: Text(e.date),
                      onTap: () {
                        Routes.navigateTo(context, Routes.voiceDetail,
                            params: {"link": e.link, "idx": "0"});
                      },
                    ))
                .toList(),
          )
        ],
      ),
    );
  }
}
