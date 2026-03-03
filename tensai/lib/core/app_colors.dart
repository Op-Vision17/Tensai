import 'package:flutter/material.dart';

/// App color palette and gradients.
class AppColors {
  AppColors._();

  static const Color surface = Color(0xFF0d1526);
  static const Color border = Color(0xFF1e2d4a);
  static const Color subtitle = Color(0xFF64748b);
  static const Color primary = Color(0xFF6366f1);
  static const Color primaryDark = Color(0xFF4f46e5);
  static const Color focusBorder = Color(0xFF818cf8);
  static const Color errorBorder = Color(0xFFf87171);
  static const Color success = Color(0xFF4ade80);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
