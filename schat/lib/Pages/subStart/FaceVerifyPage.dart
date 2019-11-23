import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/services.dart';
import 'package:flutter_camera_ml_vision/flutter_camera_ml_vision.dart';
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:schat/Helper/ColorMap.dart';
import 'package:schat/Helper/Helper.dart';
import 'package:schat/Widgets/PatternProgressWidget.dart';
import 'package:sprintf/sprintf.dart';
import 'package:image/image.dart' as imgLib;

typedef SignInConfirm = void Function(List<int> patterns);

class FaceVerifyPage extends StatefulWidget {
  final String code;
  final SignInConfirm signInConfirm;

  FaceVerifyPage({this.code, this.signInConfirm});

  @override
  FaceVerifyPageState createState() => FaceVerifyPageState();
}

class FaceVerifyPageState extends State<FaceVerifyPage> {
  int _rightTemp = 0;
  int _leftTemp = 0;
  int _count = 1; //인증파일 저장개수
  String mUserMsg = "";
  bool _isInitProcess = true;

  int _countPattern = 4; //패턴인식개수
  List<int> stateList = [0, 0, 0, 0];
  List<int> patternList = [];
  final _scanKey = GlobalKey<CameraMlVisionState>();
  final _patternPageKey = GlobalKey<PatternProgressWidgetState>();
  bool _isSaving = false;

  bool _isDone = false;
  int _mProgress = 0;
  String _mProgressMsg = "0%";

  bool isIos = false;

  CameraLensDirection _cameraLensDirection = CameraLensDirection.front;
  FaceDetector _detector = FirebaseVision.instance.faceDetector(FaceDetectorOptions(
    enableClassification: true,
    enableTracking: true,
    mode: FaceDetectorMode.fast,
    enableContours: true,
    enableLandmarks: true,
  ));

  @override
  void initState() {
    super.initState();
    mUserMsg = sprintf("Checking confirmation of %s users", [this.widget.code]);
    isIos = Platform.isIOS;
    _init();
  }

