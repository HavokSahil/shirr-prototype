import 'package:flutter/material.dart';

class WaveFormPainter extends CustomPainter{
  final List<double> pcmBuffer;
  
  WaveFormPainter(this.pcmBuffer);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    double xInterval = size.width / pcmBuffer.length;
    double centerY = size.height / 2;
    Path path = Path();
    for (int i = 0; i<pcmBuffer.length; i++) {
      double x = i * xInterval;
      double y = centerY - pcmBuffer[i] * centerY;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}