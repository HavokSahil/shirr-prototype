import 'package:flutter/material.dart';

class ThemeColors {
  final Color bgColor;
  final Color textColor;
  final Color panelPrimary;
  final Color panelSecondary;
  final Color sliderDot;
  final Color sliderTrack;
  final Color flanks;

  ThemeColors._({
    required this.bgColor,
    required this.textColor,
    required this.panelPrimary,
    required this.panelSecondary,
    required this.sliderDot,
    required this.sliderTrack,
    required this.flanks,
  });

  factory ThemeColors.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ThemeColors._(
      bgColor: isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
      textColor: isDark ? const Color(0xFFD5D5D5) : const Color(0xFF1A1A1A),
      panelPrimary: isDark ? const Color(0xFF303030) : const Color(0xFF1E1E1E),
      panelSecondary: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0F0F0),
      sliderDot: isDark ? const Color(0xFFE9E9E9) : const Color(0xFF303030),
      sliderTrack: isDark ? const Color(0xFFAEAEAE) : const Color(0xFF9C9C9C),
      flanks: isDark ? const Color(0xFF303030) : const Color(0xFF000000),
    );
  }
}
