import 'package:flutter/material.dart';
import 'package:schat/CustomPainter/LoadingPainter.dart';
import 'package:schat/Helper/ColorMap.dart';

class LoadingAnimationWidget extends StatefulWidget{


  @override
  LoadingAnimationWidgetState createState() => LoadingAnimationWidgetState();
}

class LoadingAnimationWidgetState extends State<LoadingAnimationWidget> with TickerProviderStateMixin{

  AnimationController _animationController;

  @override
  void initState() {
    _animationController = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this,);
    super.initState();
    startAnimation();
  }

  void startAnimation(){
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: RotationTransition(
              turns: Tween(begin: 0.0, end: 1.0).animate(_animationController),
              child: CustomPaint(
                painter: LoadingPainter(
                    stick: 4.0,
                    foreColor: ColorMap.progressColor,
                    backColor: ColorMap.progressBackColor
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}