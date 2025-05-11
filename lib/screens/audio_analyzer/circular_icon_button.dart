import 'package:flutter/material.dart';

class CircularIconButton extends StatelessWidget {
  const CircularIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.isGlowing,
    required this.color,
    super.key,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isGlowing;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: isGlowing ? color.withAlpha(128): color.withAlpha(100),
            blurRadius: isGlowing ? 20 : 12,
            spreadRadius: isGlowing? 4: 1,
          )
        ],
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: icon,
      ),
    );
  }
}
