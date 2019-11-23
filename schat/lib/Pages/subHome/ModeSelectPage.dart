import 'package:flutter/material.dart';
import 'package:schat/Helper/ColorMap.dart';
typedef SwitchPageHandler = void Function(int index);
class ModeSelectPage extends StatefulWidget{

  final Key key;
  final SwitchPageHandler switchPageHandler;

  ModeSelectPage({this.key, this.switchPageHandler}) : super(key : key);

  @override
  ModeSelectPageState createState() => ModeSelectPageState();
}

class ModeSelectPageState extends State<ModeSelectPage>{

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Container(
      decoration: BoxDecoration(
        color: ColorMap.backgroundColor,
      ),
      padding: EdgeInsets.symmetric(horizontal: 50.0, vertical: 50.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          SizedBox(
            width: width / 3,
            height: width / 3,
            child: FittedBox(
              child: Image.asset("assets/home_logo.png", fit: BoxFit.cover,),
            ),
          ),
          SizedBox(height: 50,),
          SizedBox(
            height: 30,
            child: Center(
              child: Text("Select chat mode", style: TextStyle(color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.w700),),
            ),
          ),
          SizedBox(height: 50,),
          SizedBox(
            width: double.infinity,
            child: RaisedButton(
              onPressed: (){
                this.widget.switchPageHandler(1);
              },
              color: ColorMap.buttonColor,
              padding: EdgeInsets.symmetric(vertical: 15),
              shape: new RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(8.0),
                  side: BorderSide(color: Colors.transparent)),
              textColor: Colors.white,
              highlightColor: ColorMap.buttonClickColor,
              child: Text("Invite Chat", style: TextStyle(fontSize: 16.0),),
            ),
          ),
          SizedBox(height: 20,),
          SizedBox(
            width: double.infinity,
            child: RaisedButton(
              onPressed: (){
                this.widget.switchPageHandler(2);
              },
              color: ColorMap.buttonColor,
              padding: EdgeInsets.symmetric(vertical: 15),
              shape: new RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(8.0),
                  side: BorderSide(color: Colors.transparent)),
              textColor: Colors.white,
              highlightColor: ColorMap.buttonClickColor,
              child: Text("Friendly Chat", style: TextStyle(fontSize: 16.0),),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

}