import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:schat/Helper/ColorMap.dart';
import 'package:schat/Helper/ToastUtil.dart';
import 'package:schat/Model/EmitModel.dart';
import 'package:sprintf/sprintf.dart';
import 'package:schat/Helper/Constants.dart';

typedef Emit = void Function(String resCode, List<EmitModel> arguments);
typedef AcceptCall = void Function(String room);
typedef RejectCall = void Function(String room);

class InvitingModal extends StatefulWidget {
  final Key key;
  final int time;
  final String requestID;
  final String requestNote;
  final Emit emit;
  final String room;
  final AcceptCall acceptCall;
  final RejectCall rejectCall;
  final int inviteType;

  InvitingModal({this.key, @required this.inviteType, @required this.time, @required this.requestID, @required this.requestNote, @required this.room, @required this.emit, @required this.acceptCall, @required this.rejectCall}) : super(key: key);

  @override
  InvitingModalState createState() => InvitingModalState();
}

class InvitingModalState extends State<InvitingModal> {
  Timer mTimer;
  String showTime;
  int selectWidget = 0;
  String photo;

  @override
  void initState() {
    super.initState();
    this.widget.emit("req-image", [new EmitModel("to_user", this.widget.requestID)]);
    showTime = sprintf("%02d : %02d", [(this.widget.time / 60).floor(), this.widget.time % 60]);
    mTimer = Timer.periodic(Duration(seconds: 1), (Timer t) => updateState(t));
  }

  @override
  void dispose() {
    mTimer?.cancel();
    super.dispose();
  }

  Widget buildWidget(Size size) {
    Widget result;
    switch (this.selectWidget) {
      case 0: //show progress bar
        result = Positioned.fill(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
        break;
      case 1: //show photo
        result = Positioned.fill(
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: Center(
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: ClipOval(
                      child: Image.memory(
                        base64Decode(photo),
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: CircularPercentIndicator(
                    radius: 150,
                    lineWidth: 5,
                    animation: true,
                    percent: 1.0,
                    progressColor: ColorMap.progressColor,
                    backgroundColor: ColorMap.progressBackColor,
                    circularStrokeCap: CircularStrokeCap.round,
                    animationDuration: 4000,
                  ),
                ),
              )
            ],
          ),
        );
        break;
      case 2: //show chat info
        result = Positioned.fill(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(8.0))),
                child: Center(
                  child: Text(
                    this.widget.requestID,
                    style: TextStyle(color: Colors.black, fontSize: 18.0, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              SizedBox(
                height: 15,
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(8.0))),
                child: Center(
                  child: Text(
                    this.widget.requestNote,
                    style: TextStyle(color: Colors.black, fontSize: 18.0, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
        break;
    }
    return result;
  }

  //매 초마다 상태업데이트
  void updateState(Timer timer) {
    int secondRemain = this.widget.time - timer.tick;
    if (secondRemain < 0) {
      onFinish();
      return;
    }
    showTime = sprintf("%02d : %02d", [(secondRemain / 60).floor(), secondRemain % 60]);

    if (mounted) {
      setState(() {});
    }
  }

  Future<bool> onBackPressed() async {
    bool result = true;
    if(this.widget.inviteType == Constants.IsInvite){
      this.widget.rejectCall(this.widget.room);
      result = false;
    }else{
      result = true;
    }
    return result;
  }

  //
  void onFinish() {
    mTimer.cancel();
    Navigator.pop(context, Constants.RESULTOK);
  }

  //대화 상대방의 이미지를 받은 경우 해당 이미지 현지, 4초후 해당 대화요청 정보 현시
  void readyImage(String photoBase64String) {
    if (mounted) {
      this.photo = photoBase64String;
      Timer(Duration(milliseconds: 4000), () {
        if(mounted){
          setState(() {
            selectWidget = 2;
          });
        }
      });
      setState(() {
        selectWidget = 1;
      });
    }
  }

  //대화 상대방의 이미지 요청에 실패하는 경우 대화 요청 정보 현시
  void failedImage() {
    if(mounted){
      setState(() {
        selectWidget = 2;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: onBackPressed,
      child: Scaffold(
        body: SafeArea(
          child: Container(
            constraints: BoxConstraints.expand(),
            decoration: BoxDecoration(color: ColorMap.backgroundColor),
            padding: EdgeInsets.symmetric(vertical: 30, horizontal: 50),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Flexible(
                  flex: 1,
                  child: Container(
                    child: Center(
                      child: SizedBox(
                        width: size.width / 3,
                        height: size.width / 3,
                        child: FittedBox(
                          child: Image.asset(
                            "assets/invite_chat_logo.png",
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: Container(
                    constraints: BoxConstraints.expand(),
                    child: Stack(
                      children: <Widget>[
                        buildWidget(size),
                      ],
                    ),
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: Container(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Text("Remain Time: $showTime", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20.0)),
                        SizedBox(
                          height: 15,
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: RaisedButton(
                            onPressed: () {
                              this.widget.acceptCall(this.widget.room);
                            },
                            color: ColorMap.buttonColor,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(8.0), side: BorderSide(color: Colors.transparent)),
                            textColor: Colors.white,
                            highlightColor: ColorMap.buttonClickColor,
                            child: Text(
                              "Accept",
                              style: TextStyle(fontSize: 16.0),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: RaisedButton(
                            onPressed: () {
                              if(this.widget.inviteType == Constants.IsInvite){
                                this.widget.rejectCall(this.widget.room);
                              }else{
                                Navigator.of(context).pop();
                              }
                            },
                            color: ColorMap.buttonColor,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(8.0), side: BorderSide(color: Colors.transparent)),
                            textColor: Colors.white,
                            highlightColor: ColorMap.buttonClickColor,
                            child: Text(
                              "Reject",
                              style: TextStyle(fontSize: 16.0),
                            ),
                          ),
                        )
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
