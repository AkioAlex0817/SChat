import 'package:flutter/material.dart';
import 'package:schat/Helper/ColorMap.dart';
class DownloadProgressWidget extends StatefulWidget{

  final Key key;
  DownloadProgressWidget({this.key}) : super(key : key);

  @override
  DownloadProgressWidgetState createState() => DownloadProgressWidgetState();
}

class DownloadProgressWidgetState extends State<DownloadProgressWidget>{

  bool _isShow = false;
  double _downloadProgress = 0.0;
  Key _key;

  Key getKey(){
    return _key;
  }

  setKey(Key key){
    _key = key;
  }

  setShow(bool show){
    if(mounted){
      setState(() {
        _isShow = show;
      });
    }
  }

  setProgress(double progress){
    if(mounted){
      setState(() {
        _downloadProgress = progress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isShow ? SizedBox(
      width: 50,
      height: 50,
      child: ClipOval(
        child: Container(
          decoration: BoxDecoration(
            color: ColorMap.buttonColor
          ),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: CircularProgressIndicator(
                  value: _downloadProgress,
                  strokeWidth: 5,
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.file_download, color: Colors.white,),
                ),
              )
            ],
          ),
        ),
      ),
    ) : Container();
  }
}