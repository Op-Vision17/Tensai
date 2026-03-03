import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Consistent InputDecoration for all TextFields.
class InputStyles {
  InputStyles._();

  static const Color fillColor = Color(0xFF0a0f1e);
  static const Color borderColor = Color(0xFF1e2d4a);
  static const Color hintColor = Color(0xFF64748b);

  static InputDecoration standard({
    String? labelText,
    String? hintText,
    String? errorText,
    Widget? suffix,
  }) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: borderColor),
    );
    return InputDecoration(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.focusBorder, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.errorBorder),
      ),
      hintStyle: GoogleFonts.spaceGrotesk(color: hintColor, fontSize: 14),
      labelStyle: GoogleFonts.spaceGrotesk(color: hintColor),
      suffix: suffix,
    );
  }

  static InputDecoration otp() {
    return standard(hintText: '000000').copyWith(
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
    );
  }
}
