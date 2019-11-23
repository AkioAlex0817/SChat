import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:schat/Fragments/CallFragment.dart';
import 'package:schat/Fragments/VideoFragment.dart';
import 'package:schat/Helper/AttachmentType.dart';
import 'dart:core';
import 'dart:async';

import 'package:schat/Helper/ColorMap.dart';
import 'package:schat/Helper/Constants.dart';
import 'package:schat/Helper/Helper.dart';
import 'package:schat/Helper/Signaling.dart';
import 'package:schat/Helper/ToastUtil.dart';
import 'package:schat/Modal/ReceivingRequestDialog.dart';
import 'package:schat/Model/FileModel.dart';
import 'package:schat/Model/Message.dart';
import 'package:schat/Modal/SendingRequestDialog.dart';
import 'package:schat/Pages/ImagePage.dart';
import 'package:schat/Pages/VideoPlayPage.dart';
import 'package:schat/Widgets/DownloadProgressWidget.dart';
import 'package:schat/Widgets/LoadingAnimationWidget.dart';
import 'package:schat/Widgets/MessageView.dart';
import 'package:schat/Widgets/MinMaxButton.dart';
import 'package:schat/main.dart';
import 'package:sprintf/sprintf.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

class ChatPage extends StatefulWidget {
  final Key key;
  final String room;
  final bool isInitiator;
  final String custom;

  ChatPage({this.key, @required this.room, @required this.isInitiator, @required this.custom}) : super(key: key);

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> with SingleTickerProviderStateMixin {
  int ChatMode = 0; //0 : none, 1 : voice chat, 2 : video chat
  bool loading = true;
  bool isDownload = false;
  String token;
  String code;
  Signaling _signaling;

  List<Message> messages = [];
  TextEditingController _messageController = TextEditingController();
  ScrollController _scrollController = ScrollController();

  RTCVideoRenderer _localRenderer = new RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = new RTCVideoRenderer();

  List<FileModel> _uploadFiles = []; //상대방에게 전송한 파일의 목록

  //download variants section
  bool _receivingFile = false;
  Uint8List _fileBytes;
  int _incomingFileSize = 0;
  String _fileName;
  int _currentIndexPointer = 0;
  double _downloadProgress = 0.0;

  //-----------end-------------

  //Audio variants
  AudioPlayer _audioPlayer;
  AudioCache _audioCache;
  final String callMp3 = "calling.mp3";
  final String incomeMp3 = "incoming.mp3";

  //--------------------

  //sendingDialog variant
  bool mSendingDialog = false; //요청중 화면이 현시중인지 판단하는 변수
  bool mReceivingDialog = false; //받기중 화면이 현시중인지 판단하는 변수

  GlobalKey<SendingRequestDialogState> sendingDialogKey = GlobalKey<SendingRequestDialogState>(); //요청중화면페지 키
  GlobalKey<ReceivingRequestDialogState> receivingDialogKey = GlobalKey<ReceivingRequestDialogState>(); //받기중화면페지 키
  GlobalKey<DownloadProgressWidgetState> downloadWidgetKey = GlobalKey<DownloadProgressWidgetState>(); // 다운로드 프로그레스바 위젯 키
  GlobalKey<MinMaxButtonState> minmaxButtonKey = GlobalKey<MinMaxButtonState>(); //최대 최소화단추 위젯 키

  //--------------------------

  //CallFragment variant
  GlobalKey<CallFragmentState> callFragment = GlobalKey<CallFragmentState>(); //음성통화상태페지 키
  Timer _callDuration; //음성통화시간계수기
  int _callTime; //음성통화시간
  //-----------------------------

  //VideoFragment variant
  GlobalKey<VideoFragmentState> videoFragment = GlobalKey<VideoFragmentState>(); // 화면통화상태페지 키
  //---------------------------

  bool _isShowMinMax = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    token = await MyApp.shareUtils.getString("token");
    code = await MyApp.shareUtils.getString("code");
    //인증상태가 미정이면 등록페지로 이동
    if (token == null || code == null) {
      Navigator.of(context).pushNamedAndRemoveUntil("start", (_) => false);
    }

    //이미 다운로드된 파일 전부 삭제
    String delPath = (await getApplicationDocumentsDirectory()).path + "/files/";
    final dir = Directory(delPath);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
    //착신음적제
    _audioPlayer = new AudioPlayer();
    _audioCache = new AudioCache(prefix: 'audio/', fixedPlayer: _audioPlayer);
    _audioCache.loadAll([callMp3, incomeMp3]);

    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    _connect();
  }

