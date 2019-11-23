import 'package:flutter/material.dart';
import 'dart:math' as math;

class LoadingPainter extends CustomPainter {
  final Color foreColor;
  final Color backColor;
  final double stick;

  LoadingPainter({this.foreColor, this.backColor, this.stick});

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;

  @override
  void paint(Canvas canvas, Size size) {
    double width = size.width;
    double height = size.width;

    Paint paint = new Paint();
    paint.color = foreColor;
    paint.strokeWidth = stick;
    paint.isAntiAlias = true;
    paint.style = PaintingStyle.stroke;

    canvas.drawArc(Rect.fromLTRB(0, 0, width, width), -math.pi / 2, math.pi, false, paint);

    paint.color = backColor;

    canvas.drawArc(Rect.fromLTRB(0, 0, width, width), math.pi / 2, math.pi, false, paint);

  }
}
