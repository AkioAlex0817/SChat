import 'package:flutter/material.dart';

class GridViewItem extends StatelessWidget{

  final String iconPath;
  final String title;


  GridViewItem({this.iconPath, this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Flexible(
            flex: 4,
            child: Image.asset(iconPath, fit: BoxFit.cover,),
          ),
          Flexible(
            flex: 1,
            child: Text(title, style: TextStyle(color: Colors.black, fontSize: 15),),
          )
        ],
      ),
    );
  }
}