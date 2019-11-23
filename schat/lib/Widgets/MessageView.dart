import 'package:flutter/material.dart';
import 'package:schat/Helper/AttachmentType.dart';
import 'package:schat/Model/Message.dart';
import 'package:schat/Widgets/messageViews/ImageMessageView.dart';
import 'package:schat/Widgets/messageViews/TextMessageView.dart';
import 'package:schat/Widgets/messageViews/VideoMessageView.dart';

class MessageView extends StatefulWidget{

  final Key key;
  final Message message;


  MessageView({this.key, this.message}) : super(key : key);

  @override
  MessageViewState createState() => MessageViewState();
}

class MessageViewState extends State<MessageView>{

  void setRefresh(){
    if(mounted){
      setState(() {});
    }
  }

  Widget _buildMessageView(){
    Widget result;
    switch(this.widget.message.attachType){
      case AttachmentType.MESSAGE:
        result = TextMessageView(
          message: this.widget.message,
        );
        break;
      case AttachmentType.IMAGE:
        result = Container(
          width: 200,
          alignment: Alignment.centerLeft,
          child: ImageMessageView(
            message: this.widget.message,
          ),
        );
        break;
      case AttachmentType.VIDEO:
        result = Container(
          width: 200,
          alignment: Alignment.centerLeft,
          child: VideoMessageView(
            message: this.widget.message,
          ),
        );
        break;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return _buildMessageView();
  }
}