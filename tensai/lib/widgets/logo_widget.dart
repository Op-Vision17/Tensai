import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// Tensai logo with background removed, for use in app bars.
class AppBarLogo extends StatelessWidget {
  const AppBarLogo({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Image.asset(
        'assets/app_icon_bgremove.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(Icons.school_rounded, size: size, color: AppColors.subtitle),
      ),
    );
  }
}

/// Full Tensai logo image for screens (e.g. Send OTP, Verify OTP).
class LogoWidget extends StatelessWidget {
  const LogoWidget({super.key, this.width = 80});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo_bg_remove.png',
      width: width,
      height: width,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/app_icon_bgremove.png',
        width: width,
        height: width,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(Icons.school_rounded, size: width, color: AppColors.subtitle),
      ),
    );
  }
}
