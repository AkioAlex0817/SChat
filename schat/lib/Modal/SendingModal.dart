import 'dart:async';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:schat/Helper/ColorMap.dart';
import 'package:schat/Helper/ToastUtil.dart';
import 'package:sprintf/sprintf.dart';

typedef CancelCall = void Function();

class SendingModal extends StatefulWidget {
  final Key key;
  final int time;
  final CancelCall cancelCall;

  SendingModal({this.key, this.time, this.cancelCall}) : super(key: key);

  @override
  SendingModalState createState() => SendingModalState();
}

class SendingModalState extends State<SendingModal> {
  Timer mTimer;
  double mProgress = 1.0;
  String showTime = "00 : 00";
  String mTitle = "Please wait for server response";

  @override
  void initState() {
    super.initState();
    showTime = sprintf("%02d : %02d", [(this.widget.time / 60).floor(), this.widget.time % 60]);
  }

  void updateState(Timer timer) {
    int secondRemain = this.widget.time - timer.tick;
    if (secondRemain < 0) {
      ToastUtil.showToast("Failed connection. Please try again later.");
      onFinish();
      return;
    }
    mProgress = secondRemain / this.widget.time;
    int minutes = (secondRemain / 60).floor();
    int seconds = secondRemain % 60;
    this.showTime = sprintf("%02d : %02d", [minutes, seconds]);
    if (mounted) {
      setState(() {});
    }
  }

  void onFinish() {
    mTimer.cancel();
    this.widget.cancelCall();
    //Navigator.of(context).pop();
  }

  void onReady() {
    mTitle = "Please wait for other response";
    if (mTimer == null) {
      mTimer = Timer.periodic(Duration(seconds: 1), (Timer t) => updateState(t));
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    mTimer?.cancel();
    super.dispose();
  }

  Future<bool> onBackPressed() async {
    onFinish();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return WillPopScope(
      onWillPop: onBackPressed,
      child: Scaffold(
        body: SafeArea(
          child: Container(
            constraints: BoxConstraints.expand(),
            decoration: BoxDecoration(color: ColorMap.backgroundColor),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  width: width / 3 * 2,
                  height: width / 3 * 2,
                  child: Stack(
                    children: <Widget>[
                      Positioned.fill(
                        child: CircularPercentIndicator(
                          radius: (width / 3 * 2) - 10,
                          lineWidth: 5,
                          animation: false,
                          percent: mProgress,
                          progressColor: ColorMap.progressColor,
                          backgroundColor: ColorMap.progressBackColor,
                          circularStrokeCap: CircularStrokeCap.round,
                        ),
                      ),
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.all(50),
                          child: Image.asset(
                            "assets/sign_up_waiting.png",
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(
                  height: 30,
                ),
                Text(showTime, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20.0)),
                SizedBox(
                  height: 15,
                ),
                Text(mTitle, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20.0)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
