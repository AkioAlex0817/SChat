import 'package:flutter/material.dart';

class PatternProgressWidget extends StatefulWidget{

  final Key key;
  final List<int> status;


  PatternProgressWidget({this.key, this.status}) : super(key : key);

  @override
  PatternProgressWidgetState createState() => PatternProgressWidgetState();
}

class PatternProgressWidgetState extends State<PatternProgressWidget>{

  List<int> progress = [];


  @override
  void initState() {
    super.initState();
    progress = this.widget.status;
  }

  void checkResult(List<int> check){
    setState(() {
      progress = check;
    });
  }

  List<Widget> _buildWidget(){
    List<Widget> result = [];
    for(int i = 0; i < progress.length; i++){
      if(progress[i] == 0){
        result.add(Icon(Icons.close, color: Colors.red, size: 25,));
      }else{
        result.add(Icon(Icons.check, color: Colors.green, size: 25,));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      constraints: BoxConstraints.expand(),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _buildWidget(),
      ),
    );
  }
}