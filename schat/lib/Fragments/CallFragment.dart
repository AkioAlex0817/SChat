import 'dart:async';

import 'package:flutter/material.dart';
import 'package:schat/Helper/ColorMap.dart';
import 'package:sprintf/sprintf.dart';

typedef MessageFunction = void Function();
typedef SpeakerFunction = void Function(bool speaker);
typedef SoundFunction = void Function(bool sound);
typedef DisconnectVoiceCall = void Function();

class CallFragment extends StatefulWidget {
  final Key key;
  final String ID;
  final int duration;
  final MessageFunction messageFunction;
  final SpeakerFunction speakerFunction;
  final SoundFunction soundFunction;
  final DisconnectVoiceCall disconnectVoiceCall;

  CallFragment({this.key, @required this.ID, @required this.duration, @required this.messageFunction, @required this.speakerFunction, @required this.soundFunction, @required this.disconnectVoiceCall}) : super(key: key);

  @override
  CallFragmentState createState() => CallFragmentState();
}

class CallFragmentState extends State<CallFragment> {
  bool _isSoundOn = true;
  bool _isMaxSize = true;
  bool _isSpeaker = false;

  String showTime = "00 : 00";

  @override
  void initState() {
    super.initState();
    showTime = sprintf("%02d : %02d", [(this.widget.duration / 60).floor(), this.widget.duration % 60]);
  }

  void onTick(int tick){
    if(mounted){
      _updateState(tick);
    }
  }

  void _updateState(int tick) {
    if (mounted) {
      int minutes = (tick / 60).floor();
      int seconds = tick % 60;
      this.showTime = sprintf("%02d : %02d", [minutes, seconds]);
      setState(() {});
    }
  }

  finishFragment(){
    Navigator.of(context).pop(context);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<bool> _onBackPressed() async {
    _disconnectHandler();
    return false;
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
    this.widget.disconnectVoiceCall();
  }

  _messageHandler(){
    this.widget.messageFunction();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        body: SafeArea(
          child: Container(
            constraints: BoxConstraints.expand(),
            decoration: BoxDecoration(
              color: ColorMap.backgroundColor,
            ),
            padding: EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  this.widget.ID,
                  style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w700),
                ),
                SizedBox(
                  height: 40,
                ),
                SizedBox(
                  width: width / 3 * 2,
                  height: width / 3 * 2,
                  child: Stack(
                    children: <Widget>[
                      Positioned.fill(
                        child: Image.asset(
                          "assets/call_time_background.png",
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned.fill(
                        child: Center(
                          child: Text(
                            this.showTime,
                            style: TextStyle(color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.w700),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(
                  height: 60,
                ),
                SizedBox(
                  width: 60,
                  height: 60,
                  child: InkWell(
                    onTap: (){
                      _disconnectHandler();
                    },
                    child: ClipOval(
                      child: Container(
                        decoration: BoxDecoration(
                          color: ColorMap.rejectButtonColor,
                        ),
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.call_end, color: Colors.white, size: 30,),
                      )
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                SizedBox(
                  width: width / 3 * 2,
                  height: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: InkWell(
                          onTap: (){
                            _soundHandler();
                          },
                          child: ClipOval(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: ColorMap.buttonColor,
                                ),
                                padding: EdgeInsets.all(10),
                                child: Icon(_isSoundOn ? Icons.mic : Icons.mic_off, color: Colors.white, size: 30,),
                              )
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: InkWell(
                          onTap: (){
                            _messageHandler();
                          },
                          child: ClipOval(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: ColorMap.buttonColor,
                                ),
                                padding: EdgeInsets.all(10),
                                child: Icon(Icons.message, color: Colors.white, size: 30,),
                              )
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: InkWell(
                          onTap: (){
                            _speakHandler();
                          },
                          child: ClipOval(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: ColorMap.buttonColor,
                                ),
                                padding: EdgeInsets.all(10),
                                child: Icon(_isSpeaker ? Icons.volume_up : Icons.volume_off, color: Colors.white, size: 30,),
                              )
                          ),
                        ),
                      ),
                    ],
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
