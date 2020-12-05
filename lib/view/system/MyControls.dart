import 'dart:async';

import 'package:book/event/event.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/store/Store.dart';
import 'package:chewie/src/chewie_player.dart';
import 'package:chewie/src/chewie_progress_colors.dart';
import 'package:chewie/src/material_progress_bar.dart';
import 'package:chewie/src/utils.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MyControls extends StatefulWidget {
  String title;

  MyControls(this.title);

  @override
  State<StatefulWidget> createState() {
    return _MyMaterialControlsState();
  }
}

class _MyMaterialControlsState extends State<MyControls> {
  VideoPlayerValue _latestValue;
  double _latestVolume;
  bool _hideStuff = true;
  Timer _hideTimer;
  Timer _initTimer;
  Timer _showAfterExpandCollapseTimer;
  bool _dragging = false;
  bool _displayTapped = false;
  static const lightColor = Color.fromRGBO(255, 255, 255, 0.85);
  static const darkColor = Colors.transparent;
  final barHeight = 48.0;
  final marginSize = 5.0;
  Offset _initialSwipeOffset;
  Offset _finalSwipeOffset;
  ColorModel _colorModel;

  VideoPlayerController controller;
  ChewieController chewieController;

  @override
  Widget build(BuildContext context) {
    if (_latestValue.hasError) {
      return chewieController.errorBuilder != null
          ? chewieController.errorBuilder(
              context,
              chewieController.videoPlayerController.value.errorDescription,
            )
          : Center(
              child: Icon(
                Icons.error,
                color: Colors.white,
                size: 42,
              ),
            );
    }

    return MouseRegion(
      onHover: (_) {
        _cancelAndRestartTimer();
      },
      child: GestureDetector(
        onHorizontalDragStart: _onHorizontalDragStart,
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        onTap: () => _cancelAndRestartTimer(),
        child: AbsorbPointer(
            absorbing: _hideStuff,
            child: Stack(
              children: [
                Column(
                  children: <Widget>[
                    chewieController.isFullScreen
                        ? _buildHeader(context, this.widget.title)
                        : Container(),
                    _latestValue != null &&
                                !_latestValue.isPlaying &&
                                _latestValue.duration == null ||
                            _latestValue.isBuffering
                        ? const Expanded(
                            child: const Center(
                              child: const CircularProgressIndicator(),
                            ),
                          )
                        : _buildHitArea(),
                    _buildBottomBar(context),
                  ],
                ),
                Align(
                  child: (_hideStuff && !chewieController.isFullScreen)
                      ? Container(
                          color: darkColor,
                          height: 0,
                          child: Row(
                            children: [_buildProgressBar()],
                          ),
                        )
                      : Container(),
                  alignment: Alignment.bottomCenter,
                )
              ],
            )),
      ),
    );
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    controller.removeListener(_updateState);
    _hideTimer?.cancel();
    _initTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
  }

