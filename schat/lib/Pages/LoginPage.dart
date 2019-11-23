import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_camera_ml_vision/flutter_camera_ml_vision.dart';
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:schat/Helper/ColorMap.dart';
import 'package:schat/Helper/Constants.dart';
import 'package:schat/Helper/Helper.dart';
import 'package:schat/Widgets/PatternProgressWidget.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:schat/main.dart';
import 'package:sprintf/sprintf.dart';
import 'package:image/image.dart' as imgLib;

class LoginPage extends StatefulWidget {
  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  String code;
  String token;
  int _rightTemp = 0;
  int _leftTemp = 0;
  int _count = 1; //인증을 해야할 회수
  String mUserMsg = "";
  bool _isInitProcess = true; //패턴인식공정이 시작되였는지 판단, true: 아직 시작되지 않음, false : 시작됨
  int _countPattern = 4; //인식패턴개수
  List<int> stateList = [0, 0, 0, 0];
  List<int> patternList = [];

  final _scanKey = GlobalKey<CameraMlVisionState>();
  final _patternPageKey = GlobalKey<PatternProgressWidgetState>();
  bool _isCheckFace = false; //현재 얼굴인증도중인지 확인
  bool _isCheckPattern = false; //얼굴패턴인증이 시작되였는지 확인

  bool _isDone = false; // 모든공정이 끝났는지 확인하는 변수
  int _mProgress = 0;
  String _mProgresssMsg = "0%";
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
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    isIos = Platform.isIOS;
    _init();
  }

  _init() async {
    token = await MyApp.shareUtils.getString("token");
    code = await MyApp.shareUtils.getString("code");
    //인증상태가 미정이면 등록페지로 이동
    if (token == null || code == null) {
      Navigator.of(context).pushNamedAndRemoveUntil("start", (_) => false);
    }

    setState(() {
      mUserMsg = sprintf("Checking confirmation of %s users", [this.code]);
    });

    //패턴인식렬불러들이기
    String patternStr = await MyApp.shareUtils.getString("pattern");
    List<String> loop = patternStr.split(",");
    for (String item in loop) {
      patternList.add(int.parse(item));
    }
    //print(patternList);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _verifyImage(CameraImage image) async {
    try {
      if (_isCheckFace) return; //현재 인증작업중인지 확인
      _isCheckFace = true;
      String fileExtend = this.isIos ? ".bmp" : ".png";
      String filename = this.code + "_" + _count.toString();
      String path = (await getApplicationDocumentsDirectory()).path + "/auths/" + filename + fileExtend;
      File file = File(path);
      if (file.existsSync()) {
        Uint8List convert = this.isIos ? await convertImageIOS(image) : await convertImageAndroid(image);
        String authBase64 = base64Encode(file.readAsBytesSync());
        String compareBase64 = base64Encode(convert);

        FormData formData = new FormData.fromMap({'img_1': authBase64, 'img_2': compareBase64});
        var _dio = Dio();
        _dio.options.headers = {'user_id': Constants.FaceXUserID, 'Content-Type': "multipart/form-data"};
        Response response = await _dio.post(
          Uri.encodeFull(Constants.FaceXURL),
          data: formData,
        );
        if (this.mounted) {
          if (response.statusCode == 200) {
            var result = response.data;
            if (result['status'] == "ok") {
              if (double.parse(result['data']['confidence']) > 0.5) {
                _count--;
                _mProgress = 100;
                _mProgresssMsg = "100%";
                String fileinfo = (await getApplicationDocumentsDirectory()).path + "/auths/" + this.code + ".png";
                File cFile = File(fileinfo);
                if(!cFile.existsSync()){
                  cFile.createSync(recursive: true);
                }
                //cFile.writeAsBytes(imgLib.encodePng(imageConvert));
                cFile.writeAsBytes(convert);
                setState(() {});
                await Future.delayed(Duration(seconds: 2));
                setState(() {});
                _isCheckFace = false;
              } else {
                mUserMsg = "Unverified";
                _isCheckFace = false;
                setState(() {});
              }
            } else {
              mUserMsg = "Unverified";
              _isCheckFace = false;
              setState(() {});
            }
          }

        }
      }
    } on PlatformException catch (e) {
      debugPrint('$e');
      _isCheckFace = false;
    } on CameraException catch (e1) {
      debugPrint('$e1');
      _isCheckFace = false;
    } on TickerCanceled {
      _isCheckFace = false;
    }
  }

  Future<void> _processImage(Face face) async {
    if (_isCheckPattern) return;
    if (_isInitProcess) {
      //패턴인식의 시작일때
      Future.delayed(Duration(seconds: 1));
      mUserMsg = "Verifing your eye blink Pattern";
      setState(() {
        _isInitProcess = false;
      });
    }else{
      _isCheckPattern = true;
      if(_countPattern > 0){
        //패턴항목의 검사수가 남아있을떄
        if(face.leftEyeOpenProbability < 0.4){
          _checkRightEyeBlinkClose();
        }else if(face.leftEyeOpenProbability > 0.9){
          _checkRightEyeBlinkOpen();
        }

        if(face.rightEyeOpenProbability < 0.4){
          _checkLeftEyeBlinkClose();
        }else if(face.rightEyeOpenProbability > 0.9){
          _checkLeftEyeBlinkOpen();
        }
      }
      _isCheckPattern = false;
    }
  }


  _checkRightEyeBlinkOpen(){
    if (_rightTemp == 1){
      _rightTemp = 0;
      if(patternList[(4 - _countPattern)] == 0){ //패턴과 일치하는 경우에만
        stateList[(4 - _countPattern)] = 1;
        _countPattern--;
        _patternPageKey.currentState.checkResult(stateList);
        if(_countPattern == 0){
          setState(() {
            _isDone = true;
            mUserMsg = "Verified";
          });
        }
      }else{ //불일치일때
        _unverifyPattern();
      }
    }
  }

  _checkLeftEyeBlinkOpen(){
    if(_leftTemp == 1){
      _leftTemp = 0;
      if(patternList[(4 - _countPattern)] == 1) { //패턴과 일치하는 경우에만
        stateList[(4 - _countPattern)] = 1;
        _countPattern--;
        _patternPageKey.currentState.checkResult(stateList);
        if(_countPattern == 0){
          setState(() {
            _isDone = true;
            mUserMsg = "Verified";
          });
        }
      }else{ //불일치일때
        _unverifyPattern();
      }
    }
  }

  _unverifyPattern(){
    stateList = [0, 0, 0, 0];
    _countPattern = 4;
    _patternPageKey.currentState.checkResult(stateList);
  }


  _checkRightEyeBlinkClose() {
    if (_rightTemp == 0) {
      _rightTemp = 1;
    }
  }

  _checkLeftEyeBlinkClose() {
    if (_leftTemp == 0) {
      _leftTemp = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SafeArea(
        child: Container(
          constraints: BoxConstraints.expand(),
          decoration: BoxDecoration(color: ColorMap.backgroundColor),
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
                                            //인증회수가 남아있을때
                                            _verifyImage(image);
                                          } else {
                                            if (faces[0].rightEyeOpenProbability != null && faces[0].leftEyeOpenProbability != null) {
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
                    ),
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
                _mProgresssMsg,
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
                          Navigator.of(context).pushNamedAndRemoveUntil("home", (_) => false);
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
