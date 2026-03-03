import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// App theme configuration.
class AppTheme {
  AppTheme._();

  static TextTheme _textTheme(Color onSurface, Brightness brightness) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    return GoogleFonts.spaceGroteskTextTheme(base).copyWith(
      bodyLarge: base.bodyLarge?.copyWith(color: onSurface),
      bodyMedium: base.bodyMedium?.copyWith(color: onSurface),
      bodySmall: base.bodySmall?.copyWith(color: onSurface),
      labelLarge: base.labelLarge?.copyWith(color: onSurface),
      labelMedium: base.labelMedium?.copyWith(color: onSurface),
      labelSmall: base.labelSmall?.copyWith(color: onSurface),
      titleLarge: base.titleLarge?.copyWith(color: onSurface),
      titleMedium: base.titleMedium?.copyWith(color: onSurface),
      titleSmall: base.titleSmall?.copyWith(color: onSurface),
      headlineLarge: base.headlineLarge?.copyWith(color: onSurface),
      headlineMedium: base.headlineMedium?.copyWith(color: onSurface),
      headlineSmall: base.headlineSmall?.copyWith(color: onSurface),
    );
  }

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        textTheme: _textTheme(Colors.black87, Brightness.light),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0a0f1e),
        textTheme: _textTheme(Colors.white, Brightness.dark),
      );
}
