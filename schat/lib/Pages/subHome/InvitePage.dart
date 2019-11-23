import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:schat/Helper/ColorMap.dart';
import 'package:schat/Helper/ToastUtil.dart';
import 'package:schat/Widgets/GridViewItem.dart';
typedef InviteRoomCreate = void Function(String notice, int timeout);
typedef SocialShare = void Function(int type, int minute);
typedef BackPress = void Function();
class InvitePage extends StatefulWidget {
  final Key key;
  final String myCode;
  final InviteRoomCreate inviteRoomCreate;
  final SocialShare socialShare;
  final BackPress backPress;

  InvitePage({this.key, this.myCode, this.inviteRoomCreate, this.socialShare, this.backPress}) : super(key: key);

  @override
  InvitePageState createState() => InvitePageState();
}

class InvitePageState extends State<InvitePage> {
  TextEditingController roomController = TextEditingController();
  TextEditingController noticeController = TextEditingController();

  FocusNode noticeNode;

  bool isLoading = false;
  int minutes = 5;

  bool isCreate = true;

  @override
  void initState() {
    super.initState();
    noticeNode = FocusNode();
  }

  @override
  void dispose() {
    roomController?.dispose();
    noticeController?.dispose();
    noticeNode?.dispose();
    super.dispose();
  }

  void showLoading(bool show) {
    if(mounted){
      setState(() {
        isLoading = show;
      });
    }
  }

  void createRoom() {
    String notice = noticeController.text.trim();
    if(notice.isEmpty){
      ToastUtil.showToast("Please insert notification message");
      return;
    }
    
    if(minutes == 0){
      ToastUtil.showToast("Please select wait time");
      return;
    }
    
    this.showLoading(true);
    this.widget.inviteRoomCreate(notice, minutes);
  }

  void createdRoom(String room){
    roomController.text = room;
    isCreate = false;
    if(isLoading){
      this.showLoading(false);
    }
  }

  void _shareSocial(int type){
    Navigator.of(context).pop();
    this.widget.socialShare(type, minutes);
  }

  void shareRoom() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.black,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              Text(
                "Share to your friend by using here",
                style: TextStyle(color: Colors.black, fontSize: 16.0, fontWeight: FontWeight.w700),
              ),
              Container(
                padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Flexible(
                      flex: 1,
                      child: InkWell(
                          onTap: (){
                            _shareSocial(0);
                          },
                          child: SizedBox(
                            width: 70,
                            height: 70,
                            child: GridViewItem(iconPath : "assets/sms.png", title: "SMS",),
                          )
                      ),
                    ),
                    Flexible(
                      flex: 1,
                      child: InkWell(
                          onTap: (){
                            _shareSocial(1);
                          },
                          child: SizedBox(
                            width: 70,
                            height: 70,
                            child: GridViewItem(iconPath : "assets/facebook.png", title: "Facebook",),
                          )
                      ),
                    ),
                    Flexible(
                      flex: 1,
                      child: InkWell(
                          onTap: (){
                            _shareSocial(2);
                          },
                          child: SizedBox(
                            width: 70,
                            height: 70,
                            child: GridViewItem(iconPath : "assets/twitter.png", title: "Twitter",),
                          )
                      ),
                    ),
                    Flexible(
                      flex: 1,
                      child: InkWell(
                        onTap: (){
                          _shareSocial(3);
                        },
                        child: SizedBox(
                          width: 70,
                          height: 70,
                          child: GridViewItem(iconPath : "assets/kakao.png", title: "KakaoTalk",),
                        )
                      ),
                    )
                  ],
                ),
              ),
            ],
          );
        });
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
              color: ColorMap.backgroundColor,
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
                    child: Image.asset(
                      "assets/invite_chat_logo.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(
                  height: 20.0,
                ),
                Form(
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        controller: roomController,
                        enabled: false,
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
                          hintText: "Room code",
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 18.0,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                      TextFormField(
                        focusNode: noticeNode,
                        controller: noticeController,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (term) {
                          noticeNode.unfocus();
                          SystemChrome.setEnabledSystemUIOverlays([]);
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
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 18.0,
                            fontWeight: FontWeight.normal,
                          ),
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
                        child: Text(
                          "Wait Time",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25.0,
                          ),
                        ),
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
                                      body1: theme.textTheme.headline.copyWith(fontSize: 20.0, color: Colors.grey))),
                              child: NumberPicker.integer(
                                  initialValue: minutes,
                                  minValue: 0,
                                  maxValue: 59,
                                  zeroPad: true,
                                  infiniteLoop: true,

                                  onChanged: (newValue) {
                                    setState(() {
                                      minutes = newValue;
                                    });
                                  }),
                            ),
                            Text(
                              "Min",
                              style: TextStyle(color: Colors.white, fontSize: 20.0),
                            )
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
                    onPressed: () {
                      if (isCreate) {
                        createRoom();
                      } else {
                        shareRoom();
                      }
                    },
                    color: ColorMap.buttonColor,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(8.0), side: BorderSide(color: Colors.transparent)),
                    textColor: Colors.white,
                    highlightColor: ColorMap.buttonClickColor,
                    child: Text(
                      isCreate ? "Create Room" : "Share",
                      style: TextStyle(fontSize: 16.0),
                    ),
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
        isLoading
            ? Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black26.withOpacity(0.5),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            : Container(),
      ],
    );
  }
}
