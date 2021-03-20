// import 'package:book/model/ColorModel.dart';
// import 'package:book/model/VoiceModel.dart';
// import 'package:book/store/Store.dart';
// import 'package:flutter/material.dart';
//
//
// class VoiceScrollList extends StatefulWidget {
//   @override
//   _VoiceScrollListState createState() => _VoiceScrollListState();
// }
//
// class _VoiceScrollListState extends State<VoiceScrollList> {
//   ScrollController controller= new ScrollController();
//   static double itemHeight = 50.0;
//   final scrollDirection = Axis.vertical;
//   VoiceModel _voiceModel;
//   ColorModel _colorModel;
//
//   @override
//   void initState() {
//     _voiceModel = Store.value<VoiceModel>(context);
//     _colorModel = Store.value<ColorModel>(context);
//
//     var widgetsBinding = WidgetsBinding.instance;
//     widgetsBinding.addPostFrameCallback((callback) {
//       scrollTo();
//     });
//     super.initState();
//   }
// //滚动到当前阅读位置
//   scrollTo() async {
//     if (controller.hasClients) {
//
//       await controller.animateTo(
//           (_voiceModel.idx - 3) * (itemHeight+16),
//           duration: Duration(microseconds: 1),
//           curve: Curves.ease);
//     }
//   }
//   Widget _getRow(int idx) {
//     return GestureDetector(
//       child: Container(
//         margin: EdgeInsets.symmetric(vertical: 5),
//         alignment: Alignment.center,
//         height: itemHeight,
//         decoration: BoxDecoration(
//             border: Border.all(
//                 color: idx == _voiceModel.idx
//                     ? _colorModel.theme.primaryColor
//                     : Colors.black,
//                 width: 2),
//             borderRadius: BorderRadius.circular(12)),
//         child: Text(_voiceModel.voiceDetail.chapters[idx].name,style: TextStyle(    color: idx == _voiceModel.idx
//             ? _colorModel.theme.primaryColor
//             : Colors.black,),),
//       ),
//       onTap: () {
//         if (_voiceModel.idx != idx) {
//           _voiceModel.changeUrl(idx, flag: false);
//           Navigator.pop(context);
//         }
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       child: ListView.builder(
//           controller: controller,
//           itemExtent: itemHeight+16,
//           padding: EdgeInsets.all(8),
//           itemBuilder: (BuildContext context, int ix) {
//             return _getRow(ix);
//           },
//           itemCount: _voiceModel.voiceDetail.chapters.length),
//     );
//   }
//
//   @override
//   void dispose() {
//     controller.dispose();
//     super.dispose();
//   }
// }