import 'package:flutter/material.dart';
import 'package:schat/Helper/ColorMap.dart';
import 'package:schat/Model/Message.dart';
import 'dart:io';

import 'package:sprintf/sprintf.dart';

class ImageMessageView extends StatelessWidget{

  final Key key;
  final Message message;

  ImageMessageView({this.key, @required this.message}) : super(key : key);

  Widget _buildImageView(){
    Widget result;
    if(message.isMine){
      result = Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            child: Text(sprintf("ID: %s", [message.senderID]), style: TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.w700),),
          ),
          SizedBox(
            width: 200,
            child: Card(
              color: Colors.transparent,
              child: FadeInImage(
                fit: BoxFit.cover,
                placeholder: AssetImage("assets/image_waiting.png"),
                image: FileImage(File(message.getFilePath())),
              ),
            ),
          )
        ],
      );
    }else{
      result = Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            child: Text(sprintf("ID: %s", [message.senderID]), style: TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.w700),),
          ),
          FutureBuilder<Widget>(
            future: _getClientWidget(),
            builder: (context, snapshot){
              if (snapshot.connectionState == ConnectionState.done) {
                return snapshot.data;
              }else{
                return SizedBox(
                  width: 200,
                  height: 180,
                  child: Container(),
                );
              }
            },
          )
        ],
      );
    }
    return result;
  }
  
  Future<Widget> _getClientWidget() async{
    Widget result;
    String path = await message.getDownloadFilePath();
    if(File(path).existsSync()){
      result = SizedBox(
        width: 200,
        child: Card(
          color: Colors.transparent,
          child: Image.file(File(path), fit: BoxFit.cover,),
        ),
      );
    }else{
      result = SizedBox(
        width: 200,
        height: 180,
        child: Center(
          child: SizedBox(
            width: 60,
            height: 60,
            child: Image.asset("assets/ic_image_reveal.png", fit: BoxFit.cover,),
          ),
        ),
      );
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: 200, maxWidth: 200,),
      decoration: BoxDecoration(color: ColorMap.buttonColor, borderRadius: BorderRadius.all(Radius.circular(5.0))),
      margin: EdgeInsets.symmetric(vertical: 5),
      child: _buildImageView(),
    );
  }

}
