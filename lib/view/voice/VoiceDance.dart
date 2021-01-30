import 'package:audioplayers/audioplayers.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/VoiceModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/system/AnimationImages.dart';
import 'package:book/view/voice/RollImg.dart';
import 'package:flutter/material.dart';

class VoiceDance extends StatefulWidget {
  @override
  _VoiceDanceState createState() => _VoiceDanceState();
}

class _VoiceDanceState extends State<VoiceDance> with TickerProviderStateMixin {
  ColorModel _colorModel;

  @override
  void initState() {
    _colorModel = Store.value<ColorModel>(context);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Store.connect<VoiceModel>(
        builder: (context, VoiceModel model, child) {
      return model.hasEntity
          ? Align(
              alignment: Alignment(-0.7, 0.4),
              child: model.showMenu ? _danceMenu(model) : _danceIcon(model))
          : Container();
    });
  }

  Widget _danceIcon(VoiceModel model) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(25.0)),
        color: Colors.white,
        // border: Border.all(
        //   width: 1,
        //   color: _colorModel.dark ? Colors.white10 : Colors.black,
        // )
      ),
      child: Store.connect<VoiceModel>(
          builder: (context, VoiceModel model, child) {
        return InkWell(
          child: (model.audioPlayer.state != AudioPlayerState.PLAYING)
              ? Image(
                  image: AssetImage(
                    "images/loading_00029.png",
                  ),
                  color: _colorModel.theme.primaryColor,
                )
              : AnimationImages(),
          onTap: () {
            model.showMenuFun(true);
            if (model.audioPlayer.state == AudioPlayerState.PLAYING) {
              eventBus.fire(RollEvent("1"));
            }
          },
        );
      }),
      width: 45,
      height: 45,
    );
  }

  Widget _danceMenu(VoiceModel model) {
    return Container(
      decoration: BoxDecoration(
        color: _colorModel.dark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(45.0)),
      ),
      height: 45,
      width: 230,
      child: ListView(
        padding: EdgeInsets.only(left: 10),
        scrollDirection: Axis.horizontal,
        children: [
          InkWell(
            child: RollImg(),
            onTap: () {
              Routes.navigateTo(context, Routes.voiceDetail,
                  params: {"link": model.link, "idx": model.idx.toString()});
            },
          ),
          _divider(),
          InkWell(
            child: ImageIcon(
              AssetImage("images/${model.stateImg}.png"),
              // color: Colors.white,
            ),
            onTap: () async {
              if (model.audioPlayer.state != AudioPlayerState.PLAYING) {
                 eventBus.fire(RollEvent("1"));
              } else {
                 eventBus.fire(RollEvent("0"));
              }
              await model.toggleState();
            },
          ),
          _divider(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            //transitionBuilder决定动画效果
            transitionBuilder: (Widget child, Animation<double> animation) {
              //执行缩放动画
//              return ScaleTransition(child: child,scale: animation,);
              //渐显渐隐动画
              return FadeTransition(
                child: child,
                opacity: animation,
              );
            },
            child: InkWell(
              child: ImageIcon(
                AssetImage("images/btu.png"),
              ),
              onTap: () async {
                 eventBus.fire(RollEvent("0"));
                await model.changeUrl(1);
                 eventBus.fire(RollEvent("1"));
              },
            ),
          ),
          _divider(),
          InkWell(
            child: ImageIcon(
              AssetImage("images/egq.png"),
            ),
            onTap: () async {
              Routes.navigateTo(context, Routes.voiceList);
            },
          ),
          _divider(),
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                model.showMenuFun(false);
              })
        ],
      ),
    );
  }

  Widget _divider() {
    return VerticalDivider(
      indent: 10,
      endIndent: 10,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