  _disconnect() async {
    _signaling.clearSocket();
    MyApp.signalServer.socketIO.emit("leave-room", [
      {
        "room": this.widget.room,
      }
    ]);
    if (this.widget.isInitiator) {
      MyApp.signalServer.socketIO.emit("close-room", [
        {"room": this.widget.room}
      ]);
    }
    if (_signaling != null) {
      _signaling.closeInternal();
    }
  }

  @override
  void dispose() {
    _localRenderer?.dispose();
    _remoteRenderer?.dispose();
    _messageController?.dispose();
    _scrollController?.dispose();
    _audioPlayer?.dispose();
    _audioCache?.clearCache();
    _callDuration?.cancel();
    super.dispose();
  }

  void _initAppRTC() {
    /*var client = new http.Client();sig
    client.get(Constants.signalServerURL + "turn").then((response) {
      if (mounted) {
        if (response.statusCode == 200) {
          Map<String, dynamic> iceServers = {
            "iceServers" : []
          };
          List<IceServerModel> lists = [];
          var result = json.decode(response.body);
          for (var item in result['iceServers']) {
            lists.add(new IceServerModel(item['url'], item['username'], item['credential']));
          }
          for (int index = 0; index < lists.length; index++) {
            iceServers['iceServers'][index] = {'url': lists[index].url, 'username': lists[index].username, 'credential': lists[index].credential};
          }
          signaling.setIceServers(iceServers);
          connectAppRTC();
        }
      }
    }, onError: (error) {
      print("Error : $error");
    });*/
  }

  _closePeerConnectionForce() {
    if (this.widget.isInitiator) {
      MyApp.signalServer.socketIO.emit("close-room", [
        {"room": this.widget.room}
      ]);
    }
    _signaling.clearSocket();
    _signaling.closeInternal();
  }

  _connect() {
    if (_signaling == null) {
      _signaling = new Signaling(isInitiator: this.widget.isInitiator, room: this.widget.room, code: this.code)..connect();
      _signaling.onStateChange = (SignalingState state) {
        print("onStateChange");
      };

      _signaling.onLocalStream = ((stream) {
        print("onLocalStream");
        _localRenderer.srcObject = stream;
      });

      _signaling.onAddRemoteStream = ((stream) {
        print("onAddRemoteStream");
        _remoteRenderer.srcObject = stream;
      });

      _signaling.onRemoveRemoteStream = ((stream) {
        print("onRemoveRemoteStream");
        _remoteRenderer.srcObject = null;
      });

      _signaling.onIceConnected = (() {
        _signaling.videoSet(false);
        _signaling.voiceSet(false);
        setState(() {
          loading = false;
        });
      });
      _signaling.onDisconnect = (() {
        _closePeerConnectionForce();
      });

      _signaling.onIceDisconnected = (() {
        _closePeerConnectionForce();
      });

      _signaling.reportError = ((msg) {
        return showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return AlertDialog(
                title: Text(msg),
                actions: <Widget>[
                  FlatButton(
                    onPressed: () {
                      _closePeerConnectionForce();
                    },
                    child: Text("OK"),
                  )
                ],
              );
            });
      });

      _signaling.onPeerConnectionClosed = (() {
        Navigator.popUntil(context, ModalRoute.withName('home'));
      });

      _signaling.onDataChannelMessage = ((RTCDataChannelMessage data) {
        print("Message received");
        String result = utf8.decode(data.binary);
        List<String> parse = result.split(":::");
        switch (parse[0]) {
          case "Msg": //Msg 일때
            Map<String, dynamic> msg = jsonDecode(parse[1]);
            this.messages.insert(0, new Message(GlobalKey<MessageViewState>(), this.widget.custom, msg['body'], false, msg['attach'], false));
            if (messages.length > 10) {
              messages.removeAt(0);
            }
            setState(() {});
            Future.delayed(
              Duration(milliseconds: 100),
            );
            //_scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
            _scrollController.animateTo(0.0, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);

            break;
          case "Call": // 상대방에게서 음성통화요청이 왔을때
            _onCall();
            break;
          case "VideoCall": //상대방에게서 비디오통화요청이 왔을떄
            _onVideoCall();
            break;
          case "ReceiveCall": // 상대방의 음성통화요청에 대한 응답
            _onReceiveCall(parse[1]);
            break;
          case "ReceiveVideoCall": // 상대방의 비디오통화요청에 대한 응답
            _onReceiveVideoCall(parse[1]);
            break;
          case "SendFile": //파일전송요청
            ToastUtil.showToast("File sending");
            _sendFile(parse[1]);
            break;
        }
      });

