import 'package:flutter/material.dart';
import 'package:shirr/core/constants.dart';

class DiskDialogue extends StatefulWidget{
  final String message;
  const DiskDialogue({required this.message, super.key});

  @override
  State<DiskDialogue> createState() => _DiskDialogueState();
}

class _DiskDialogueState extends State<DiskDialogue> with SingleTickerProviderStateMixin {

  late final AnimationController _animationController;
  late Animation<double> _radiusAnim;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 700),
      reverseDuration: Duration(milliseconds: 400)
    );

    _radiusAnim = CurvedAnimation(
      parent: _animationController,
      curve: Curves.decelerate);

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  final double maxRadius = 300.0;

  @override
  Widget build(BuildContext context) {
    final isDark = (Theme.of(context).brightness == Brightness.dark)? true: false;

    return Scaffold(
      backgroundColor: isDark? Colors.black.withAlpha(0): Colors.white.withAlpha(0),
      body: GestureDetector(
        onTap: () => _animationController.reverse().then((_) {
          Navigator.of(context).pop();
        }),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedBuilder(
            animation: _radiusAnim,
            builder: (_, _) {
              return CustomPaint(
                painter: RadialDialoguePainter(
                  progress: _radiusAnim.value,
                  maxRadius: maxRadius,
                  numRings: 5,
                  isDark: isDark,
                  message: widget.message,
                ),
              );
            }),
        ),
      ),
    );
  }
}

class RadialDialoguePainter extends CustomPainter {
  final double progress;
  final double maxRadius;
  final int numRings;
  final bool isDark;
  final String message;

  RadialDialoguePainter({
    required this.progress,
    required this.maxRadius,
    required this.numRings,
    required this.isDark,
    required this.message
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width/2, size.height/2);

    for (int i = numRings - 1; i>=0; i--) {
      final radius = progress * maxRadius * (1-i/numRings);
      final alpha = ((i+1)/numRings * 255).toInt();
      final paint = Paint()
        ..color = (isDark? Colors.white: Colors.black).withAlpha(alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, radius, paint);
    }

    if (progress > 0.99) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: message,
          style: TextStyle(
            color: isDark? Colors.black: Colors.white,
            fontFamily: Constants.fontFamilyBody,
            fontSize: Constants.fontSizeDialog,
            fontWeight: FontWeight.bold
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr
      );
      textPainter.layout(
        maxWidth: maxRadius * 0.8
      );
      textPainter.paint(
        canvas,
        center - Offset(textPainter.width/2, textPainter.height/2)
      );
    }
  }

  @override
  bool shouldRepaint(covariant RadialDialoguePainter oldDelegate) => oldDelegate.progress != progress;
}