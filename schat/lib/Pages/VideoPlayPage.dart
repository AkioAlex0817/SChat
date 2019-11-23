import 'package:flutter/material.dart';
import 'package:schat/Helper/ColorMap.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class VideoPlayPage extends StatefulWidget {
  final String filePath;

  VideoPlayPage({this.filePath});

  @override
  VideoPlayPageState createState() => VideoPlayPageState();
}

class VideoPlayPageState extends State<VideoPlayPage> {
  VideoPlayerController playerController;
  VoidCallback listener;
  Duration allDuration;
  Duration currentDuration;

  @override
  void initState() {
    super.initState();
    listener = () {
      setState(() {
        currentDuration = playerController.value.position;
      });
    };
    playerController = VideoPlayerController.file(new File(this.widget.filePath))
      ..addListener(listener)
      ..initialize().then((_) {
        allDuration = playerController.value.duration;
        currentDuration = playerController.value.position;
        playerController.play();
        setState(() {});
      });
  }

  @override
  void dispose() {
    playerController?.dispose();
    super.dispose();
  }

  forward() {
    Duration current = playerController.value.position;
    Duration all = playerController.value.duration;
    setState(() {
      playerController.seekTo(Duration(hours: current.inHours, minutes: current.inMinutes, seconds: current.inSeconds + 5 > all.inSeconds ? all.inSeconds : current.inSeconds + 5));
    });
  }

  backward() {
    Duration current = playerController.value.position;
    setState(() {
      playerController.seekTo(Duration(hours: current.inHours, minutes: current.inMinutes, seconds: current.inSeconds - 5 < 0 ? 0 : current.inSeconds - 5));
    });
  }

  videoPlay(){
    if(playerController.value.position == allDuration){
      playerController.seekTo(Duration(hours: 0, minutes: 0, seconds: 0));
    }
    playerController.play();
  }

  videoStop(){
    playerController.pause();
  }

  String _printDuration(Duration duration) {
    String twoDigits(int n) {
      if (n >= 10) return "$n";
      return "0$n";
    }

    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60) + 60 * duration.inHours);
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: ColorMap.backgroundColor,
          ),
          child: Center(
            child: playerController.value.initialized
                ? AspectRatio(
                    aspectRatio: playerController.value.aspectRatio,
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(child: VideoPlayer(playerController)),
                        Positioned(
                          left: 5,
                          right: 5,
                          bottom: 5,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.all(Radius.circular(15.0))),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 5),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        InkWell(
                                          onTap: () {
                                            backward();
                                          },
                                          child: Icon(
                                            Icons.replay_5,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              playerController.value.isPlaying ? videoStop() : videoPlay();
                                            });
                                          },
                                          child: Icon(
                                            playerController.value.isPlaying ? Icons.pause : Icons.play_arrow,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            forward();
                                          },
                                          child: Icon(
                                            Icons.forward_5,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 5,
                                  child: Container(
                                    child: VideoProgressIndicator(
                                      playerController,
                                      allowScrubbing: true,
                                      padding: EdgeInsets.symmetric(horizontal: 2),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    child: Center(
                                      child: Text(
                                        _printDuration(currentDuration) + "/" + _printDuration(allDuration),
                                        style: TextStyle(color: Colors.white, fontSize: 14.0),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                : CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}