  //이미 인증에 사용하는 파일이 있으면 전부 삭제
  _init() async {
    String delPath = (await getApplicationDocumentsDirectory()).path + "/auths/";
    final dir = Directory(delPath);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  _checkRightEyeBlinkClose() {
    if (_rightTemp == 0) {
      _rightTemp = 1;
    }
  }

  _checkRightEyeBlinkOpen() {
    if (_rightTemp == 1) {
      _rightTemp = 0;
      stateList[(4 - _countPattern)] = 1;
      patternList.add(0);
      _countPattern--;
      if (mounted) {
        _patternPageKey.currentState.checkResult(stateList);
        if (_countPattern == 0) {
          setState(() {
            _isDone = true;
            mUserMsg = "Thanks for your verify";
          });
        }
      }
    }
  }

  _checkLeftEyeBlinkClose() {
    if (_leftTemp == 0) {
      _leftTemp = 1;
    }
  }

  _checkLeftEyeBlinkOpen() {
    if (_leftTemp == 1) {
      _leftTemp = 0;
      stateList[(4 - _countPattern)] = 1;
      patternList.add(1);
      _countPattern--;
      if (mounted) {
        _patternPageKey.currentState.checkResult(stateList);
        if (_countPattern == 0) {
          setState(() {
            _isDone = true;
            mUserMsg = "Thanks for your verify";
          });
        }
      }
    }
  }

  _savingImage(CameraImage image) async {
    try {
      if (_isSaving) return;
      _isSaving = true;
      String fileExtend = this.isIos ? ".bmp" : ".png";
      String filename = this.widget.code + "_" + _count.toString();
      String path = (await getApplicationDocumentsDirectory()).path + "/auths/" + filename + fileExtend;
      File file = File(path);
      if(!file.existsSync()){
        file.createSync(recursive: true);
      }
      Uint8List convert = this.isIos ? await convertImageIOS(image) : await convertImageAndroid(image);
      await file.writeAsBytes(convert);
      await Future.delayed(Duration(seconds: 1));
      _count--;
      _mProgress = 100;
      _mProgressMsg = "100%";
      if(_count == 0){ //검증이 완료된후 사진보관
        String fileinfo = (await getApplicationDocumentsDirectory()).path + "/auths/" + this.widget.code + fileExtend;
        File cFile = File(fileinfo);
        if(!cFile.existsSync()){
          cFile.createSync(recursive: true);
        }
        cFile.writeAsBytes(convert);
      }
      setState(() {});
      await Future.delayed(Duration(seconds: 2));
      setState(() {});
      _isSaving = false;
    } on PlatformException catch (e) {
      _isSaving = false;
      debugPrint('$e');
    } on CameraException catch(e1){
      _isSaving = false;
      debugPrint('$e1');
    }
  }

  String _getPatternText() {
    String result = "";
    if (patternList.length > 0) {
      for (int i = 0; i < patternList.length; i++) {
        if (patternList[i] == 0) {
          result = result + "Right";
        } else {
          result = result + "Left";
        }
        if (i < patternList.length - 1) {
          result = result + ", ";
        }
      }
    }
    return result;
  }

  _processImage(Face face) async {
    if (_isSaving) return;
    if (_isInitProcess) {
      //패턴인식의 시작일때
      Future.delayed(Duration(seconds: 1));
      mUserMsg = "Checking your eye blink pattern";
      setState(() {
        _isInitProcess = false;
      });
    } else {
      if (_countPattern > 0) {
        //패턴항목의 수가 남아있을때
        if (face.leftEyeOpenProbability < 0.4) {
          _checkRightEyeBlinkClose();
        } else if (face.leftEyeOpenProbability > 0.9) {
          _checkRightEyeBlinkOpen();
        }

        if (face.rightEyeOpenProbability < 0.4) {
          _checkLeftEyeBlinkClose();
        } else if (face.rightEyeOpenProbability > 0.9) {
          _checkLeftEyeBlinkOpen();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SafeArea(
        child: Container(
          constraints: BoxConstraints.expand(),
          decoration: BoxDecoration(
            color: ColorMap.backgroundColor,
          ),
          padding: EdgeInsets.symmetric(vertical: 30, horizontal: 30),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: width / 3,
                height: width / 3,
                child: FittedBox(
                  child: Image.asset(
                    "assets/face_detect.png",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                mUserMsg,
                style: TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.w700),
              ),
              SizedBox(
                height: 10,
              ),
              !_isDone
                  ? Container(
                      width: width / 3 * 2,
                      height: width / 3 * 2,
                      constraints: BoxConstraints(minWidth: width / 3 * 2, minHeight: width / 3 * 2),
                      child: Stack(
                        children: <Widget>[
                          Positioned.fill(
                            child: Container(
                              constraints: BoxConstraints.expand(),
                              padding: EdgeInsets.all(5),
                              child: ClipOval(
                                child: OverflowBox(
                                  alignment: Alignment.center,
                                  child: FittedBox(
                                    fit: BoxFit.fitWidth,
                                    child: Container(
                                      width: width / 3 * 2,
                                      height: width / 3 * 2,
                                      child: CameraMlVision<List<Face>>(
                                        key: _scanKey,
                                        cameraLensDirection: _cameraLensDirection,
                                        detector: _detector.processImage,
                                        onResult: (faces, image) {
                                          if (faces == null || faces.isEmpty || !mounted) {
                                            return;
                                          }
                                          if (_count > 0 && faces[0].rightEyeOpenProbability != null) {
                                            _savingImage(image);
                                          } else {
                                            if(faces[0].rightEyeOpenProbability != null && faces[0].leftEyeOpenProbability != null){
                                              _processImage(faces[0]);
                                            }
                                          }
                                        },
                                        onDispose: () {
                                          _detector.close();
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: CircularPercentIndicator(
                              radius: (width / 3 * 2) - 5,
                              lineWidth: 5,
                              animation: true,
                              animationDuration: 2000,
                              percent: _mProgress / 100,
                              progressColor: ColorMap.progressColor,
                              backgroundColor: ColorMap.progressBackColor,
                              circularStrokeCap: CircularStrokeCap.round,
                            ),
                          )
                        ],
                      ),
                    )
                  : Container(
                      width: width / 3 * 2,
                      height: width / 3 * 2,
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              _getPatternText(),
                              style: TextStyle(color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.w700,),
                              textAlign: TextAlign.center,
                            )
                          ],
                        ),
                      )),
              SizedBox(
                height: 50,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: !_isInitProcess
                      ? PatternProgressWidget(
                          key: _patternPageKey,
                          status: this.stateList,
                        )
                      : Container(),
                ),
              ),
              Text(
                _mProgressMsg,
                style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700),
              ),
              SizedBox(
                height: 10,
              ),
              _isDone
                  ? Text(
                      "Confirmed",
                      style: TextStyle(color: Colors.white, fontSize: 15.0, fontWeight: FontWeight.w700),
                    )
                  : Container(),
              SizedBox(
                height: 10,
              ),
              _isDone
                  ? SizedBox(
                      width: width / 2,
                      child: RaisedButton(
                        onPressed: () {
                          this.widget.signInConfirm(this.patternList);
                        },
                        color: ColorMap.buttonColor,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: BorderSide(color: Colors.transparent),
                        ),
                        textColor: Colors.white,
                        highlightColor: ColorMap.buttonClickColor,
                        child: Text(
                          "Next",
                          style: TextStyle(fontSize: 16.0),
                        ),
                      ),
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}
