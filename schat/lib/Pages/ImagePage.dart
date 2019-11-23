import 'dart:io';
import 'package:flutter/material.dart';
import 'package:schat/Helper/ColorMap.dart';

class ImagePage extends StatefulWidget{

  final String filePath;

  ImagePage({this.filePath});

  @override
  ImagePageState createState() => ImagePageState();
}

class ImagePageState extends State<ImagePage>{

  Future<File> _getLocalFile() async{
    File f = new File(this.widget.filePath);
    return f;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Serect Chat"),
        backgroundColor: ColorMap.backgroundColor,
      ),
      body: SafeArea(
        child: Container(
          constraints: BoxConstraints.expand(),
          child: FutureBuilder(
            future: _getLocalFile(),
            builder: (BuildContext context, AsyncSnapshot<File> snapshot){
              return snapshot.data != null ? Image.file(snapshot.data, fit: BoxFit.cover,) : Center(
                child: CircularProgressIndicator(),
              );
            },
          ),
        ),
      ),
    );
  }
}