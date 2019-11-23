import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:schat/Helper/ColorMap.dart';
import 'package:schat/Helper/ToastUtil.dart';
typedef ConnectRoomCreate = void Function(String custom, String notice, int timeout);
typedef BackPress = void Function();
class ConnectPage extends StatefulWidget{

  final Key key;
  final String myCode;
  final ConnectRoomCreate connectRoomCreate;
  final BackPress backPress;

  ConnectPage({this.key, this.myCode, this.connectRoomCreate, this.backPress}): super(key : key);

  @override
  ConnectPageState createState() => ConnectPageState();
}

class ConnectPageState extends State<ConnectPage>{

  TextEditingController codeController = TextEditingController();
  TextEditingController noticeController = TextEditingController();
  FocusNode codeNode;
  FocusNode noticeNode;

  int minutes = 5;


  @override
  void initState() {
    super.initState();
    codeNode = FocusNode();
    noticeNode = FocusNode();
  }


  @override
  void dispose() {
    codeController?.dispose();
    noticeController?.dispose();
    codeNode?.dispose();
    noticeNode?.dispose();
    super.dispose();
  }

  void sendRequest() async{
    String code = codeController.text.trim();
    String notice = noticeController.text.trim();

    if(code.isEmpty){
      ToastUtil.showToast("Please insert ID");
      return;
    }

    if(notice.isEmpty){
      ToastUtil.showToast("Please insert notification message");
      return;
    }

    if(minutes == 0){
      ToastUtil.showToast("Please select wait time");
      return;
    }

    this.widget.connectRoomCreate(code, notice, minutes);

  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
                color: ColorMap.backgroundColor
            ),
            padding: EdgeInsets.all(50.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  width: width / 3,
                  height: width / 3,
                  child: FittedBox(
                    child: Image.asset("assets/invite_chat_logo.png", fit: BoxFit.cover,),
                  ),
                ),
                SizedBox(
                  height: 20.0,
                ),
                Text("My ID : " + this.widget.myCode, style: TextStyle(color: Colors.white, fontSize: 22.0, fontWeight: FontWeight.w700),),
                SizedBox(
                  height: 10.0,
                ),
                Form(
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        focusNode: codeNode,
                        controller: codeController,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (term){
                          codeNode.unfocus();
                          FocusScope.of(context).requestFocus(noticeNode);
                        },
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black, fontSize: 18.0, fontWeight: FontWeight.normal),
                        maxLines: 1,
                        decoration: InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 15),
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.transparent
                              )
                          ),
                          border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.transparent
                              )
                          ),
                          hintText: "ID",
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 18.0, fontWeight: FontWeight.normal, ),
                        ),
                      ),
                      SizedBox(
                        height: 20.0,
                      ),
                      TextFormField(
                        focusNode: noticeNode,
                        controller: noticeController,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (term){
                          noticeNode.unfocus();
                        },
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(color: Colors.black, fontSize: 18.0, fontWeight: FontWeight.normal),
                        decoration: InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 15),
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.transparent
                              )
                          ),
                          border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.transparent
                              )
                          ),
                          hintText: "Notification",
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 18.0, fontWeight: FontWeight.normal, ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Divider(color: Colors.grey, height: 2.0),
                Container(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Flexible(
                        flex: 5,
                        child : Text("Wait Time", style: TextStyle(color: Colors.white, fontSize: 25.0,),),
                      ),
                      Flexible(
                        flex: 6,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            Theme(
                              data: theme.copyWith(
                                  accentColor: Colors.white,
                                  textTheme: theme.textTheme.copyWith(
                                      headline: theme.textTheme.headline.copyWith(
                                        fontSize: 30.0,
                                      ),
                                      body1: theme.textTheme.headline.copyWith(
                                          fontSize: 20.0,
                                          color: Colors.grey
                                      )
                                  )
                              ),
                              child: NumberPicker.integer(
                                  initialValue: minutes,
                                  minValue: 0,
                                  maxValue: 59,
                                  zeroPad: true,
                                  infiniteLoop: true,
                                  onChanged: (newValue){
                                    setState(() {
                                      minutes = newValue;
                                    });
                                  }
                              ),
                            ),
                            Text("Min", style: TextStyle(color: Colors.white, fontSize: 20.0),)
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Divider(color: Colors.grey, height: 2.0),
                SizedBox(
                  height: 20.0,
                ),
                SizedBox(
                  width: double.infinity,
                  child: RaisedButton(
                    onPressed: (){
                      sendRequest();
                    },
                    color: ColorMap.buttonColor,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: new RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(8.0),
                        side: BorderSide(color: Colors.transparent)),
                    textColor: Colors.white,
                    highlightColor: ColorMap.buttonClickColor,
                    child: Text("Share", style: TextStyle(fontSize: 16.0),),
                  ),
                )
              ],
            ),
          ),
        ),
        Positioned(
          left: 10,
          top: 10,
          child: Center(
              child: IconButton(
                onPressed: (){
                  this.widget.backPress();
                },
                icon: Icon(Icons.arrow_back, color: Colors.white, size: 30,),
              )
          ),
        ),
      ],
    );
  }
}