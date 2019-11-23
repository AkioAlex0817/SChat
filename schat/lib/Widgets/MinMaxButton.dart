import 'package:flutter/material.dart';
import 'package:schat/Helper/ColorMap.dart';

typedef CallBack = void Function();
class MinMaxButton extends StatefulWidget{

  final Key key;
  final bool show;
  final CallBack callBack;


  MinMaxButton({this.key, this.show, this.callBack}) : super(key : key);

  @override
  MinMaxButtonState createState() => MinMaxButtonState(show);
}

class MinMaxButtonState extends State<MinMaxButton>{

  bool _show;

  setShow(bool val){
    if(mounted){
      setState(() {
        _show = val;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _show ? InkWell(
      onTap: (){
        this.widget.callBack();
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(5.0)),
            border: Border.all(
                color: ColorMap.buttonColor,
                width: 2.0,
                style: BorderStyle.solid
            )
        ),
        padding: EdgeInsets.all(5),
        child: Icon(Icons.zoom_out_map, color: Colors.white, size: 25,),
      ),
    ) : Container();
  }

  MinMaxButtonState(this._show);
}