import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:schat/Helper/ColorMap.dart';
import 'package:schat/Helper/Constants.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:schat/Helper/ToastUtil.dart';

import 'package:schat/Model/Message.dart';
import 'package:schat/Pages/LocationPage.dart';
import 'package:schat/Pages/VideoPlayPage.dart';
import 'package:image/image.dart' as imgLib;
import 'package:schat/main.dart';
import 'package:sharesdk_plugin/sharesdk_defines.dart';
import 'package:sharesdk_plugin/sharesdk_interface.dart';
import 'package:sharesdk_plugin/sharesdk_map.dart';


class TestPage extends StatefulWidget {
  @override
  TestPageState createState() => TestPageState();
}


class TestPageState extends State<TestPage> {
  List<Message> messages = [];

  File file;
  bool isVisible = true;
  String mText = "";
  Uint8List mImage;

  Future<bool> _backPressed() async {
    switchVisible();
    return false;
  }

  _openFile(BuildContext context) async {
    try {
      String path = await FilePicker.getFilePath(type: FileType.VIDEO);
      print(path);
      //var file = File(path);
      //int fileSize = file.lengthSync();
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => VideoPlayPage(
            filePath: path,
          )));
    } on PlatformException catch (error) {
      ToastUtil.showToast("Unsupported operation" + error.toString());
    }
  }

  mapTest() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => LocationPage()
    ));
  }

  checkUint8List(){
    Uint8List test = Uint8List(54);
    for(int i = 0; i < 54; i++){
      test[i] = i;
    }
    print(test);
    print(test.length);
    int num = (test.length / 10).round();
    print(num);
    print(test.length % 10);

    print(test.sublist(0, 10));
    print(test.sublist(50));
  }

  testRound(){
    double num = 10.5;
    print(num.round());
    print(num.floor());
  }

  void switchVisible(){
    setState(() {
      isVisible = !isVisible;
    });
  }

  _initImage() async{
    String filepath = (await getApplicationDocumentsDirectory()).path + "/auths/6d0136_4.png";
    print(filepath);
    this.file = File(filepath);
    imgLib.Image sximage = imgLib.decodePng(file.readAsBytesSync());
    //imgLib.Image convert = imgLib.copyRotate(sximage, Platform.isAndroid ? 0 : 0);
    print(sximage.width.toString() + ":::" + sximage.height.toString());

    String base64 = base64Encode(imgLib.encodePng(sximage));
    setState(() {
      mImage = imgLib.encodePng(sximage);
      isVisible = false;
    });
    FormData formData = new FormData.fromMap({
      'img_1' : base64,
      'img_2' : base64
    });
    var _dio = Dio();
    _dio.options.headers = {
      'user_id' : Constants.FaceXUserID,
      'Content-Type' : 'multipart/form-data'
    };
    Response response = await _dio.post(Constants.FaceXURL, data: formData,);
    print(response);
    /*if(response.statusCode == 200){
      print("Alex Ok");
    }else{
      print("Alex cancel");
    }*/
  }

  void _shareSDK(int type) async{
    String room = "dfdfdfdfdf";
    SSDKMap params = SSDKMap()..setGeneral("Invite You", Constants.ShareURL + "call/" + room, null, null, null, null, null, null, null, SSDKContentTypes.text);

    ShareSDKPlatform shareSDKPlatform;
    switch(type){
      case 0:
        shareSDKPlatform = ShareSDKPlatforms.sms;
        break;
      case 1:
        shareSDKPlatform = ShareSDKPlatforms.facebook;
        break;
      case 2:
        shareSDKPlatform = ShareSDKPlatforms.twitter;
        break;
      case 3:
        shareSDKPlatform = ShareSDKPlatforms.kakaoTalk;
        break;
    }

    if(shareSDKPlatform != null){
      var result = await SharesdkPlugin.share(shareSDKPlatform, params, null);
      switch(result["state"]){
        case 1: //success
          print("Success");
          break;
        case 2: //Fail
          print("Fail");
          break;
        case 3: //Cancel
          print("Cancel");
          break;
      }
    }


  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _backPressed,
      child: Scaffold(
        // The image is stored as a file on the device. Use the `Image.file`
        // constructor with the given path to display the image.
        body: Container(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                RaisedButton(
                  onPressed: (){
                    _shareSDK(0);
                  },
                  child: Text("SMS"),
                ),
                RaisedButton(
                  onPressed: (){
                    _shareSDK(1);
                  },
                  child: Text("FaceBook"),
                ),
                RaisedButton(
                  onPressed: (){
                    _shareSDK(2);
                  },
                  child: Text("Twitter"),
                ),
                RaisedButton(
                  onPressed: (){
                    _shareSDK(3);
                  },
                  child: Text("Kakao"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    //initIceSocket();
    //_initImage();
    // init();
  }

  void init(){
    String test = "http://schat.hmsoft.com/call/54545454";
    var result = Uri.parse(test);
    print(result.queryParameters);
  }

  void initIceSocket() {
    /*var client = new http.Client();
    client.get(Constants.signalServerURL + 'turn').then((response) {
      if (response.statusCode == 200) {
        var result = json.decode(response.body);
        for (var item in result['iceServers']) {
          print(item['urls']);
          print(item['username']);
          print(item['credential']);
        }
      }
    }, onError: (error) {
      print("Error : $error");
    });*/
  }
}
