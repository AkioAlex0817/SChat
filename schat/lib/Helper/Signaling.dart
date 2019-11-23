import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:schat/main.dart';

import 'Constants.dart';


enum SignalingState {
  CallStateNew,
  CallStateRinging,
  CallStateInvite,
  CallStateConnected,
  CallStateDisconnected,
  CallStateBye,
  ConnectionOpen,
  ConnectionClosed,
  ConnectionError,
}

typedef void SignalingStateCallback(SignalingState state);
typedef void StreamStateCallback(MediaStream stream);
typedef void DataChannelMessageCallback(RTCDataChannelMessage data);
typedef void DataChannelFileCallback(RTCDataChannelMessage data);
typedef void DataChannelCallback(RTCDataChannel dc);
typedef void OnIceConnected();
typedef void OnIceDisconnected();
typedef void ReportError(String msg);
typedef void Disconnect();
typedef void OnPeerConnectionClosed();


class Signaling{
  RTCPeerConnection _peerConnection;
  RTCDataChannel _localMessageDataChannel;
  RTCDataChannel _localFileDataChannel;

  RTCDataChannel _remoteMessageDataChannel;
  RTCDataChannel _remoteFileDataChannel;



  MediaStream _localStream;
  MediaStream _remoteStream;

  SignalingStateCallback onStateChange;
  StreamStateCallback onLocalStream;
  StreamStateCallback onAddRemoteStream;
  StreamStateCallback onRemoveRemoteStream;
  DataChannelMessageCallback onDataChannelMessage;
  DataChannelFileCallback onDataChannelFile;
  DataChannelCallback onDataChannel;

  OnIceConnected onIceConnected;
  OnIceDisconnected onIceDisconnected;
  Disconnect onDisconnect;
  OnPeerConnectionClosed onPeerConnectionClosed;
  ReportError reportError;

  var _remoteCandidates = [];
  Timer _mMyHandler;
  bool onlyCall = false;

  final isInitiator;
  final room;
  final code;
  Signaling({@required this.isInitiator, @required this.room, @required this.code});

  RTCPeerConnection get peerConnection => _peerConnection;

  Map<String, dynamic> _iceServers = {
    "iceServers" : [
      {'url': 'stun:stun.l.google.com:19302'},
      {'url' : 'stun:global.stun.twilio.com:3478?transport=udp'},
      {'url' : 'turn:global.turn.twilio.com:3478?transport=udp', 'username' : '0593907d6b42ef2072cd84219cf265bb8ae7a4c556d7dd108f93a2506d527748', 'credential' : '/8OigiobAXHnCcmhFQ4E49WO5aZB696/INcC9vaP7iY='},
      {'url' : 'turn:global.turn.twilio.com:3478?transport=tcp', 'username' : '0593907d6b42ef2072cd84219cf265bb8ae7a4c556d7dd108f93a2506d527748', 'credential' : '/8OigiobAXHnCcmhFQ4E49WO5aZB696/INcC9vaP7iY='},
      {'url' : 'turn:global.turn.twilio.com:443?transport=tcp', 'username' : '0593907d6b42ef2072cd84219cf265bb8ae7a4c556d7dd108f93a2506d527748', 'credential' : '/8OigiobAXHnCcmhFQ4E49WO5aZB696/INcC9vaP7iY='},
      {'url' : 'stun:64.233.188.127:19302'},
      {'url' : 'turn:74.125.23.127:19305?transport=udp', 'username' : 'CJCU0uEFEgY3byO+QRgYzc/s6OMTIICjBQ', 'credential' : 'r7ltb22WlMkTCsypwFn+pOgOfrY='},
      {'url' : 'stun:47.75.201.142:3478', 'username' : 'webrtc', 'credential' : 'webrtc'},
    ]
  };

