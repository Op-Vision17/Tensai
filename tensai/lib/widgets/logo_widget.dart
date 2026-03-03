import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class LogoWidget extends StatelessWidget {
  const LogoWidget({super.key, this.width = 80});

  final double width;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => AppColors.brandGradient.createShader(bounds),
      child: Icon(Icons.school_rounded, size: width, color: Colors.white),
    );
  }
}