      _signaling.onDataChannelFile = ((RTCDataChannelMessage data) {
        if (!_receivingFile) {
          String firstMessage = utf8.decode(data.binary);
          List<String> parse = firstMessage.split(":::");
          print(parse);
          if (parse[0] == "-i") {
            _incomingFileSize = int.parse(parse[1]);
            _fileBytes = new Uint8List(_incomingFileSize);
            _fileName = parse[2];
            _receivingFile = true;
            _currentIndexPointer = 0;
            _downloadProgress = 0.0;
            if (downloadWidgetKey.currentState != null) {
              downloadWidgetKey.currentState.setProgress(_downloadProgress);
            }
          }
        } else {
          for (int b in data.binary) {
            _fileBytes[_currentIndexPointer++] = b;
          }
          _downloadProgress = _currentIndexPointer / _incomingFileSize;
          if (downloadWidgetKey.currentState != null) {
            downloadWidgetKey.currentState.setProgress(_downloadProgress);
          }
          //print("$_currentIndexPointer:::$_incomingFileSize");
          if (_currentIndexPointer == _incomingFileSize) {
            ToastUtil.showToast("Download complete");
            _receivingFile = false;
            _currentIndexPointer = 0;
            _makeFile(_fileName, _fileBytes).then((_) {
              _fileName = null;
              isDownload = false;
              if (downloadWidgetKey.currentState != null) {
                downloadWidgetKey.currentState.setShow(isDownload);
                GlobalKey<MessageViewState> key = downloadWidgetKey.currentState.getKey();
                if (key.currentState != null) {
                  key.currentState.setRefresh();
                }
              }
            });
          }
        }
      });
    }
  }

  _onReceiveCall(String type) {
    print("AlexTypeCall:" + type);
    switch (type) {
      case "OK": //수락
        if (mSendingDialog) {
          if(sendingDialogKey.currentState != null){
            sendingDialogKey.currentState.finishModal(0); //보내던화면을 숨기기
          }
          _setCallFragment(); //기본음성통화 화면현시
        }
        break;
      case "Cancel": //거절
        if (mSendingDialog) {
          if(sendingDialogKey.currentState != null){
            sendingDialogKey.currentState.finishModal(1); //통화거절
          }

        }
        break;
      case "Disconnect": //요청취소
        if (mReceivingDialog) {
          if(receivingDialogKey.currentState != null){
            receivingDialogKey.currentState.finishModal(0);
          }
        }
        break;
      case "HangUP": //음성대화완료
        if (_callDuration != null) {
          _callDuration.cancel();
          _callDuration = null;
        }
        _signaling.speakSet(false);
        _signaling.voiceSet(false);
        if (callFragment.currentState != null) {
          callFragment.currentState.finishFragment();
        }
        ChatMode = 0;
        _isShowMinMax = false;
        if (minmaxButtonKey.currentState != null) {
          minmaxButtonKey.currentState.setShow(_isShowMinMax);
        }
        break;
    }
  }

  _onReceiveVideoCall(String type) {
    print("AlexTypeVideo:" + type);
    switch (type) {
      case "OK": //수락
        if (mSendingDialog) {
          if(sendingDialogKey.currentState != null){
            sendingDialogKey.currentState.finishModal(0); //보내던 화면의 숨기기
          }
          _setVideoCallFragment(); //기본비디오통화 화면현시
        }
        break;
      case "Cancel": //거절
        if (mSendingDialog) {
          if(sendingDialogKey.currentState != null){
            sendingDialogKey.currentState.finishModal(1);
          }

        }
        break;
      case "Disconnect": //요청취소
        if (mReceivingDialog) {
          if(receivingDialogKey.currentState != null){
            receivingDialogKey.currentState.finishModal(0);
          }
        }
        break;
      case "HangUP": //비디오대화 완료
        _signaling.speakSet(false);
        _signaling.voiceSet(false);
        _signaling.videoSet(false);
        if (videoFragment.currentState != null) {
          videoFragment.currentState.finishFragment();
        }
        ChatMode = 0;
        _isShowMinMax = false;
        if (minmaxButtonKey.currentState != null) {
          minmaxButtonKey.currentState.setShow(_isShowMinMax);
        }
        break;
    }
  }

  // 전송받은 파일의 보관
  Future<void> _makeFile(String fileName, Uint8List fileBytes) async {
    String path = (await getApplicationDocumentsDirectory()).path + "/files/" + fileName;
    File file = await File(path).create(recursive: true);
    return file.writeAsBytesSync(fileBytes);
  }

  // 상대방이 파일다운로드를 등록하는 경우 파일은 file channel 을 통해 전송
  _sendFile(String key) {
    for (int i = 0; i < _uploadFiles.length; i++) {
      if (_uploadFiles[i].key == key) {
        File file = File(_uploadFiles[i].path);
        if (file.existsSync()) {
          Uint8List bytes = file.readAsBytesSync();
          _sendFileThrowDataChannel(bytes, Helper.parseFileName(_uploadFiles[i].path));
          _uploadFiles.removeAt(i);
        } else {
          _uploadFiles.removeAt(i);
        }
        break;
      }
    }
  }

  //파일바이트배렬을 64kb단위로 불로크와 하여 전송
  _sendFileThrowDataChannel(Uint8List bytes, String fileInfo) async {
    int size = bytes.length;
    int numberOfChunks = (size / Constants.CHUNK_SIZE).floor();
    var meta = utf8.encode("-i:::" + size.toString() + ":::" + fileInfo);
    var data = meta is Uint8List ? meta : new Uint8List.fromList(meta);
    _signaling.sendFile(data);
    Future.delayed(Duration(milliseconds: 50));
    for (int i = 0; i < numberOfChunks; i++) {
      int start = i * Constants.CHUNK_SIZE;
      int end = start + Constants.CHUNK_SIZE;
      var wrap = bytes.sublist(start, end);
      _signaling.sendFile(wrap);
      Future.delayed(Duration(milliseconds: 50));
    }
    int remainder = size % Constants.CHUNK_SIZE;
    if (remainder > 0) {
      print("Test");
      print(remainder);
      var wrap = bytes.sublist(numberOfChunks * Constants.CHUNK_SIZE);
      _signaling.sendFile(wrap);
    }
  }

  // 메시지 전송단추이벤트 핸들러
  void sendTextMessage() {
    String message = _messageController.text.trim();
    if (message.isNotEmpty) {
      sendMessage(message, AttachmentType.MESSAGE);
      _messageController.clear();
    }
  }

  void sendMessage(final String messageBody, int attachType) {
    this.messages.insert(0, new Message(GlobalKey<MessageViewState>(), this.code, messageBody, false, attachType, true));
    if (this.messages.length > 10) {
      this.messages.removeAt(0);
    }
    setState(() {});
    //_scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    _scrollController.animateTo(0.0, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);

    var content = {"body": messageBody, "attach": attachType};
    String request = "Msg:::" + jsonEncode(content);
    sendThrowData(request);
  }

  void sendThrowData(String result) {
    var list = utf8.encode(result);
    var data = list is Uint8List ? list : new Uint8List.fromList(list);
    _signaling.sendMessage(data);
  }

  Future<bool> _onBackPressed() async {
    return showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text("Do you really want exit this chat?"),
              actions: <Widget>[
                FlatButton(
                  child: Text("No"),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                FlatButton(
                  child: Text("Yes"),
                  onPressed: () {
                    Navigator.pop(context);
                    _disconnect();
                  },
                )
              ],
            ));
    return false;
  }

  _prepareFileSend(path, int type) {
    try {
      if (path == null) {
        throw new Exception("Failed");
      }
      var file = File(path);
      if (!Helper.overFileSize(file.lengthSync())) {
        String addTime = new DateTime.now().millisecondsSinceEpoch.toString();
        String message = addTime + "---" + path;
        _uploadFiles.add(new FileModel(addTime, path));
        sendMessage(message, type);
      } else {
        ToastUtil.showToast("Can not send larger than 14MB");
      }
    } catch (error) {
      ToastUtil.showToast("Failed send file");
    }
  }

  _dismissAttachFileDialog(int type) async {
    Navigator.pop(context);
    switch (type) {
      case AttachmentType.IMAGE: // Image file
        String path = await _openFileExplorer(FileType.IMAGE);
        _prepareFileSend(path, AttachmentType.IMAGE);
        break;
      case AttachmentType.VIDEO: // Video File
        String path = await _openFileExplorer(FileType.VIDEO);
        _prepareFileSend(path, AttachmentType.VIDEO);
        break;
      case AttachmentType.LOCATION: // Location
        break;
    }
  }

  Future<String> _openFileExplorer(FileType fileType) async {
    String result;
    try {
      result = await FilePicker.getFilePath(type: fileType);
    } on PlatformException catch (error) {
      ToastUtil.showToast("Unsupported operation" + error.toString());
    }

    return result;
  }

  void _showAttachFileDialog() {
    double width = MediaQuery.of(context).size.width;
    showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            children: <Widget>[
              Container(
                width: width / 4 * 3,
                height: 100,
                padding: EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(color: Colors.white),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "Please select file type",
                      style: TextStyle(color: Colors.black, fontSize: 20.0, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: Container(
                            child: Material(
                              color: Colors.white,
                              child: InkWell(
                                onTap: () {
                                  _dismissAttachFileDialog(AttachmentType.IMAGE);
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.max,
                                  children: <Widget>[
                                    FittedBox(
                                      child: SizedBox(
                                        width: 50,
                                        height: 50,
                                        child: Image.asset(
                                          "assets/ic_image_reveal.png",
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      "Image",
                                      style: TextStyle(color: Colors.black, fontSize: 18.0),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            child: Material(
                              color: Colors.white,
                              child: InkWell(
                                onTap: () {
                                  _dismissAttachFileDialog(AttachmentType.VIDEO);
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.max,
                                  children: <Widget>[
                                    FittedBox(
                                      child: SizedBox(
                                        width: 50,
                                        height: 50,
                                        child: Image.asset(
                                          "assets/ic_video_reveal.png",
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      "Video",
                                      style: TextStyle(color: Colors.black, fontSize: 18.0),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          );
        });
  }

  void _onMessageClick(final Message message) async {
    switch (message.attachType) {
      case AttachmentType.IMAGE:
        if (message.isMine) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => ImagePage(
                    filePath: message.getFilePath(),
                  )));
        } else {
          if (await message.isDownloaded()) {
            String path = await message.getDownloadFilePath();
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ImagePage(
                      filePath: path,
                    )));
          } else {
            showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Download"),
                    content: const Text("Do you want download it?"),
                    actions: <Widget>[
                      FlatButton(
                        child: const Text("Yes"),
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (isDownload) {
                            ToastUtil.showToast("There is already a file being downloaded. Please wait...");
                          } else {
                            String msg = "SendFile:::" + message.getDownloadKey();
                            sendThrowData(msg);
                            isDownload = true;
                            if (downloadWidgetKey.currentState != null) {
                              downloadWidgetKey.currentState.setKey(message.key);
                              downloadWidgetKey.currentState.setShow(isDownload);
                            }
                          }
                        },
                      ),
                      FlatButton(
                        child: const Text("No"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      )
                    ],
                  );
                });
          }
        }
        break;
      case AttachmentType.VIDEO:
        if (message.isMine) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => VideoPlayPage(
                    filePath: message.getFilePath(),
                  )));
        } else {
          if (await message.isDownloaded()) {
            String path = await message.getDownloadFilePath();
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => VideoPlayPage(
                      filePath: path,
                    )));
          } else {
            showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Download"),
                    content: const Text("Do you want download it?"),
                    actions: <Widget>[
                      FlatButton(
                        child: const Text("Yes"),
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (isDownload) {
                            ToastUtil.showToast("There is already a file being downloaded. Please wait...");
                          } else {
                            String msg = "SendFile:::" + message.getDownloadKey();
                            sendThrowData(msg);
                            isDownload = true;
                            if (downloadWidgetKey.currentState != null) {
                              downloadWidgetKey.currentState.setKey(message.key);
                              downloadWidgetKey.currentState.setShow(isDownload);
                            }
                          }
                        },
                      ),
                      FlatButton(
                        child: const Text("No"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      )
                    ],
                  );
                });
          }
        }
        break;
      case AttachmentType.LOCATION:
        break;
    }
  }

  List<Widget> _buildMessageListWidget() {
    List<Widget> result = [];
    for (int i = 0; i < messages.length; i++) {
      result.add(InkWell(
        onTap: () {
          _onMessageClick(messages[i]);
        },
        child: MessageView(
          key: messages[i].key,
          message: messages[i],
        ),
      ));
    }
    return result;
  }

  void _clearKeyBoard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _placeCall({bool isVideo}) async {
    _clearKeyBoard();
    if (isVideo) {
      // 비데오통화요청
      if (!mSendingDialog) {
        sendThrowData("VideoCall:::Video");
        mSendingDialog = true;
        _startMusic(true);
        int isCancel = await Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => SendingRequestDialog(
                  key: sendingDialogKey,
                  request: "Video Calling",
                )));
        mSendingDialog = false;
        _stopMusic();
        switch (isCancel) {
          case 1: //통화거절
            ToastUtil.showToast("Rejected call");
            break;
          case 2: //보내던 요청의 취소
            sendThrowData("ReceiveVideoCall:::Disconnect");
            break;
          default:
            break;
        }
      }
    } else {
      //음성통화요청
      if (!mSendingDialog) {
        sendThrowData("Call:::Phone");
        mSendingDialog = true;
        _startMusic(true);
        int isCancel = await Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => SendingRequestDialog(
                  key: sendingDialogKey,
                  request: "Voice Calling",
                )));
        mSendingDialog = false;
        _stopMusic();
        switch (isCancel) {
          case 1: //통화거절
            ToastUtil.showToast("Rejected call");
            break;
          case 2: //보내던 요청의 취소
            sendThrowData("ReceiveCall:::Disconnect");
            break;
          default:
            break;
        }
      }
    }
  }

  //상대방으로부터 음성통화요청 도착
  void _onCall() async {
    _clearKeyBoard(); //키보드초기화
    if (!mReceivingDialog) {
      // 받기중 Dialog창이 없는 경우에만
      mReceivingDialog = true;
      _startMusic(false);
      int isAccept = await Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ReceivingRequestDialog(
                key: receivingDialogKey,
                request: "Incoming voice call",
              )));
      mReceivingDialog = false;
      _stopMusic();
      switch (isAccept) {
        case 0: //완료사건처리
          ToastUtil.showToast("Canceled call");
          break;
        case 1: //음성요청수락처리
          sendThrowData("ReceiveCall:::OK");
          _setCallFragment(); //기본음성통화 화면현시
          break;
        case 2: //음성요청거절처리
          sendThrowData("ReceiveCall:::Cancel");
          break;
      }
    }
  }

  //상대방으로부터 비디오통화요청 도착
  void _onVideoCall() async {
    _clearKeyBoard(); //키보드 숨기기
    if (!mReceivingDialog) {
      //받기중화면이 현시중이 아닌 경우에만
      mReceivingDialog = true;
      _startMusic(false);
      int isAccept = await Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ReceivingRequestDialog(
                key: receivingDialogKey,
                request: "Incoming Video call",
              )));
      mReceivingDialog = false;
      _stopMusic();
      switch (isAccept) {
        /*case 0: //완료사건처리
          ToastUtil.showToast("Canceled call");
          break;*/
        case 1: //비디오 요청수락
          sendThrowData("ReceiveVideoCall:::OK");
          _setVideoCallFragment(); //기본비디오통화 화면현시
          break;
        case 2: //비디오 요청거절
          sendThrowData("ReceiveVideoCall:::Cancel");
          break;
      }
    }
  }

  _setCallFragment() {
    print("SetCallFragment");
    _signaling.voiceSet(true);
    if (_callDuration != null) {
      _callDuration.cancel();
      _callDuration = null;
    }
    _callTime = 0;
    _callDuration = new Timer.periodic(Duration(seconds: 1), (tick) {
      _callTime++;
      if (callFragment.currentState != null) {
        callFragment.currentState.onTick(_callTime);
      }
    });
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => CallFragment(
              key: callFragment,
              duration: _callTime,
              ID: this.widget.custom,
              disconnectVoiceCall: _disconnectVoiceCall,
              messageFunction: _messageFunction,
              soundFunction: _soundFunction,
              speakerFunction: _speakerFunction,
            )));
  }

  //Override CallFragment disconnectVoiceCall
  void _disconnectVoiceCall() {
    _signaling.speakSet(false);
    _signaling.voiceSet(false);
    sendThrowData("ReceiveCall:::HangUP");
    if (_callDuration != null) {
      _callDuration.cancel();
      _callDuration = null;
    }
    if(callFragment.currentState != null){
      callFragment.currentState.finishFragment();
    }
  }

  //Override CallFragment messageFunction
  void _messageFunction() {
    ChatMode = 1;
    _isShowMinMax = true;
    if (minmaxButtonKey.currentState != null) {
      minmaxButtonKey.currentState.setShow(_isShowMinMax);
    }
    Navigator.of(context).pop(context);
  }

  //Override CallFragment speakerFunction
  void _speakerFunction(bool speak) {
    _signaling.speakSet(speak);
  }

  //Override CallFragment soundFunction
  void _soundFunction(bool sound) {
    _signaling.voiceSet(sound);
  }

  _setVideoCallFragment() {
    print("SetVideoCallFragment");
    _signaling.voiceSet(true);
    _signaling.videoSet(true);
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => VideoFragment(
              key: videoFragment,
              remoteRenderer: _remoteRenderer,
              localRenderer: _localRenderer,
              speakerFunction: _speakerFunction,
              soundFunction: _soundFunction,
              disconnectVideoCall: _disconnectVideoCall,
              messageFunction: _videoMessageFunction,
              switchCamera: _switchCameraFunction,
              videoFunction: _videoFunction,
            )));
  }

  void _disconnectVideoCall() {
    _signaling.speakSet(false);
    _signaling.voiceSet(false);
    _signaling.videoSet(false);
    sendThrowData("ReceiveVideoCall:::HangUP");
    if(videoFragment.currentState != null){
      videoFragment.currentState.finishFragment();
    }

  }

  void _videoMessageFunction() {
    ChatMode = 2;
    _isShowMinMax = true;
    if (minmaxButtonKey.currentState != null) {
      minmaxButtonKey.currentState.setShow(_isShowMinMax);
    }
    Navigator.of(context).pop(context);
  }

  void _switchCameraFunction() {
    _signaling.switchCamera();
  }

  void _videoFunction(bool video) {
    _signaling.videoSet(video);
  }

  _startMusic(bool isCalling) {
    if (isCalling) {
      _audioCache.loop(callMp3);
    } else {
      _audioCache.loop(incomeMp3);
    }
  }

  _stopMusic() {
    _audioPlayer.stop();
  }

  //최대 최소화 단추 이벤트 핸들러
  _minMaxButtonHandler() {
    if (ChatMode == 1) {
      //음성통화중이였을때
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => CallFragment(
                key: callFragment,
                duration: _callTime,
                ID: this.widget.custom,
                disconnectVoiceCall: _disconnectVoiceCall,
                messageFunction: _messageFunction,
                soundFunction: _soundFunction,
                speakerFunction: _speakerFunction,
              )));
    } else if (ChatMode == 2) {
      //비디오 통화중이였을때
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => VideoFragment(
                key: videoFragment,
                remoteRenderer: _remoteRenderer,
                localRenderer: _localRenderer,
                speakerFunction: _speakerFunction,
                soundFunction: _soundFunction,
                disconnectVideoCall: _disconnectVideoCall,
                messageFunction: _videoMessageFunction,
                switchCamera: _switchCameraFunction,
                videoFunction: _videoFunction,
              )));
    }
    ChatMode = 0;
    _isShowMinMax = false;
    if (minmaxButtonKey.currentState != null) {
      minmaxButtonKey.currentState.setShow(_isShowMinMax);
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        body: SafeArea(
          child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: ColorMap.backgroundColor,
              ),
              child: loading
                  ? Center(
                      child: SizedBox(
                        width: width / 3 * 2,
                        height: width / 3 * 2,
                        child: Stack(
                          children: <Widget>[
                            Positioned.fill(child: LoadingAnimationWidget()),
                            Positioned.fill(
                              child: Padding(
                                padding: EdgeInsets.all(60.0),
                                child: Image.asset(
                                  "assets/sign_up_waiting.png",
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                  : Stack(
                      children: <Widget>[
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: ColorMap.backgroundColor,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                AppBar(
                                  backgroundColor: ColorMap.backgroundColor,
                                  title: Text(
                                    sprintf("%s%s", ["ID: ", this.widget.custom]),
                                    style: TextStyle(color: Colors.white, fontSize: 25.0, fontWeight: FontWeight.normal),
                                  ),
                                  centerTitle: true,
                                  leading: InkWell(
                                    onTap: () {
                                      _onBackPressed();
                                    },
                                    child: Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                      size: 25,
                                    ),
                                  ),
                                  actions: <Widget>[
                                    InkWell(
                                      onTap: () {
                                        if (ChatMode == 0) {
                                          _placeCall(isVideo: false);
                                        }
                                      },
                                      child: SizedBox(
                                        width: 30,
                                        height: 30,
                                        child: FittedBox(
                                          child: Image.asset(
                                            "assets/voice_call.png",
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 15,
                                    ),
                                    InkWell(
                                      onTap: () {
                                        if (ChatMode == 0) {
                                          _placeCall(isVideo: true);
                                        }
                                      },
                                      child: SizedBox(
                                        width: 30,
                                        height: 30,
                                        child: FittedBox(
                                          child: Image.asset(
                                            "assets/video_call.png",
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 15,
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: Stack(
                                    children: <Widget>[
                                      Positioned.fill(
                                        child: ListView.builder(
                                            itemBuilder: (context, index) {
                                              return InkWell(
                                                onTap: (){
                                                  _onMessageClick(messages[index]);
                                                },
                                                child: MessageView(
                                                  key: messages[index].key,
                                                  message: messages[index],
                                                ),
                                              );
                                            },
                                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            controller: _scrollController,
                                            reverse: true,
                                            addAutomaticKeepAlives: true,
                                            itemCount: messages.length),
                                      ),
                                      Positioned(
                                        bottom: 40,
                                        right: 20,
                                        child: DownloadProgressWidget(
                                          key: downloadWidgetKey,
                                        ),
                                      ),
                                      Positioned(
                                        top: 20,
                                        right: 20,
                                        child: MinMaxButton(
                                          key: minmaxButtonKey,
                                          show: _isShowMinMax,
                                          callBack: () {
                                            _minMaxButtonHandler();
                                          },
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  height: 60,
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: ColorMap.backgroundColor, boxShadow: [BoxShadow(color: ColorMap.backgroundColorHover, spreadRadius: 2.0, offset: Offset(1.0, 0.0), blurRadius: 1.0)]),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 5),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          InkWell(
                                            child: Icon(
                                              Icons.add,
                                              color: Colors.white,
                                              size: 40,
                                            ),
                                            onTap: () {
                                              _showAttachFileDialog();
                                            },
                                          ),
                                          Expanded(
                                            child: Container(
                                              padding: EdgeInsets.symmetric(horizontal: 5),
                                              child: TextFormField(
                                                controller: _messageController,
                                                textInputAction: TextInputAction.done,
                                                onFieldSubmitted: (term) {
                                                  sendTextMessage();
                                                },
                                                minLines: 1,
                                                style: TextStyle(color: Colors.white, fontSize: 16.0, fontStyle: FontStyle.normal),
                                                decoration:
                                                    InputDecoration.collapsed(hintText: "Type your message", hintStyle: TextStyle(color: Colors.grey, fontSize: 16.0, fontWeight: FontWeight.normal)),
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            child: Icon(
                                              Icons.send,
                                              color: Color.fromARGB(255, 0, 132, 255),
                                              size: 40,
                                            ),
                                            onTap: () {
                                              sendTextMessage();
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        Visibility(
                          visible: false,
                          child: Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(color: ColorMap.backgroundColor),
                            ),
                          ),
                        )
                      ],
                    )),
        ),
      ),
    );
  }
}
