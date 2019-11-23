import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:schat/Helper/ColorMap.dart';
import 'package:schat/Helper/ToastUtil.dart';
import 'package:schat/Model/ResJoinModel.dart';
import 'package:schat/Pages/subStart/FaceVerifyPage.dart';
import 'package:schat/Pages/subStart/SignUpConfirmPage.dart';
import 'package:schat/Pages/subStart/SignUpPage.dart';
import 'package:schat/Widgets/LoadingAnimationWidget.dart';
import 'package:schat/main.dart';

class StartPage extends StatefulWidget {
  @override
  StartPageState createState() => StartPageState();
}

class StartPageState extends State<StartPage> {
  bool loading = false;
  int selected = 0;
  ResJoinModel resJoinModel;


  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    initSocket();
  }


  @override
  void dispose() {
    clearSocket();
    super.dispose();
  }

  void initSocket(){
    MyApp.signalServer.socketIO.on("res-join", (data){
      if(data['result'] == "OK"){
        resJoinModel = new ResJoinModel(data['user']['code'], data['user']['token']);
        setState(() {
          loading = false;
          selected = 1;
        });
      }
    });
  }

  void clearSocket(){
    MyApp.signalServer.socketIO.off("res-join");
  }

  void signIn(){
    if(MyApp.mSocketState != SocketState.Connected){
      ToastUtil.showToast("Failed register. Check Internet state and try again");
      return;
    }
    setState(() {
      loading = true;
    });

    MyApp.signalServer.socketIO.emit("join", [""]);
  }

  void signInConfirm(List<int> patterns) async{
    if(this.resJoinModel != null){
      await MyApp.shareUtils.setString("token", resJoinModel.token);
      await MyApp.shareUtils.setString("code", resJoinModel.code);
      await MyApp.shareUtils.setString("pattern", patterns.join(","));
      Navigator.pushNamedAndRemoveUntil(context, "home", (_) => false);
    }
  }

  void nextActivity(){
    setState(() {
      selected = 2;
    });
  }

  Widget _buildWidget(){
    Widget result;
    switch(selected){
      case 0: //signUpPage
        result = SignUpPage(signIn: signIn,);
        break;
      case 1: //signUpConfirmPage
        result = SignUpConfirmPage(
          code: resJoinModel == null ? "" : resJoinModel.code,
          nextActivity: nextActivity,
        );
        break;
      case 2: // FaceverifyPage
        result = FaceVerifyPage(
          code: resJoinModel == null ? "" : resJoinModel.code,
          signInConfirm: signInConfirm,
        );
        break;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: ColorMap.backgroundColor,
          ),
          child: loading
              ? Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(
                        width: width / 3 * 2,
                        height: width / 3 * 2,
                        child: Stack(
                          children: <Widget>[
                            Positioned.fill(child: LoadingAnimationWidget()),
                            Positioned.fill(
                              child: Padding(
                                padding: EdgeInsets.all(60.0),
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
                      Text("Please wait", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),)
                    ],
                  ),
                )
              : _buildWidget(),
        ),
      ),
    );
  }
}
