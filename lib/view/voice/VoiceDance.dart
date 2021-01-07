import 'package:audioplayers/audioplayers.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/VoiceModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/system/AnimationImages.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class VoiceDance extends StatefulWidget {
  @override
  _VoiceDanceState createState() => _VoiceDanceState();
}

class _VoiceDanceState extends State<VoiceDance> with TickerProviderStateMixin {
  ColorModel _colorModel;
  VoiceModel _voiceModel;
  AnimationController controller;

  @override
  void initState() {
    eventBus.on<RollEvent>().listen((roll) {
      if (roll.roll == "1") {
        controller?.forward();
      } else {
        controller?.reset();
      }
    });
    _colorModel = Store.value<ColorModel>(context);
    _voiceModel = Store.value<VoiceModel>(context);
    controller =
        AnimationController(duration: const Duration(seconds: 20), vsync: this);
    if (_voiceModel.audioPlayer.state == AudioPlayerState.PLAYING) {
      controller.forward();
    }
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        //动画从 controller.forward() 正向执行 结束时会回调此方法
        print("status is completed");
        //重置起点
        controller.reset();
        //开启
        controller.forward();
      } else if (status == AnimationStatus.dismissed) {
        //动画从 controller.reverse() 反向执行 结束时会回调此方法
        print("status is dismissed");
      } else if (status == AnimationStatus.forward) {
        print("status is forward");
        //执行 controller.forward() 会回调此状态
      } else if (status == AnimationStatus.reverse) {
        //执行 controller.reverse() 会回调此状态
        print("status is reverse");
      }
    });
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
              controller.forward();
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
      width: 220,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          InkWell(
            child: _buildRotationTransition(model),
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
                controller.forward();
              } else {
                controller.reset();
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
                controller.reset();
                await model.changeUrl(1);
                controller.forward();
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

  Widget _buildRotationTransition(VoiceModel model) {
    return Center(
      child: RotationTransition(
        alignment: Alignment.center,
        turns: controller,
        child: Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
                // color: Colors.green,
                borderRadius: BorderRadius.circular(35),
                // 圆形图片
                image: DecorationImage(
                    image: model.voiceDetail == null
                        ? AssetImage("images/nocover.jpg")
                        : CachedNetworkImageProvider(
                            model.voiceDetail.cover,
                          ),
                    fit: BoxFit.cover))),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
