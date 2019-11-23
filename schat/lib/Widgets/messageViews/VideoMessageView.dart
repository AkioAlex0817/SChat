import 'dart:io';

import 'package:flutter/material.dart';
import 'package:schat/Helper/ColorMap.dart';
import 'package:schat/Model/Message.dart';
import 'package:sprintf/sprintf.dart';

class VideoMessageView extends StatefulWidget{

  final Key key;
  final Message message;

  VideoMessageView({this.key, @required this.message}) : super(key : key);

  @override
  VideoMessageViewState createState() => VideoMessageViewState();


}

class VideoMessageViewState extends State<VideoMessageView>{
  Widget _buildVideoView(){
    Widget result;
    if(this.widget.message.isMine){
      result = Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            child: Text(sprintf("ID: %s", [this.widget.message.senderID]), style: TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.w700),),
          ),
          SizedBox(
            width: 200,
            height: 180,
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Center(
                    child: Icon(Icons.local_movies, size: 150, color: Color.fromARGB(38, 0, 230, 118),),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Icon(Icons.play_circle_outline, size: 40, color: Color.fromARGB(255, 0, 230, 118),),
                  ),
                )
              ],
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
            child: Text(sprintf("ID: %s", [this.widget.message.senderID]), style: TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.w700),),
          ),
          FutureBuilder<Widget>(
            future: _getClientWidget(),
            builder: (context, snapshot){
              if(snapshot.connectionState == ConnectionState.done){
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
    String path = await this.widget.message.getDownloadFilePath();
    if(File(path).existsSync()){
      result = SizedBox(
        width: 200,
        height: 180,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Center(
                child: Icon(Icons.local_movies, size: 150, color: Color.fromARGB(38, 0, 230, 118),),
              ),
            ),
            Positioned.fill(
              child: Center(
                child: Icon(Icons.play_circle_outline, size: 40, color: Color.fromARGB(255, 0, 230, 118),),
              ),
            )
          ],
        ),
      );
    }else{
      result = SizedBox(
        width: 200,
        height: 180,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Center(
                child: Icon(Icons.local_movies, size: 150, color: Color.fromARGB(38, 0, 230, 118),),
              ),
            ),
            Positioned.fill(
              child: Center(
                child: Icon(Icons.file_download, size: 40, color: Color.fromARGB(255, 0, 230, 118),),
              ),
            )
          ],
        ),
      );
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: 200, maxWidth: 200),
      decoration: BoxDecoration(color: ColorMap.buttonColor, borderRadius: BorderRadius.all(Radius.circular(5.0))),
      margin: EdgeInsets.symmetric(vertical: 5),
      child: _buildVideoView(),
    );
  }
}