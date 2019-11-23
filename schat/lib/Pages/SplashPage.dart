import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:schat/Helper/ToastUtil.dart';
import 'package:schat/main.dart';
import 'package:uni_links/uni_links.dart';

class SplashPage extends StatefulWidget {
  @override
  SplashPageState createState() => SplashPageState();
}

class SplashPageState extends State<SplashPage> {

  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage(
                      "assets/splash.png",
                    ),
                    fit: BoxFit.cover)),
            child: Column(
              children: <Widget>[
                Flexible(
                  flex: 2,
                  child: Container(
                    /*child: Center(
                      child: RaisedButton(
                        onPressed: (){
                          print(MyApp.mSocketState);
                        },
                        child: Text("onClick"),
                      ),
                    ),*/
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: Center(
                    child: SpinKitThreeBounce(
                      color: Color.fromARGB(255, 51, 181, 229),
                      size: 25.0,
                    ),
                  ),
                )
              ],
            )),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown
    ]);
    checkPermission();
  }


  void checkPermission() async{
    bool result = true;
    bool camera = await PermissionHandler().checkPermissionStatus(PermissionGroup.camera) == PermissionStatus.granted;
    bool storage = await PermissionHandler().checkPermissionStatus(PermissionGroup.storage) == PermissionStatus.granted;
    bool speech = await PermissionHandler().checkPermissionStatus(PermissionGroup.speech) == PermissionStatus.granted;
    bool location = await PermissionHandler().checkPermissionStatus(PermissionGroup.location) == PermissionStatus.granted;
    List<PermissionGroup> permissionList = [];
    if(!camera){
      permissionList.add(PermissionGroup.camera);
    }
    if(!storage){
      permissionList.add(PermissionGroup.storage);
    }
    if(!speech){
      permissionList.add(PermissionGroup.speech);
    }
    if(!location){
      permissionList.add(PermissionGroup.location);
    }
    if(permissionList.length > 0){
      Map<PermissionGroup, PermissionStatus> map = await PermissionHandler().requestPermissions(permissionList);
      for(PermissionStatus grant in map.values){
        if(grant != PermissionStatus.granted){
          result = false;
          break;
        }
      }
    }else{
      result = true;
    }

    if(result){
      prepareDeepLink();
    }else{
      SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    }
  }

  void prepareDeepLink() async{
    try{
      String initalLink = await getInitialLink();
      if(initalLink != null){
        String request_id = initalLink.substring(initalLink.lastIndexOf("/") + 1);
        MyApp.requestID = request_id;
      }

      prepareNextPage();
    }on PlatformException catch(error){
      print("Error InitialLink");
    }
  }

  void prepareNextPage(){
    print(MyApp.mSocketState);
    if(MyApp.mSocketState == SocketState.Connected){
      Timer(Duration(seconds: 4), () => nextPage());
    }else{
      if(MyApp.mSocketState != SocketState.Connecting && MyApp.mSocketState != SocketState.Init){
        ToastUtil.showToast("Can not connect to Server. Check Internet State.");
        Timer(Duration(seconds: 4), () => prepareNextPage());
      }
    }
  }

  Future nextPage() async{
    String code = await MyApp.shareUtils.getString("code");
    String token = await MyApp.shareUtils.getString("token");
    if(code == "" || token == ""){
      print("startPage");
      await Navigator.pushNamedAndRemoveUntil(context, 'start', (_) => false);
    }else{
      Navigator.pushNamedAndRemoveUntil(context, 'login', (_) => false);
      //await Navigator.pushNamedAndRemoveUntil(context, 'home', (_) => false);
      print("loginPage");
    }
  }
}
