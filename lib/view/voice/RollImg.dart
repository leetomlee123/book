// import 'package:audioplayers/audioplayers.dart';
// import 'package:book/event/event.dart';
// import 'package:book/model/VoiceModel.dart';
// import 'package:book/store/Store.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
//
// class RollImg extends StatefulWidget {
//   final double width;
//   final double height;
//
//   RollImg({this.width = 35, this.height = 35});
//
//   @override
//   _RollImgState createState() => _RollImgState();
// }
//
// class _RollImgState extends State<RollImg> with TickerProviderStateMixin {
//   // AnimationController controller;
//   VoiceModel _voiceModel;
//
//   @override
//   void initState() {
//     // eventBus.on<RollEvent>().listen((roll) {
//     //   if (roll.roll == "1") {
//     //     if (controller.status != AnimationStatus.forward) {
//     //       controller?.forward();
//     //     }
//     //   } else {
//     //     controller?.reset();
//     //   }
//     // });
//     _voiceModel = Store.value<VoiceModel>(context);
//     // controller =
//     //     AnimationController(duration: const Duration(seconds: 20), vsync: this);
//     // if (_voiceModel.audioPlayer.state == AudioPlayerState.PLAYING) {
//     //   controller.forward();
//     // }
//     // controller.addStatusListener((status) {
//     //   if (status == AnimationStatus.completed) {
//     //     //动画从 controller.forward() 正向执行 结束时会回调此方法
//     //     print("status is completed");
//     //     //重置起点
//     //     controller.reset();
//     //     //开启
//     //     controller.forward();
//     //   } else if (status == AnimationStatus.dismissed) {
//     //     //动画从 controller.reverse() 反向执行 结束时会回调此方法
//     //     print("status is dismissed");
//     //   } else if (status == AnimationStatus.forward) {
//     //     print("status is forward");
//     //     //执行 controller.forward() 会回调此状态
//     //   } else if (status == AnimationStatus.reverse) {
//     //     //执行 controller.reverse() 会回调此状态
//     //     print("status is reverse");
//     //   }
//     // });
//
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: RotationTransition(
//         alignment: Alignment.center,
//         turns: controller,
//         child: Container(
//             width: this.widget.width,
//             height: this.widget.height,
//             decoration: BoxDecoration(
//                 // color: Colors.green,
//                 borderRadius: BorderRadius.circular(this.widget.width),
//                 // 圆形图片
//                 image: DecorationImage(
//                     image: _voiceModel.voiceDetail == null
//                         ? AssetImage("images/nocover.jpg")
//                         : CachedNetworkImageProvider(
//                             _voiceModel.voiceDetail.cover,
//                           ),
//                     fit: BoxFit.cover))),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     controller.dispose();
//     super.dispose();
//   }
// }
