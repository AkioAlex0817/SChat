import 'package:adhara_socket_io/adhara_socket_io.dart';
import 'package:schat/Helper/Constants.dart';

typedef onConnectHandler = void Function(dynamic data);
typedef onConnectingHandler = void Function();
typedef onDisconnectHandler = void Function();
typedef onErrorHandler = void Function();
typedef onConnectErrorHandler = void Function();
typedef onTimeoutHandler = void Function();

class SignalServer{

  final onConnectHandler connectHandler;
  final onDisconnectHandler disconnectHandler;
  final onErrorHandler errorHandler;
  final onConnectErrorHandler connectErrorHandler;
  final onTimeoutHandler timeoutHandler;
  final onConnectingHandler connectingHandler;


  SignalServer({this.connectingHandler, this.connectHandler, this.disconnectHandler, this.errorHandler, this.connectErrorHandler, this.timeoutHandler});

  SocketIO socketIO;

  void connectServer() async{
    this.socketIO = await SocketIOManager().createInstance(SocketOptions(Constants.signalServerURL, nameSpace: "/"));
    socketIO.onConnect((data){
      connectHandler(data);
    });
    socketIO.onDisconnect((_){
      disconnectHandler();
    });
    socketIO.onError((_){
      print(_);
      errorHandler();
    });
    socketIO.onConnectError((_){
      print(_);
      connectErrorHandler();
    });
    socketIO.onConnectTimeout((_){
      timeoutHandler();
    });

    socketIO.onConnecting((_){
      connectingHandler();
    });

    socketIO.connect();
  }
}