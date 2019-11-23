import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:schat/Helper/Constants.dart';
import 'package:schat/Helper/ToastUtil.dart';
import 'package:schat/Modal/InvitingModal.dart';
import 'package:schat/Modal/SendingModal.dart';
import 'package:schat/Model/EmitModel.dart';
import 'package:schat/Model/ResJoinModel.dart';
import 'package:schat/Pages/ChatPage.dart';
import 'package:schat/Pages/subHome/ConnectPage.dart';
import 'package:schat/Pages/subHome/InvitePage.dart';
import 'package:schat/Pages/subHome/ModeSelectPage.dart';
import 'package:schat/main.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io;

import 'package:sharesdk_plugin/sharesdk_plugin.dart';
import 'package:sharesdk_plugin/sharesdk_interface.dart';
import 'package:sharesdk_plugin/sharesdk_map.dart';
import 'package:sharesdk_plugin/sharesdk_defines.dart';

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int selected = 0; //0 : mode select, 1 : invite Page, 2 : friendly page
  String token;
  String code;
  bool isInitiator = false;
  bool isIos = false;

  int inviteMode; // 0: invite code, 1 : use link
  String customId;
  String mRoom;

  GlobalKey modeSelectPageKey = GlobalKey();
  GlobalKey<InvitePageState> invitePageKey = GlobalKey<InvitePageState>();
  GlobalKey<ConnectPageState> connectPageKey = GlobalKey<ConnectPageState>();
  GlobalKey<InvitingModalState> requestModalKey = GlobalKey<InvitingModalState>();
  GlobalKey<SendingModalState> sendingModalKey = GlobalKey<SendingModalState>();

  bool isProgressDialog = false;
  bool isRequestDialog = false;

  int InviteType = 0; //0 : Invite-room을 통해 호출된 경우, //1 : 소셜공유를 통해 호출된 경우

  @override
  void initState() {
    super.initState();
    this.isIos = Platform.isIOS;
    init();
  }

  void init() async {
    this.token = await MyApp.shareUtils.getString("token");
    this.code = await MyApp.shareUtils.getString("code");
    //print(this.code);
    initMobSDK();
    initSocket();
  }

  initMobSDK(){
    ShareSDKRegister register = ShareSDKRegister();
    register.setupFacebook(Constants.FaceBookAppKey, Constants.FaceBookSecretKey, "FaceBook");
    register.setupTwitter(Constants.TwitterAppKey, Constants.TwitterSerectKey, "https://mob.com");
    register.setupKakao(Constants.KakaoAppKey, Constants.KakaoRestKey, "https://mob.com");
    SharesdkPlugin.regist(register);
  }

  @override
  void dispose() {
    clearSocket();
    super.dispose();
  }

  void initSocket() {
    //인증을 위한 이벤트
    MyApp.signalServer.socketIO.on("res-join", (data) => this.onJoin(data));

    //방생성요청에 대한 응답이벤트
    MyApp.signalServer.socketIO.on("res-create-room", (data) => this.onCreateRoom(data));

    //방가입요청에 대한 응답이벤트
    MyApp.signalServer.socketIO.on("res-join-room", (data) => this.onJoinRoom(data));

    //상대방에게 요청을 보내기 위한 이벤트
    MyApp.signalServer.socketIO.on("res-invite-room", (data) => this.onInviteRoom(data));

    //상대방의 통화거절
    MyApp.signalServer.socketIO.on("req-reject-invite-room", (data) => this.onReqRejectInviteRoom(data));

    //통화취소에 대한 요청
    MyApp.signalServer.socketIO.on("res-close-room", (data) => this.onResCloseRoom(data));

    //방에 련결됨
    MyApp.signalServer.socketIO.on("room-ready", (data) => this.onRoomReady(data));

    //상대방의 요청을 받기 위한 이벤트
    MyApp.signalServer.socketIO.on("req-invite-room", (data) => this.onReqInviteRoom(data));

    //요청을 받은후 요청에 대한 정보를 얻고 정상인 경우 Dialog 를 띄운다
    MyApp.signalServer.socketIO.on("res-query-room", (data) => this.onResQueryRoom(data));

    //통화거절에대한 응답
    MyApp.signalServer.socketIO.on("res-reject-invite-room", (data) => this.onResRejectRoom(data));

    //상대방에게 보낸 사진요청에 대한 응답
    MyApp.signalServer.socketIO.on("res-image", (data) => this.onResImage(data));

    //상대방이 보낸 사진에 대한 처리
    MyApp.signalServer.socketIO.on("res-send-image", (data) => this.onResSendImage(data));

    //사진 요청에 대한 처리
    MyApp.signalServer.socketIO.on("req-send-image", (data) => this.onReqSendImage(data));

    //지금은 사용하지 않음... 다중대화로 로직요구가 오는 경우에 사용할것으로 보임
    MyApp.signalServer.socketIO.on("req-close-room", (data) => this.onReqCloseRoom(data));

    this.emit("join", []);
  }

  //상대방에게 자기의 이미지 보내기
  void sendImage(dynamic data) async{
    String fileExtend = this.isIos ? ".bmp" : ".png";
    final path = (await getApplicationDocumentsDirectory()).path + "/auths/" + this.code + ".png";
    if(await io.File(path).exists()){
      io.File file = io.File(path);
      List<int> imageBytes = file.readAsBytesSync();
      this.emit("send-image", [
        new EmitModel("code", data['callee']),
        new EmitModel("photo", base64Encode(imageBytes))
      ]);
    }
  }

  void clearSocket() {
    MyApp.signalServer.socketIO.off("res-join");
    MyApp.signalServer.socketIO.off("res-room-create");
    MyApp.signalServer.socketIO.off("res-join-room");
    MyApp.signalServer.socketIO.off("res-invite-room");
    MyApp.signalServer.socketIO.off("req-reject-invite-room");
    MyApp.signalServer.socketIO.off("res-close-room");
    MyApp.signalServer.socketIO.off("room-ready");

    MyApp.signalServer.socketIO.off("req-invite-room");
    MyApp.signalServer.socketIO.off("res-query-room");
    MyApp.signalServer.socketIO.off("res-reject-invite-room");
    MyApp.signalServer.socketIO.off("req-close-room");

    MyApp.signalServer.socketIO.off("res-image");
    MyApp.signalServer.socketIO.off("res-send-image");
    MyApp.signalServer.socketIO.off("req-send-image");
  }

  Widget _buildTransitionsStack() {
    Widget result;
    switch (selected) {
      case 0: //Select mode screen
        result = ModeSelectPage(
          key: modeSelectPageKey,
          switchPageHandler: this.switchPageHandler,
        );
        break;
      case 1: //Invite screen
        result = InvitePage(
          key: invitePageKey,
          myCode: this.code,
          inviteRoomCreate: inviteRoomCreate,
          socialShare: _socialShare,
          backPress: subBackPress,
        );
        break;
      case 2: //Connect screen
        result = ConnectPage(
          key: connectPageKey,
          myCode: this.code,
          connectRoomCreate: connectRoomCreate,
          backPress: subBackPress,
        );
        break;
    }
    return result;
  }

  void subBackPress(){
    switchPageHandler(0);
  }

  void switchPageHandler(int index) {
    if (selected != index) {
      setState(() {
        selected = index;
      });
    }
  }

  void inviteModeChat() {
    if (this.inviteMode == 0) {
      this.emit("invite-room", [
        new EmitModel("room", this.mRoom),
        new EmitModel("callee", this.customId)
      ]);
    } else {
      if (selected == 1) {
        invitePageKey.currentState.createdRoom(this.mRoom);
      }
    }
  }

  void inviteRoomCreate(String notice, int timeout) {
    this.inviteMode = 1;
    this.createRoom(notice, timeout);
  }

  void connectRoomCreate(String custom, String notice, int timeout) {
    this.inviteMode = 0;
    this.customId = custom;
    prepareProgressDialog(timeout);
    this.createRoom(notice, timeout);
  }

  void prepareProgressDialog(int minutes) {
    if(!this.isProgressDialog){
      this.isProgressDialog = true;
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => SendingModal(
            key: sendingModalKey,
            time: minutes * 60,
            cancelCall: this.cancelCall,
          )));
    }

  }

  void dismissProgressDialog(){
    if(mounted && this.isProgressDialog){
      this.isProgressDialog = false;
      Navigator.of(context).pop("Progress Dialog");
    }
  }


  void prepareRequestDialog(int timeout, String master, String notice, String room){
    if(!this.isRequestDialog){
      print(room);
      this.isRequestDialog = true;
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => InvitingModal(
            key: this.requestModalKey,
            time: timeout,
            requestID: master,
            requestNote: notice,
            room: room,
            emit: this.emit,
            acceptCall: this.acceptCall,
            rejectCall: this.rejectCall,
            inviteType: this.InviteType,
          )));
    }
  }

  void dismissRequestDialog(){
    if(this.isRequestDialog && mounted){
      this.isRequestDialog = false;
      Navigator.of(context).pop("Request Dialog");
    }
  }

  void createRoom(String notice, int timeout) {
    this.isInitiator = true;
    this.emit("create-room", [
      new EmitModel("notice", notice),
      new EmitModel("timeout", timeout)
    ]);
  }

  void cancelCall() {
    print("cancelCall");
    if (this.mRoom != null && this.mRoom != "") {
      this.emit("close-room", [
        new EmitModel("room", this.mRoom)
      ]);
    }
  }

  void serverRoomQuery(String room, int type) {
    InviteType = type;
    this.emit("query-room", [
      new EmitModel("room", room)
    ]);
  }

  void joinRoom(String room) {
    this.mRoom = room;
    this.emit("join-room", [
      new EmitModel("room", room)
    ]);
  }

  //대화 요청 거절
  void rejectCall(String room){
    this.isInitiator = false;
    this.emit("reject-invite-room", [
      new EmitModel("room", room)
    ]);
  }

  //대화수락
  void acceptCall(String room){
    this.isInitiator = false;
    joinRoom(room);
  }

  Future<bool> onBackPressed() async {
    if (selected == 0) {
      return showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text("Do you really want to exit the app?"),
                actions: <Widget>[
                  FlatButton(
                    child: Text("No"),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                  FlatButton(
                    child: Text("Yes"),
                    onPressed: () => SystemChannels.platform.invokeMethod('SystemNavigator.pop'),
                  )
                ],
              ));
    } else {
      setState(() {
        selected = 0;
      });
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onBackPressed,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: _buildTransitionsStack(),
        ),
      ),
    );
  }

  void emit(String resCode, List<EmitModel> arguments) {
    arguments.add(new EmitModel("token", token));
    Map<String, dynamic> params = new HashMap();
    for(int i = 0; i < arguments.length; i++){
      EmitModel item = arguments[i];
      params[item.key] = item.value;
    }
    MyApp.signalServer.socketIO.emit(resCode, [params]);
  }

  //"res-join" Callback
  void onJoin(dynamic data){ //{result: OK, user: {id: 8, code: 2ee2c0, token: 4b3cd49ca9d0aa02c1fece11cbcacd9472f6039d0e5ef8b735147768394f5b92, status: 0, created_at: 1571641021, accessed_at: 1571642261}}
    print("onJoined");
    if (data['result'] == "OK") {
      ResJoinModel resJoinModel = new ResJoinModel(data['user']['code'], data['user']['token']);
      this.token = resJoinModel.token;
      this.code = resJoinModel.code;
      MyApp.shareUtils.setString("token", resJoinModel.token);
      //소셜공유를 통하여 앱이 호출된 경우 해당 방에 접속시도
      if (MyApp.requestID != null) {
        serverRoomQuery(MyApp.requestID, Constants.IsShare);
        MyApp.requestID = null;
      }
    } else {
      //응답이 실패인 경우 보관된 유저정보를 지우고 인증절차를 다시 걸치도록 한다.
      MyApp.shareUtils.setString("token", null);
      MyApp.shareUtils.setString("code", null);
      Navigator.pushNamedAndRemoveUntil(context, "start", (_) => false);
    }
  }

  //"res-create-room" Callback
  void onCreateRoom(dynamic data){ //{result: OK, room: 85dc60139df2}
    print("res-create-room");
    if (data['result'] == "OK") {
      joinRoom(data['room']);
    } else {
      dismissProgressDialog();
      ToastUtil.showToast("Failed created room, Please try again later");
    }
  }

  //"res-join-room" Callback
  void onJoinRoom(dynamic data){
    print("res-join-room");
    if (data['result'] == "OK") {
      //방가입 성공
      inviteModeChat();
    } else {
      //방가입 실패
      dismissProgressDialog();
      cancelCall();
      ToastUtil.showToast("Failed join room. Please try again later");
    }
  }

  //"res-invite-room" Callback
  void onInviteRoom(dynamic data){
    print("res-invite-room");
    if(data['result'] == "OK"){
      if(mounted && this.isProgressDialog){
        this.sendingModalKey.currentState.onReady();
      }
    }else{
      dismissProgressDialog();
      cancelCall();
      String error = "";
      switch(data['reason']){
        case 999:
          error = "Invalid Request";
          break;
        case 998:
          error = "Invalid room code";
          break;
        case 997:
          error = "Invalid information";
          break;
        case 99:
          error = "Not logined";
          break;
        case 996:
          error = "Failed join room. Please try again later";
          break;
      }
      ToastUtil.showToast(error);
    }
  }

  //"req-reject-invite-room" Callback
  void onReqRejectInviteRoom(dynamic data){
    print("req-reject-invite-room");
    this.cancelCall();
    ToastUtil.showToast("Rejected call");
  }

  //"res-close-room" Callback
  void onResCloseRoom(dynamic data){
    print("res-close-room");
    this.mRoom = null;
    if (data['result'] == "OK") {
      this.dismissProgressDialog();
      ToastUtil.showToast("Canceled call");
    } else {
      String error = "";
      switch (data['reason']) {
        case 999:
          error = "Invalid Request";
          break;
        case 998:
          error = "Invalid room code";
          break;
        case 997:
          error = "Invalid information";
          break;
      }
      ToastUtil.showToast(error);
    }
  }

  //"room-ready" Callback
  void onRoomReady(dynamic data){ //{result: OK, room: 03737d8e7dbb, users: [b8e951, 09c34f]}
    print("room-ready");
    print(data);
    dismissRequestDialog();
    dismissProgressDialog();
    if(data['result'] == "OK"){
      var users = data['users'] as List;
      String room = data['room'];
      if(this.code == users[0]){
        startChat(room, users[1]);
      }else{
        startChat(room, users[0]);
      }
    }
  }


  //"req-invite-room" Callback
  void onReqInviteRoom(dynamic data){ ////{caller: 2185b6, room: 1a5e0a656346, notice: bh, timeout: 540}
    print("req-invite-room");
    serverRoomQuery(data['room'], Constants.IsInvite);
  }

  //"res-query-room" Callback
  void onResQueryRoom(dynamic data){
    print("res-query-room");
    if (data['result'] == "OK") {
      if (data['room']['timeout'] != 0) {
        prepareRequestDialog(data['room']['timeout'], data['room']['master'], data['room']['notice'], data['room']['code']);
      } else {
        ToastUtil.showToast("Can not join room because limited wait time");
      }
    } else {
      String error = "";
      switch (data['reason']) {
        case 999:
          error = "Invalid Request";
          break;
        case 998:
          error = "Invalid Room code";
          break;
        case 997:
          error = "Invalid Information";
          break;
      }

      ToastUtil.showToast(error);
    }
  }

  //"res-reject-invite-room" Callback
  void onResRejectRoom(dynamic data){
    print("res-reject-invite-room");
    if(data['result'] == "OK"){
      if(mounted && this.isRequestDialog){
        dismissRequestDialog();
      }
    }else{
      String error = "";
      switch(data['reason']){
        case 999:
          error = "Invalid request";
          break;
        case 998:
          error = "Invalid room code";
          break;
        case 997:
          error = "Invalid information";
          break;
      }
      ToastUtil.showToast(error);
    }
  }

  //"res-image" Callback
  void onResImage(dynamic data){
    print("res-image");
    if(mounted && data['result'] != "OK" && isRequestDialog){
      this.requestModalKey.currentState.failedImage();
    }
  }

  //"res-send-image" Callback
  void onResSendImage(dynamic data){
    print("res-send-image");
    if(mounted && isRequestDialog){
      requestModalKey.currentState.readyImage(data['photo']);
    }
  }

  //"req-send-image" Callback
  void onReqSendImage(dynamic data){
    print("req-send-image");
    sendImage(data);
  }

  //"req-close-room" Callback
  void onReqCloseRoom(dynamic data){
    print("req-close-room");
    dismissRequestDialog();
  }

  //대화 시작
  void startChat(String room, String custom) async{
    print(room);
    print(custom);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ChatPage(
        room: room,
        custom: custom,
        isInitiator: this.isInitiator,
      )
    ));
  }


  //소셜 공유
  void _socialShare(int type, int minute) async{
    String shareContent = Constants.ShareURL + "call/" + this.mRoom;
    SSDKMap params = SSDKMap()..setGeneral("Invite You", shareContent, null, null, null, null, null, null, null, SSDKContentTypes.text);
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
      if(result["state"] == 1){ // 성공으로 돌아오는 경우에만
        setState(() {
          selected = 0;
        });
        prepareProgressDialog(minute);
        Timer(Duration(seconds: 1), (){
          if(mounted && this.isProgressDialog){
            this.sendingModalKey.currentState.onReady();
          }
        });
      }
    }
  }
}
