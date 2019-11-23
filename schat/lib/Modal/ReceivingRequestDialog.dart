import 'package:flutter/material.dart';
import 'package:schat/Helper/ColorMap.dart';
import 'package:schat/Widgets/LoadingAnimationWidget.dart';

class ReceivingRequestDialog extends StatefulWidget{

  final Key key;
  final String request;


  ReceivingRequestDialog({this.key, @required this.request}) : super(key : key);

  @override
  ReceivingRequestDialogState createState() => ReceivingRequestDialogState();
}

class ReceivingRequestDialogState extends State<ReceivingRequestDialog>{

  Future<bool> _onBackPressed() async {
    finishModal(2);
    return false;
  }

  finishModal(int isDisconnect){
    Navigator.pop(context, isDisconnect);
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
              color: ColorMap.backgroundColor
            ),
            padding: EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(this.widget.request, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),),
                SizedBox(
                  height: 60,
                ),
                SizedBox(
                  width: width / 3 * 2,
                  height: width / 3 * 2,
                  child: Stack(
                    children: <Widget>[
                      Positioned.fill(child: LoadingAnimationWidget()),
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.all(60),
                          child: Image.asset("assets/voice_call_incoming.png", fit: BoxFit.cover,),
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(
                  height: 100,
                ),
                SizedBox(
                  width: width / 3 * 2,
                  height: 50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      InkWell(
                        onTap: (){
                          finishModal(1);
                        },
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: Image.asset("assets/call_accept.png", fit: BoxFit.cover,),
                        ),
                      ),
                      InkWell(
                        onTap: (){
                          finishModal(2);
                        },
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: Image.asset("assets/call_reject.png", fit: BoxFit.cover,),
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