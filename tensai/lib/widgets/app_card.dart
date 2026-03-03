import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';

/// Styled card for content sections (Tensai brand).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.title,
    this.titleIcon,
    this.margin,
    this.padding,
  });

  final Widget child;
  final String? title;
  final IconData? titleIcon;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  static const EdgeInsets defaultMargin = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const EdgeInsets defaultPadding = EdgeInsets.all(20);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? defaultMargin,
      child: Card(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        child: Padding(
          padding: padding ?? defaultPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null || titleIcon != null) ...[
                Row(
                  children: [
                    if (titleIcon != null) ...[
                      Icon(titleIcon, size: 22, color: AppColors.subtitle),
                      const SizedBox(width: 10),
                    ],
                    if (title != null)
                      Expanded(
                        child: Text(
                          title!,
                          style: GoogleFonts.spaceGrotesk(
                            color: const Color(0xFF888888),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}
