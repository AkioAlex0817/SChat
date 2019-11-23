import 'package:flutter/material.dart';
import 'package:schat/Helper/ColorMap.dart';

typedef SignIn = void Function();
class SignUpPage extends StatefulWidget{
  final SignIn signIn;


  SignUpPage({this.signIn});

  @override
  SignUpPageState createState() => SignUpPageState();
}

class SignUpPageState extends State<SignUpPage>{

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Container(
      decoration: BoxDecoration(
        color: ColorMap.backgroundColor,
      ),
      child: Column(
        children: <Widget>[
          Flexible(
            flex: 2,
            child: Center(
              child: SizedBox(
                width: width / 3,
                height: width / 3,
                child: FittedBox(
                  child: Image.asset("assets/sign_up.png", fit: BoxFit.cover,),
                ),
              ),
            ),
          ),
          Flexible(
            flex: 1,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 50),
              child: Center(
                child: SizedBox(
                  width: double.infinity,
                  child: RaisedButton(
                    onPressed: (){
                      this.widget.signIn();
                    },
                    color: ColorMap.buttonColor,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: new RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(8.0),
                        side: BorderSide(color: Colors.transparent)),
                    textColor: Colors.white,
                    highlightColor: ColorMap.buttonClickColor,
                    child: Text("SIGNUP", style: TextStyle(fontSize: 16.0),),
                  ),
                ),
              ),
            ),
          )
        ],
      ),    
    );
  }
}