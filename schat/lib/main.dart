import 'package:flutter/material.dart';
import 'package:schat/Pages/HomePage.dart';
import 'package:schat/Pages/LoginPage.dart';
import 'package:schat/Pages/StartPage.dart';
import 'package:schat/Pages/TestPage.dart';
import 'package:schat/Pages/subHome/InvitePage.dart';
import 'package:wakelock/wakelock.dart';
import 'package:schat/Helper/SignalServer.dart';
import 'package:schat/Pages/SplashPage.dart';

import 'Helper/SharePreferenceUtil.dart';

void main(){
  runApp(MyApp());
  initWakeLock();
}

void initWakeLock() async{
  bool isEnable = await Wakelock.isEnabled;
  if(!isEnable){
    Wakelock.enable();
  }
}

enum SocketState  {
  Init,
  Connecting,
  Connected,
  Disconnected,
  Error,
  Timeout
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  static SharePreferenceUtil shareUtils;
  static SocketState mSocketState = SocketState.Init;
  static SignalServer signalServer;
  static String requestID;


  @override
  Widget build(BuildContext context) {
    shareUtils = new SharePreferenceUtil();
    shareUtils.instance();
    signalServer = new SignalServer(
      connectingHandler: this.onConnecting,
      connectHandler: this.onConnected,
      disconnectHandler: this.onDisconnected,
      connectErrorHandler: this.onConnectError,
      errorHandler: this.onError,
      timeoutHandler: this.onTimeout
    );
    signalServer.connectServer();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SChat',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      routes: <String, WidgetBuilder>{
        "/" : (BuildContext context) => SplashPage(),
        "start" : (BuildContext context) => StartPage(),
        "login" : (BuildContext context) => LoginPage(),
        "home" : (BuildContext context) => HomePage(),
        "invite" : (BuildContext context) => InvitePage(),
        "test" : (BuildContext context) => TestPage()
      },
      initialRoute: "/",
    );
  }

  void onConnected(dynamic data){
    MyApp.mSocketState = SocketState.Connected;
  }

  void onDisconnected(){
    MyApp.mSocketState = SocketState.Disconnected;
  }

  void onConnectError(){
    MyApp.mSocketState = SocketState.Error;
  }

  void onError(){
    MyApp.mSocketState = SocketState.Error;
  }

  void onTimeout(){
    MyApp.mSocketState = SocketState.Timeout;
  }

  void onConnecting(){
    MyApp.mSocketState = SocketState.Connecting;
  }
}

