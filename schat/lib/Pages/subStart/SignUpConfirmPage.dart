import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter_camera_ml_vision/flutter_camera_ml_vision.dart';
import 'package:path_provider/path_provider.dart';
import 'package:schat/Helper/ColorMap.dart';

typedef NextActivity = void Function();
class SignUpConfirmPage extends StatefulWidget{

  final String code;
  final NextActivity nextActivity;


  SignUpConfirmPage({this.code, this.nextActivity});

  @override
  SignUpConfirmPageState createState() => SignUpConfirmPageState();
}

class SignUpConfirmPageState extends State<SignUpConfirmPage>{

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Container(
      decoration: BoxDecoration(
        color: ColorMap.backgroundColor
      ),
      child: Column(
        children: <Widget>[
          Flexible(
            flex: 3,
            child: Center(
              child: FittedBox(
                child: Column(
                  children: <Widget>[
                    SizedBox(
                      width: width / 3,
                      height: width / 3,
                      child: FittedBox(
                        child: Image.asset("assets/sign_up_complete.png", fit: BoxFit.cover,),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Text("Registered with this code", style: TextStyle(color: Colors.white, fontSize: 15.0),)
                  ],
                ),
              ),
            ),
          ),
          Flexible(
            flex: 2,
            child: Container(
              alignment: Alignment.topCenter,
              padding: EdgeInsets.symmetric(horizontal: 50.0),
              child: Column(
                children: <Widget>[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(8.0))
                    ),
                    child: Center(
                      child: Text(
                        widget.code,
                        style: TextStyle(color: Colors.black, fontSize: 18.0, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 23,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: RaisedButton(
                      onPressed: (){
                        this.widget.nextActivity();
                      },
                      color: ColorMap.buttonColor,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: new RoundedRectangleBorder(
                          borderRadius: new BorderRadius.circular(8.0),
                          side: BorderSide(color: Colors.transparent)),
                      textColor: Colors.white,
                      highlightColor: ColorMap.buttonClickColor,
                      child: Text("NEXT", style: TextStyle(fontSize: 16.0),),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}