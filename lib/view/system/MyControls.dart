// import 'dart:async';
//
// import 'package:book/common/Screen.dart';
// import 'package:book/event/event.dart';
// import 'package:book/model/ColorModel.dart';
// import 'package:book/store/Store.dart';
// import 'package:chewie/src/chewie_player.dart';
// import 'package:chewie/src/chewie_progress_colors.dart';
// import 'package:chewie/src/material_progress_bar.dart';
// import 'package:chewie/src/utils.dart';
// import 'package:flutter/material.dart';
// import 'package:screen/screen.dart' as Light;
// import 'package:video_player/video_player.dart';
//
// class MyControls extends StatefulWidget {
//   final String title;
//   final double latestLight;
//
//   MyControls(this.title, this.latestLight);
//
//   @override
//   State<StatefulWidget> createState() {
//     return _MyMaterialControlsState();
//   }
// }
//
// class _MyMaterialControlsState extends State<MyControls> {
//   VideoPlayerValue _latestValue;
//   double _latestVolume;
//   double _latestLight;
//   final int len = 300;
//   int intVolume;
//   int intLight;
//   bool _hideStuff = true;
//   Timer _hideTimer;
//   Timer _initTimer;
//   Timer _showAfterExpandCollapseTimer;
//   bool _dragging = false;
//   bool isVoice = false;
//
//   //拖动进度对比24/120
//   bool _progress = false;
//   bool _adjust = false;
//   bool _displayTapped = false;
//   static const lightColor = Color.fromRGBO(255, 255, 255, 0.85);
//   static const darkColor = Colors.transparent;
//   final barHeight = 48.0;
//   final marginSize = 5.0;
//   Offset _initialSwipeOffset;
//   Offset _finalSwipeOffset;
//   ColorModel _colorModel;
//
//   VideoPlayerController controller;
//   ChewieController chewieController;
//
//   @override
//   void initState() {
//     setUp();
//     super.initState();
//   }
//
//   setUp() async {
//     _latestLight = this.widget.latestLight;
//     _latestVolume = .5;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_latestValue.hasError) {
//       return chewieController.errorBuilder != null
//           ? chewieController.errorBuilder(
//               context,
//               chewieController.videoPlayerController.value.errorDescription,
//             )
//           : Center(
//               child: Icon(
//                 Icons.error,
//                 color: Colors.white,
//                 size: 42,
//               ),
//             );
//     }
//
//     return MouseRegion(
//       onHover: (_) {
//         _cancelAndRestartTimer();
//       },
//       child: GestureDetector(
//         onDoubleTap: _doubleTap,
//         onHorizontalDragStart: _onHorizontalDragStart,
//         onHorizontalDragUpdate: _onHorizontalDragUpdate,
//         onHorizontalDragEnd: _onHorizontalDragEnd,
//         onVerticalDragStart: (DragStartDetails dragStartDetails) {
//           setState(() {
//             if (intVolume == null) {
//               intVolume = (len * _latestVolume) as int;
//             }
//             _adjust = true;
//           });
//         },
//         onVerticalDragUpdate: (DragUpdateDetails dragUpdateDetails) {
//           double wSpace = Screen.width / 5;
//           double dx = dragUpdateDetails.globalPosition.dx;
//           bool up = dragUpdateDetails.primaryDelta < 0;
//           if (dx < wSpace) {
//             isVoice = false;
//             if (up) {
//               intLight += 1;
//             } else {
//               intLight -= 1;
//             }
//             setState(() {
//               if (intLight > len) {
//                 intLight = len;
//                 _latestLight = 1.0;
//               } else if (intLight < 0) {
//                 intLight = 0;
//                 _latestLight = 0;
//               }
//               var d = intLight / len;
//               Light.Screen.setBrightness(d);
//             });
//           } else if (dx > (wSpace * 4)) {
//             isVoice = true;
//             if (up) {
//               intVolume += 1;
//             } else {
//               intVolume -= 1;
//             }
//             setState(() {
//               if (intVolume > len) {
//                 intVolume = len;
//                 _latestVolume = 1.0;
//               } else if (intVolume < 0) {
//                 intVolume = 0;
//                 _latestVolume = 0;
//               }
//               var d = intVolume / len;
//               controller.setVolume(d);
//             });
//           }
//         },
//         onVerticalDragEnd: (DragEndDetails dragEndDetails) {
//           setState(() {
//             _adjust = false;
//             if (isVoice) {
//               if (intVolume > len) {
//                 intVolume = len;
//                 _latestVolume = 1.0;
//               } else if (intVolume < 0) {
//                 intVolume = 0;
//                 _latestVolume = 0;
//               }
//               var d = intVolume / len;
//               controller.setVolume(d);
//             } else {
//               if (intLight > len) {
//                 intLight = len;
//                 _latestLight = 1.0;
//               } else if (intLight < 0) {
//                 intLight = 0;
//                 _latestLight = 0;
//               }
//               var d = intLight / len;
//               Light.Screen.setBrightness(d);
//             }
//           });
//         },
//         onTap: () => _cancelAndRestartTimer(),
//         child: AbsorbPointer(
//             absorbing: _hideStuff,
//             child: Stack(
//               children: [
//                 Column(
//                   children: <Widget>[
//                     chewieController.isFullScreen
//                         ? _buildHeader(context, this.widget.title)
//                         : Container(),
//                     Center(
//                       child: Container(
//                           width: Screen.width / 6 * 4,
//                           child: Offstage(
//                               offstage: !_adjust,
//                               child: Align(
//                                   child: Row(
//                                     children: [
//                                       Icon(
//                                         isVoice ? Icons.alarm : Icons.lightbulb,
//                                         color: Colors.white,
//                                       ),
//                                       Expanded(
//                                         child: Slider(
//                                           value: getIntSlider(),
//                                           max: len.toDouble(),
//                                           min: 0,
//                                           activeColor: Colors.white,
//                                           inactiveColor: Colors.white38,
//                                           onChanged: (v) {},
//                                         ),
//                                       )
//                                     ],
//                                   ),
//                                   alignment: Alignment.topCenter))),
//                     ),
//                     _latestValue != null &&
//                                 !_latestValue.isPlaying &&
//                                 _latestValue.duration == null ||
//                             _latestValue.isBuffering
//                         ? const Expanded(
//                             child: const Center(
//                               child: const CircularProgressIndicator(),
//                             ),
//                           )
//                         : _buildHitArea(),
//                     _buildBottomBar(context),
//                   ],
//                 ),
//                 Align(
//                   child: (_hideStuff && !chewieController.isFullScreen)
//                       ? Container(
//                           color: Colors.transparent,
//                           height: 0,
//                           child: Row(
//                             children: [_buildProgressBar()],
//                           ),
//                         )
//                       : Container(),
//                   alignment: Alignment.bottomCenter,
//                 ),
//               ],
//             )),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _dispose();
//     super.dispose();
//   }
//
//   void _dispose() {
//     controller.removeListener(_updateState);
//     _hideTimer?.cancel();
//     _initTimer?.cancel();
//     _showAfterExpandCollapseTimer?.cancel();
//   }
//
//   @override
//   void didChangeDependencies() {
//     final _oldController = chewieController;
//     chewieController = ChewieController.of(context);
//     controller = chewieController.videoPlayerController;
//
//     if (_oldController != chewieController) {
//       _dispose();
//       _initialize();
//     }
//
//     super.didChangeDependencies();
//   }
//
//   Widget _buildHeader(BuildContext context, String title) {
//     return Container(
//       color: darkColor,
//       height: barHeight,
//       child: AnimatedOpacity(
//         opacity: _hideStuff ? 0.0 : 1.0,
//         duration: Duration(milliseconds: 300),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: <Widget>[
//             IconButton(
//               onPressed: _onExpandCollapse,
//               color: lightColor,
//               icon: Icon(Icons.arrow_back_ios),
//             ),
//             Text(
//               '$title',
//               style: TextStyle(
//                 color: lightColor,
//                 fontSize: 16.0,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   double getIntSlider() {
//     if (isVoice) {
//       if (intVolume == null) {
//         intVolume = (_latestVolume * len).toInt();
//       }
//       if (intVolume > len) {
//         return len.toDouble();
//       } else if (intVolume < 0) {
//         return .0;
//       } else {
//         return intVolume.toDouble();
//       }
//     } else {
//       if (intLight == null) {
//         intLight = (_latestLight * len).toInt();
//       }
//       if (intLight > len) {
//         return len.toDouble();
//       } else if (intLight < 0) {
//         return .0;
//       } else {
//         return intLight.toDouble();
//       }
//     }
//   }
//
//   AnimatedOpacity _buildBottomBar(
//     BuildContext context,
//   ) {
//     final iconColor = Theme.of(context).textTheme.button.color;
//     return AnimatedOpacity(
//       opacity: _hideStuff ? 0.0 : 1.0,
//       duration: Duration(milliseconds: 300),
//       child: Container(
//         height: barHeight,
//         color: darkColor,
//         child: Row(
//           children: <Widget>[
//             // _buildPlayPause(controller),
//             SizedBox(
//               width: 15,
//             ),
//             // _buildPlayNext(controller),
//             chewieController.isLive
//                 ? Expanded(
//                     child: const Text(
//                     'LIVE',
//                     style: TextStyle(color: lightColor),
//                   ))
//                 : _buildPosition(iconColor),
//             chewieController.isLive ? const SizedBox() : _buildProgressBar(),
//             // chewieController.allowMuting
//             //     ? _buildMuteButton(controller)
//             //     : Container(),
//             Offstage(
//               offstage: !chewieController.allowFullScreen,
//               child: _buildExpandButton(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   GestureDetector _buildExpandButton() {
//     return GestureDetector(
//       onTap: _onExpandCollapse,
//       child: AnimatedOpacity(
//         opacity: _hideStuff ? 0.0 : 1.0,
//         duration: Duration(milliseconds: 300),
//         child: Container(
//           height: barHeight,
//           margin: EdgeInsets.only(right: 12.0),
//           padding: EdgeInsets.only(
//             left: 8.0,
//             right: 8.0,
//           ),
//           child: Center(
//             child: ImageIcon(
//               AssetImage(chewieController.isFullScreen
//                   ? "images/fullscreen_exit.png"
//                   : "images/fullscreen_enter.png"),
//               size: 32.0,
//               color: Colors.white,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Expanded _buildHitArea() {
//     return Expanded(
//       child: GestureDetector(
//         onTap: () {
//           if (_latestValue != null && _latestValue.isPlaying) {
//             if (_displayTapped) {
//               setState(() {
//                 _playPause();
//                 // _hideStuff = true;
//               });
//             } else
//               _cancelAndRestartTimer();
//           } else {
//             _playPause();
//
//             setState(() {
//               _hideStuff = true;
//             });
//           }
//         },
//         child: Container(
//           color: Colors.transparent,
//           child: Center(
//             child: AnimatedOpacity(
//               opacity:
//                   _latestValue != null && !_dragging && !_hideStuff ? 1.0 : 0.0,
//               duration: Duration(milliseconds: 300),
//               child: GestureDetector(
//                 child: Container(
//                   child: Padding(
//                     padding: EdgeInsets.all(12.0),
//                     child: ImageIcon(
//                       AssetImage(_latestValue.isPlaying
//                           ? "images/btv.png"
//                           : "images/video_play.png"),
//                       size: 64.0,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   GestureDetector _buildMuteButton(
//     VideoPlayerController controller,
//   ) {
//     return GestureDetector(
//       onTap: () {
//         _cancelAndRestartTimer();
//
//         if (_latestValue.volume == 0) {
//           controller.setVolume(_latestVolume ?? 0.5);
//         } else {
//           _latestVolume = controller.value.volume;
//           controller.setVolume(0.0);
//         }
//       },
//       child: AnimatedOpacity(
//         opacity: _hideStuff ? 0.0 : 1.0,
//         duration: Duration(milliseconds: 300),
//         child: ClipRect(
//           child: Container(
//             child: Container(
//               height: barHeight,
//               padding: EdgeInsets.only(
//                 left: 8.0,
//                 right: 8.0,
//               ),
//               child: ImageIcon(
//                 AssetImage((_latestValue != null && _latestValue.volume > 0)
//                     ? "images/voice_ok.png"
//                     : "images/voice_stop.png"),
//                 size: 32.0,
//                 color: Colors.white,
//               ),
//               // child: Icon(
//               //   (_latestValue != null && _latestValue.volume > 0)
//               //       ? Icons.volume_up
//               //       : Icons.volume_off,
//               //   color: lightColor,
//               // ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   GestureDetector _buildPlayPause(VideoPlayerController controller) {
//     return GestureDetector(
//       onTap: _playPause,
//       child: Container(
//         height: barHeight,
//         color: Colors.transparent,
//         margin: EdgeInsets.only(left: 8.0, right: 4.0),
//         padding: EdgeInsets.only(
//           left: 2.0,
//           right: 12.0,
//         ),
//         child: ImageIcon(
//           AssetImage(controller.value.isPlaying
//               ? "images/btv.png"
//               : "images/video_play.png"),
//           color: Colors.white,
//           size: 32,
//         ),
//       ),
//     );
//   }
//
//   GestureDetector _buildPlayNext(VideoPlayerController controller) {
//     return GestureDetector(
//       onTap: _playNext,
//       child: Container(
//         height: barHeight,
//         color: Colors.transparent,
//         margin: EdgeInsets.only(left: 2.0, right: 8.0),
//         padding: EdgeInsets.only(
//           left: 2.0,
//           right: 2.0,
//         ),
//         child: ImageIcon(
//           AssetImage("images/video_next.png"),
//           color: Colors.white,
//           size: 32,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildPosition(Color iconColor) {
//     final position = _latestValue != null && _latestValue.position != null
//         ? _latestValue.position
//         : Duration.zero;
//     final duration = _latestValue != null && _latestValue.duration != null
//         ? _latestValue.duration
//         : Duration.zero;
//
//     return Padding(
//       padding: EdgeInsets.only(right: 20.0),
//       child: Text(
//         '${formatDuration(position)} / ${formatDuration(duration)}',
//         style: TextStyle(fontSize: 11.0, color: lightColor),
//       ),
//     );
//   }
//
//   void _onHorizontalDragStart(DragStartDetails details) {
//     _initialSwipeOffset = details.globalPosition;
//   }
//
//   void _onHorizontalDragUpdate(DragUpdateDetails details) {
//     _finalSwipeOffset = details.globalPosition;
//     if (controller.value.isPlaying) {}
//   }
//
//   void _onHorizontalDragEnd(DragEndDetails details) {
//     if (_initialSwipeOffset != null) {
//       final offsetDifference = _initialSwipeOffset.dx - _finalSwipeOffset.dx;
//       if (offsetDifference > 0) {
//         if (controller.value.isPlaying) {
//           controller.position.then(
//               (value) => {controller.seekTo(value - Duration(seconds: 5))});
//         }
//       } else {
//         if (controller.value.isPlaying) {
//           controller.position.then(
//               (value) => {controller.seekTo(value + Duration(seconds: 5))});
//         }
//       }
//     }
//   }
//
//   void _cancelAndRestartTimer() {
//     _hideTimer?.cancel();
//     _startHideTimer();
//
//     setState(() {
//       _hideStuff = false;
//       _displayTapped = true;
//     });
//   }
//
//   Future<Null> _initialize() async {
//     controller.addListener(_updateState);
//     _colorModel = Store.value<ColorModel>(context);
//     _updateState();
//
//     if ((controller.value != null && controller.value.isPlaying) ||
//         chewieController.autoPlay) {
//       _startHideTimer();
//     }
//
//     if (chewieController.showControlsOnInitialize) {
//       _initTimer = Timer(Duration(milliseconds: 200), () {
//         setState(() {
//           _hideStuff = false;
//         });
//       });
//     }
//   }
//
//   void _onExpandCollapse() {
//     setState(() {
//       _hideStuff = true;
//
//       chewieController.toggleFullScreen();
//       _showAfterExpandCollapseTimer = Timer(Duration(milliseconds: 300), () {
//         setState(() {
//           _cancelAndRestartTimer();
//         });
//       });
//     });
//   }
//
//   void _playNext() {
//     eventBus.fire(new PlayEvent("name"));
//   }
//
//   void _playPause() {
//     bool isFinished = _latestValue.position >= _latestValue.duration;
//
//     setState(() {
//       if (controller.value.isPlaying) {
//         _hideStuff = false;
//         _hideTimer?.cancel();
//         controller.pause();
//       } else {
//         _cancelAndRestartTimer();
//
//         if (!controller.value.isInitialized) {
//           controller.initialize().then((_) {
//             controller.play();
//           });
//         } else {
//           if (isFinished) {
//             controller.seekTo(Duration(seconds: 0));
//           }
//           controller.play();
//         }
//       }
//     });
//   }
//
//   void _startHideTimer() {
//     _hideTimer = Timer(const Duration(seconds: 3), () {
//       setState(() {
//         _hideStuff = true;
//       });
//     });
//   }
//
//   void _updateState() {
//     setState(() {
//       _latestValue = controller.value;
//     });
//   }
//
//   Widget _buildProgressBar() {
//     return Expanded(
//       child: Padding(
//         padding: EdgeInsets.only(right: _hideStuff ? 0 : 10.0),
//         child: MaterialVideoProgressBar(
//           controller,
//           onDragStart: () {
//             setState(() {
//               _dragging = true;
//             });
//
//             _hideTimer?.cancel();
//           },
//           onDragEnd: () {
//             setState(() {
//               _dragging = false;
//             });
//
//             _startHideTimer();
//           },
//           colors: chewieController.materialProgressColors ??
//               ChewieProgressColors(
//                 playedColor: _colorModel.theme.primaryColor,
//                 handleColor: lightColor,
//                 bufferedColor: Colors.white60,
//                 backgroundColor: Colors.white24,
//               ),
//         ),
//       ),
//     );
//   }
//
//   void _doubleTap() {
//     if (_latestValue != null) {
//       if (_latestValue.isPlaying) {
//         _playPause();
//       } else {
//         chewieController.play();
//         _cancelAndRestartTimer();
//       }
//     }
//   }
// }
