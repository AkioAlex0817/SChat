import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:schat/Helper/AttachmentType.dart';

class Message{
  final Key key;
  final String senderID;
  final String body;
  final bool selected;
  final int attachType; // 0: Text, 1 : Image, 2 : video, 3 : location
  final bool isMine;

  Message(this.key, this.senderID, this.body, this.selected, this.attachType, this.isMine);


  String getFilename(){
    String result;
    if(attachType == AttachmentType.IMAGE || attachType == AttachmentType.VIDEO){
      List<String> value = body.split("---");
      result = value[1];
    }
    return result.substring(result.lastIndexOf("/") + 1);
  }

  String getDownloadKey(){
    String result;
    if(attachType == AttachmentType.IMAGE || attachType == AttachmentType.VIDEO){
      List<String> value = body.split("---");
      result = value[0];
    }
    return result;
  }

  Future<bool> isDownloaded() async{
    File file = new File(await getDownloadFilePath());
    if(file.existsSync()){
      return true;
    }
    return false;
  }

  Future<String> getDownloadFilePath() async{
    String dir = (await getApplicationDocumentsDirectory()).path + "/files/" + getFilename();
    return dir;
  }

  String getFilePath(){
    String result;
    if(attachType == AttachmentType.IMAGE || attachType == AttachmentType.VIDEO){
      List<String> value = body.split("---");
      result = value[1];
    }
    return result;
  }

}