  @override
  void didChangeDependencies() {
    final _oldController = chewieController;
    chewieController = ChewieController.of(context);
    controller = chewieController.videoPlayerController;

    if (_oldController != chewieController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  AnimatedOpacity _buildHeader(BuildContext context, String title) {
    return new AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: new Duration(milliseconds: 300),
      child: new Container(
        color: darkColor,
        height: barHeight,
        child: new Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            new IconButton(
              onPressed: _onExpandCollapse,
              color: lightColor,
              icon: new Icon(Icons.arrow_back_ios),
            ),
            new Text(
              '$title',
              style: new TextStyle(
                color: lightColor,
                fontSize: 16.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  AnimatedOpacity _buildBottomBar(
    BuildContext context,
  ) {
    final iconColor = Theme.of(context).textTheme.button.color;
    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: Duration(milliseconds: 300),
      child: Container(
        height: barHeight,
        color: darkColor,
        child: Row(
          children: <Widget>[
            _buildPlayPause(controller),
            // _buildPlayNext(controller),
            chewieController.isLive
                ? Expanded(
                    child: const Text(
                    'LIVE',
                    style: TextStyle(color: lightColor),
                  ))
                : _buildPosition(iconColor),
            chewieController.isLive ? const SizedBox() : _buildProgressBar(),
            // chewieController.allowMuting
            //     ? _buildMuteButton(controller)
            //     : Container(),
            chewieController.allowFullScreen
                ? _buildExpandButton()
                : Container(),
          ],
        ),
      ),
    );
  }

  GestureDetector _buildExpandButton() {
    return GestureDetector(
      onTap: _onExpandCollapse,
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: Duration(milliseconds: 300),
        child: Container(
          height: barHeight,
          margin: EdgeInsets.only(right: 12.0),
          padding: EdgeInsets.only(
            left: 8.0,
            right: 8.0,
          ),
          child: Center(
            child: ImageIcon(
              AssetImage(chewieController.isFullScreen
                  ? "images/fullscreen_exit.png"
                  : "images/fullscreen_enter.png"),
              size: 32.0,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Expanded _buildHitArea() {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_latestValue != null && _latestValue.isPlaying) {
            if (_displayTapped) {
              setState(() {
                _hideStuff = true;
              });
            } else
              _cancelAndRestartTimer();
          } else {
            _playPause();

            setState(() {
              _hideStuff = true;
            });
          }
        },
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: AnimatedOpacity(
              opacity:
                  _latestValue != null && !_latestValue.isPlaying && !_dragging
                      ? 1.0
                      : 0.0,
              duration: Duration(milliseconds: 300),
              child: GestureDetector(
                child: Container(
                  // decoration: BoxDecoration(
                  //   color: Theme.of(context).dialogBackgroundColor,
                  //   borderRadius: BorderRadius.circular(48.0),
                  // ),
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: ImageIcon(
                      AssetImage("images/video_play.png"),
                      size: 64.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildMuteButton(
    VideoPlayerController controller,
  ) {
    return GestureDetector(
      onTap: () {
        _cancelAndRestartTimer();

        if (_latestValue.volume == 0) {
          controller.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller.value.volume;
          controller.setVolume(0.0);
        }
      },
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: Duration(milliseconds: 300),
        child: ClipRect(
          child: Container(
            child: Container(
              height: barHeight,
              padding: EdgeInsets.only(
                left: 8.0,
                right: 8.0,
              ),
              child: ImageIcon(
                AssetImage((_latestValue != null && _latestValue.volume > 0)
                    ? "images/voice_ok.png"
                    : "images/voice_stop.png"),
                size: 32.0,
                color: Colors.white,
              ),
              // child: Icon(
              //   (_latestValue != null && _latestValue.volume > 0)
              //       ? Icons.volume_up
              //       : Icons.volume_off,
              //   color: lightColor,
              // ),
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildPlayPause(VideoPlayerController controller) {
    return GestureDetector(
      onTap: _playPause,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        margin: EdgeInsets.only(left: 8.0, right: 4.0),
        padding: EdgeInsets.only(
          left: 2.0,
          right: 12.0,
        ),
        child: ImageIcon(
          AssetImage(controller.value.isPlaying
              ? "images/video_stop.png"
              : "images/video_play.png"),
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  GestureDetector _buildPlayNext(VideoPlayerController controller) {
    return GestureDetector(
      onTap: _playNext,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        margin: EdgeInsets.only(left: 2.0, right: 8.0),
        padding: EdgeInsets.only(
          left: 2.0,
          right: 2.0,
        ),
        child: ImageIcon(
          AssetImage("images/video_next.png"),
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildPosition(Color iconColor) {
    final position = _latestValue != null && _latestValue.position != null
        ? _latestValue.position
        : Duration.zero;
    final duration = _latestValue != null && _latestValue.duration != null
        ? _latestValue.duration
        : Duration.zero;

    return Padding(
      padding: EdgeInsets.only(right: 20.0),
      child: Text(
        '${formatDuration(position)} / ${formatDuration(duration)}',
        style: TextStyle(fontSize: 11.0, color: lightColor),
      ),
    );
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    _initialSwipeOffset = details.globalPosition;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    _finalSwipeOffset = details.globalPosition;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_initialSwipeOffset != null) {
      final offsetDifference = _initialSwipeOffset.dx - _finalSwipeOffset.dx;
      if (offsetDifference > 0) {
        if (controller.value.isPlaying) {
          controller.position.then(
              (value) => {controller.seekTo(value - Duration(seconds: 5))});
        }
      } else {
        if (controller.value.isPlaying) {
          controller.position.then(
              (value) => {controller.seekTo(value + Duration(seconds: 5))});
        }
      }
    }
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();
    _startHideTimer();

    setState(() {
      _hideStuff = false;
      _displayTapped = true;
    });
  }

  Future<Null> _initialize() async {
    controller.addListener(_updateState);
    _colorModel = Store.value<ColorModel>(context);
    _updateState();

    if ((controller.value != null && controller.value.isPlaying) ||
        chewieController.autoPlay) {
      _startHideTimer();
    }

    if (chewieController.showControlsOnInitialize) {
      _initTimer = Timer(Duration(milliseconds: 200), () {
        setState(() {
          _hideStuff = false;
        });
      });
    }
  }

  void _onExpandCollapse() {
    setState(() {
      _hideStuff = true;

      chewieController.toggleFullScreen();
      _showAfterExpandCollapseTimer = Timer(Duration(milliseconds: 300), () {
        setState(() {
          _cancelAndRestartTimer();
        });
      });
    });
  }

  void _playNext() {
    eventBus.fire(new PlayEvent("name"));
  }

  void _playPause() {
    bool isFinished = _latestValue.position >= _latestValue.duration;

    setState(() {
      if (controller.value.isPlaying) {
        _hideStuff = false;
        _hideTimer?.cancel();
        controller.pause();
      } else {
        _cancelAndRestartTimer();

        if (!controller.value.initialized) {
          controller.initialize().then((_) {
            controller.play();
          });
        } else {
          if (isFinished) {
            controller.seekTo(Duration(seconds: 0));
          }
          controller.play();
        }
      }
    });
  }

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _hideStuff = true;
      });
    });
  }

  void _updateState() {
    setState(() {
      _latestValue = controller.value;
    });
  }

  Widget _buildProgressBar() {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: _hideStuff ? 0 : 10.0),
        child: MaterialVideoProgressBar(
          controller,
          onDragStart: () {
            setState(() {
              _dragging = true;
            });

            _hideTimer?.cancel();
          },
          onDragEnd: () {
            setState(() {
              _dragging = false;
            });

            _startHideTimer();
          },
          colors: chewieController.materialProgressColors ??
              ChewieProgressColors(
                playedColor: _colorModel.theme.primaryColor,
                handleColor: lightColor,
                bufferedColor: Colors.white60,
                backgroundColor: Colors.white24,
              ),
        ),
      ),
    );
  }
}
