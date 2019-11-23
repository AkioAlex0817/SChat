import 'package:flutter/material.dart';
import 'package:schat/Model/Message.dart';
import 'package:sprintf/sprintf.dart';

class TextMessageView extends StatelessWidget {
  final Key key;
  final Message message;

  TextMessageView({this.key, @required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      width: double.infinity,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 70,
            height: 70,
            child: FittedBox(
              child: Image.asset(
                this.message.isMine ? "assets/schat_me.png" : "assets/schat_friend.png",
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(
            width: 12,
          ),
          Expanded(
            child: Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Flexible(
                    flex: 1,
                    child: Text(
                      sprintf("%s%s", ["ID : ", message.senderID]),
                      style: TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.w700),
                      maxLines: 1,
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Flexible(
                    flex: 1,
                    child: Text(
                      message.body,
                      style: TextStyle(color: Colors.white, fontSize: 15.0, fontWeight: FontWeight.normal),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