  final Map<String, dynamic> _config = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  final Map<String, dynamic> _constraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };

  void connect() async{
    try{
      if(this.onStateChange != null){
        this.onStateChange(SignalingState.ConnectionOpen);
      }
      MyApp.signalServer.socketIO.on("message", (data) => _socketMessage(data));
      MyApp.signalServer.socketIO.on("req-leave-room", (data) => _leaveRoom(data));
      if(this.isInitiator){
        // Master 일때
        //1초에 한번씩 roomReady메씨지를 보낸다. 해당 응답자가 같은 메씨지로 응답하는 경우에만 peerConnection련결 시도
        _mMyHandler = Timer.periodic(Duration(seconds: 1), (Timer t) => _sendReadyMessage());
      }
    }catch(error){
      if(this.onStateChange != null){
        this.onStateChange(SignalingState.ConnectionError);
      }
    }
  }

  void clearSocket(){
    MyApp.signalServer.socketIO.off("message");
    MyApp.signalServer.socketIO.off("req-leave-room");
  }

  _leaveRoom(dynamic data) async {
    if(this.onDisconnect != null){
      this.onDisconnect();
    }
  }

  _socketMessage(dynamic data) async{
    print("OnSocketMessage");
    print(data);
    if(data['from'] != null && data['from'] != this.code){ // 자신이 보낸 소케트가 아닌 경우에만
      var message = data['message'];
      print(message['type']);
      switch(message['type']){
        case Constants.GETREADY:
          if(this.isInitiator){
            _mMyHandler?.cancel();
            if(!onlyCall){
              invite();
            }
          }else{
            _sendReadyMessage();
          }
          break;
        case Constants.SEND_OFFER_SDP:
          if(!onlyCall){
            this.onlyCall = true;
            if(this.onStateChange != null){
              this.onStateChange(SignalingState.CallStateNew);
            }
            RTCPeerConnection pc = await _createPeerConnection();
            _createClientDataChannel(pc);
            this._peerConnection = pc;
            await pc.setRemoteDescription(new RTCSessionDescription(message['payload']['sdp'], message['payload']['type']));
            await _createAnswer(pc);
            if(this._remoteCandidates.length > 0){
              _remoteCandidates.forEach((candidate) async{
                await pc.addCandidate(candidate);
              });
              _remoteCandidates.clear();
            }
          }
          break;
        case Constants.SEND_ANSWER_SDP:
          if(_peerConnection != null){
            await _peerConnection.setRemoteDescription(new RTCSessionDescription(message['payload']['sdp'], message['payload']['type']));
          }
          break;
        case Constants.ADDCANDIDATE:
          RTCIceCandidate candidate = new RTCIceCandidate(message['payload']['candidate'], message['payload']['sdpMid'], message['payload']['sdpMLineIndex']);
          if(_peerConnection != null){
            await _peerConnection.addCandidate(candidate);
          }else{
            _remoteCandidates.add(candidate);
          }
          break;
        case Constants.DISCONNECT:
          break;
      }
    }
  }

  void _sendReadyMessage() {
    MyApp.signalServer.socketIO.emit("message", [
      {
        "room": this.room,
        "message": {"type": Constants.GETREADY}
      }
    ]);
  }

  void switchCamera(){
    if(_localStream != null){
      _localStream.getVideoTracks()[0].switchCamera();
    }
  }

  void voiceSet(bool isTurn){
    if(_localStream != null){
      _localStream.getAudioTracks()[0].enabled = isTurn;
    }
  }

  void speakSet(bool isTurn){
    _localStream.getAudioTracks()[0].enableSpeakerphone(isTurn);
  }

  void videoSet(bool isTurn){
    if(_localStream != null){
      _localStream.getVideoTracks()[0].enabled = isTurn;
    }
  }

  void setIceServers(Map<String, dynamic> servers){
    this._iceServers = servers;
  }

  void sendMessage(dynamic data){
    if(_localMessageDataChannel != null){
      print("send message");
      _localMessageDataChannel.send(new RTCDataChannelMessage.fromBinary(data));
    }
  }

  void sendFile(dynamic data){
    if(_localFileDataChannel != null){
      print("file send");
      _localFileDataChannel.send(new RTCDataChannelMessage.fromBinary(data));
    }
  }
  _createPeerConnection() async{
    _localStream = await createStream();
    RTCPeerConnection pc = await createPeerConnection(_iceServers, _config);
    pc.addStream(_localStream);
    pc.onIceCandidate = (candidate){
      MyApp.signalServer.socketIO.emit("message", [{
        "room" : this.room,
        "message" : {
          "type" : Constants.ADDCANDIDATE,
          "payload" : {
            "sdpMLineIndex" : candidate.sdpMlineIndex,
            "sdpMid" : candidate.sdpMid,
            "candidate" : candidate.candidate,
          }
        }
      }]);
    };

    pc.onIceConnectionState = (state){
      switch(state){
        case RTCIceConnectionState.RTCIceConnectionStateConnected:
          print("OnIceConnected");
          if(this.onIceConnected != null){
            this.onIceConnected();
          }
          break;
        case RTCIceConnectionState.RTCIceConnectionStateFailed:
          print("OnIceFailed");
          if(this.reportError != null){
            this.reportError("ICE connection failed");
          }
          break;
        case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
          print("OnIceDisconnected");
          if(this.onIceDisconnected != null){
            this.onIceDisconnected();
          }
          break;
        default:
          break;
      }
    };

    pc.onAddStream = (stream){
      if(this.onAddRemoteStream != null) this.onAddRemoteStream(stream);
    };

    pc.onRemoveStream = (stream){
      if(this.onRemoveRemoteStream != null) this.onRemoveRemoteStream(stream);
      _remoteStream = null;
    };



    pc.onDataChannel = (RTCDataChannel channel){
      List<String> channelname = channel.label.split("_");
      if(channelname[1] == "1"){
        channel.onMessage = (RTCDataChannelMessage data){
          if(this.onDataChannelMessage != null){
            this.onDataChannelMessage(data);
          }
        };
        _remoteMessageDataChannel = channel;

      }else{
        channel.onMessage = (RTCDataChannelMessage data){
          if(this.onDataChannelFile  != null){
            this.onDataChannelFile(data);
          }
        };
        _remoteFileDataChannel = channel;
      }


    };

    return pc;
  }

  _createMasterDataChannel(RTCPeerConnection pc) async{
    this._localMessageDataChannel = await this._createDataChannel(pc, "1_1", 100);
    this._localFileDataChannel = await this._createDataChannel(pc, "1_2", 101);
  }

  _createClientDataChannel(RTCPeerConnection pc) async{
    this._localMessageDataChannel = await this._createDataChannel(pc, "2_1", 102);
    this._localFileDataChannel = await this._createDataChannel(pc, "2_2", 103);
  }

  Future<MediaStream> createStream() async{
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {
        'mandatory': {
          'minWidth': '640', // Provide your own width, height and frame rate here
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
        'optional': [],
      }
    };

    MediaStream stream = await navigator.getUserMedia(mediaConstraints);
    if(this.onLocalStream != null){
      this.onLocalStream(stream);
    }

    return stream;
  }

  Future<RTCDataChannel> _createDataChannel(RTCPeerConnection pc, String label, int channelID) async{
    RTCDataChannelInit dataChannelDict = new RTCDataChannelInit();
    dataChannelDict.id = channelID;
    RTCDataChannel channel = await pc.createDataChannel(label, dataChannelDict);
    return channel;
  }

  _createOffer(RTCPeerConnection pc) async{
    try{
      RTCSessionDescription description = await pc.createOffer(_constraints);
      pc.setLocalDescription(description);
      MyApp.signalServer.socketIO.emit("message", [{
        "room" : this.room,
        "message" : {
          "type" : Constants.SEND_OFFER_SDP,
          "payload" : {
            "type" : description.type,
            "sdp" : description.sdp
          }
        }
      }]);
    }catch (e){
      print(e.toString());
    }
  }

  _createAnswer(RTCPeerConnection pc) async{
    try{
      RTCSessionDescription description = await pc.createAnswer(_constraints);
      pc.setLocalDescription(description);
      MyApp.signalServer.socketIO.emit("message", [{
        "room" : this.room,
        "message" : {
          "type" : Constants.SEND_ANSWER_SDP,
          "payload" : {
            "type" : description.type,
            "sdp" : description.sdp
          }
        }
      }]);
    }catch (e){
      print(e.toString());
    }
  }

  closeInternal() async{
    print("Closing peer connection");
    if(_localStream != null){
      await _localStream.dispose();
      _localStream = null;
    }
    if(_localMessageDataChannel != null){
      await _localMessageDataChannel.close();
      _localMessageDataChannel = null;
    }
    if(_localFileDataChannel != null){
      await _localFileDataChannel.close();
      _localFileDataChannel = null;
    }
    if(_remoteMessageDataChannel != null){
      await _remoteMessageDataChannel.close();
      _remoteMessageDataChannel = null;
    }

    if(_remoteFileDataChannel != null){
      await _remoteFileDataChannel.close();
      _remoteFileDataChannel = null;
    }

    if(_peerConnection != null){
      _peerConnection.close();
      _peerConnection = null;
    }
    if(this.onPeerConnectionClosed != null){
      this.onPeerConnectionClosed();
    }
  }

  invite(){
    onlyCall = true;
    if(this.onStateChange != null){
      this.onStateChange(SignalingState.CallStateNew);
    }
    _createPeerConnection().then((pc){
      _peerConnection = pc;
      _createMasterDataChannel(pc);
      _createOffer(pc);
    });
  }

}

