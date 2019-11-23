import 'package:flutter/material.dart';
import 'package:flutter_webrtc/rtc_video_view.dart';
import 'package:schat/Helper/ColorMap.dart';

typedef MessageFunction = void Function();
typedef SpeakerFunction = void Function(bool speaker);
typedef SoundFunction = void Function(bool sound);
typedef DisconnectVideoCall = void Function();
typedef SwitchCamera = void Function();
typedef VideoFunction = void Function(bool video);

class VideoFragment extends StatefulWidget {
  final Key key;
  final RTCVideoRenderer localRenderer;
  final RTCVideoRenderer remoteRenderer;
  final MessageFunction messageFunction;
  final SpeakerFunction speakerFunction;
  final SoundFunction soundFunction;
  final DisconnectVideoCall disconnectVideoCall;
  final SwitchCamera switchCamera;
  final VideoFunction videoFunction;

  VideoFragment(
      {this.key,
      @required this.localRenderer,
      @required this.remoteRenderer,
      @required this.messageFunction,
      @required this.speakerFunction,
      @required this.soundFunction,
      @required this.disconnectVideoCall,
      @required this.switchCamera,
      @required this.videoFunction})
      : super(key: key);

  @override
  VideoFragmentState createState() => VideoFragmentState();
}

class VideoFragmentState extends State<VideoFragment> {
  bool _isSoundOn = true;
  bool _isMaxSize = true;
  bool _isSpeaker = false;
  bool _isVideoOn = true;


  @override
  void initState() {
    super.initState();
    this.widget.remoteRenderer.objectFit = RTCVideoViewObjectFit.RTCVideoViewObjectFitCover;
  }


  @override
  void dispose() {
    super.dispose();
  }

  finishFragment(){
    Navigator.of(context).pop(context);
  }

  _messageHandler(){
    this.widget.messageFunction();
  }

  _switchCameraHandler(){
    this.widget.switchCamera();
  }

  _videoHandler(){
    setState(() {
      _isVideoOn = !_isVideoOn;
    });
    this.widget.videoFunction(_isVideoOn);
  }

  _speakHandler(){
    setState(() {
      _isSpeaker = !_isSpeaker;
    });
    this.widget.speakerFunction(_isSpeaker);
  }

  _soundHandler(){
    setState(() {
      _isSoundOn = !_isSoundOn;
    });
    this.widget.soundFunction(_isSoundOn);
  }

  _disconnectHandler(){
    this.widget.disconnectVideoCall();
  }

  Future<bool> _onBackPressed() async {
    _disconnectHandler();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        body: SafeArea(
          child: Container(
            constraints: BoxConstraints.expand(),
            decoration: BoxDecoration(
              color: ColorMap.backgroundColor,
            ),
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Container(
                    constraints: BoxConstraints.expand(),
                    child: RTCVideoView(this.widget.remoteRenderer),
                  ),
                ),
                Positioned(
                  // message function
                  top: 30,
                  left: 42,
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: InkWell(
                      onTap: () {
                        _messageHandler();
                      },
                      child: ClipOval(
                        child: Container(
                          decoration: BoxDecoration(color: ColorMap.buttonColor),
                          child: FittedBox(
                            child: Image.asset(
                              "assets/chat.png",
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  // video function
                  top: 30,
                  right: 20,
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: InkWell(
                      onTap: () {
                        _videoHandler();
                      },
                      child: ClipOval(
                        child: Container(
                            decoration: BoxDecoration(color: ColorMap.buttonColor),
                            child: FittedBox(
                              child: Image.asset(
                                _isVideoOn ? "assets/camera_on.png" : "assets/camera_off.png",
                                fit: BoxFit.cover,
                              ),
                            )),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  // camera switch
                  top: 30,
                  right: 90,
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: InkWell(
                      onTap: () {
                        _switchCameraHandler();
                      },
                      child: ClipOval(
                        child: Container(
                            decoration: BoxDecoration(color: ColorMap.buttonColor),
                            child: FittedBox(
                              child: Image.asset(
                                "assets/camera_switch.png",
                                fit: BoxFit.cover,
                              ),
                            )),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 90,
                  right: 20,
                  child: SizedBox(
                    width: 95,
                    height: 144,
                    child: RTCVideoView(this.widget.localRenderer),
                  ),
                ),
                Positioned(
                  bottom: 50,
                  left: 30,
                  right: 30,
                  child: SizedBox(
                    height: 60,
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: InkWell(
                            onTap: () {
                              _soundHandler();
                            },
                            child: ClipOval(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: ColorMap.buttonColor,
                                ),
                                padding: EdgeInsets.all(10),
                                child: Icon(
                                  _isSoundOn ? Icons.mic : Icons.mic_off,
                                  color: Colors.white,
                                  size: 30.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: InkWell(
                            onTap: () {
                              _disconnectHandler();
                            },
                            child: ClipOval(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: ColorMap.rejectButtonColor,
                                ),
                                padding: EdgeInsets.all(10),
                                child: Icon(
                                  Icons.call_end,
                                  color: Colors.white,
                                  size: 30.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: InkWell(
                            onTap: () {
                              _speakHandler();
                            },
                            child: ClipOval(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: ColorMap.buttonColor,
                                ),
                                padding: EdgeInsets.all(10),
                                child: Icon(
                                  _isSpeaker ? Icons.volume_up : Icons.volume_off,
                                  color: Colors.white,
                                  size: 30.0,
                                ),
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
          ),
        ),
      ),
    );
  }
}
