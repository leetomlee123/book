// import 'package:book/model/VoiceModel.dart';
// import 'package:book/store/Store.dart';
// import 'package:flutter/material.dart';
//
// class Fast extends StatelessWidget {
//   List<double> fasts = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5];
//
//   @override
//   Widget build(BuildContext context) {
//     return Store.connect<VoiceModel>(
//         builder: (context, VoiceModel model, child) {
//       return Container(
//           child: ListView(
//         padding: const EdgeInsets.all(6.0),
//         children: fasts
//             .map((e) => ListTile(
//                   title: Text('X${e.toString()}'),
//                   trailing: Radio(
//                     value: e,
//                     autofocus: true,
//                     groupValue: model.fast,
//                     onChanged: (v) {
//                       model.setFast(v);
//                       model.audioPlayer
//                           .setPlaybackRate(playbackRate: model.fast);
//
//                     },
//                   ),
//                 ))
//             .toList(),
//       ));
//     });
//   }
// }
