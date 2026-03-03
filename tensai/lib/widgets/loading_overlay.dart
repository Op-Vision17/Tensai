import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  static const Color _overlayColor = Color(0x99000000); // #000 at 60% opacity
  static const Color _indicatorColor = Color(0xFF6366f1);

  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: _overlayColor,
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_indicatorColor),
              ),
            ),
          ),
      ],
    );
  }
}
