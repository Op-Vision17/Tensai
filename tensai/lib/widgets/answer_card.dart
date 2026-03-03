import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';

class AnswerCard extends StatelessWidget {
  const AnswerCard({
    super.key,
    required this.answer,
    this.keyPoints = const [],
    this.confidence = 0.0,
    this.sources = const [],
  });

  final String answer;
  final List<String> keyPoints;
  final double confidence;
  final List<String> sources;

  static const Color _chipBg = Color(0xFF0a0f1e);

  Color _confidenceColor() {
    if (confidence >= 0.7) return const Color(0xFF22c55e);
    if (confidence >= 0.4) return const Color(0xFFf97316);
    return const Color(0xFFef4444);
  }

  @override
  Widget build(BuildContext context) {
    final confColor = _confidenceColor();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              'Answer',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: confColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: confColor, width: 1),
              ),
              child: Text(
                '${(confidence * 100).round()}%',
                style: GoogleFonts.spaceGrotesk(
                  color: confColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SelectableText(
          answer,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white70,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 16),
        const Divider(color: Color(0xFF1e2d4a), height: 1),
        const SizedBox(height: 16),
        Text(
          'Key Points',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        if (keyPoints.isEmpty)
          Text(
            '—',
            style: GoogleFonts.spaceGrotesk(color: AppColors.subtitle, fontSize: 14),
          )
        else
          ...keyPoints.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: GoogleFonts.spaceGrotesk(color: AppColors.border),
                  ),
                  Expanded(
                    child: SelectableText(
                      p,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          'Sources',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        if (sources.isEmpty)
          Text(
            '—',
            style: GoogleFonts.spaceGrotesk(color: AppColors.subtitle, fontSize: 14),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sources
                .map(
                  (s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _chipBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.focusBorder),
                    ),
                    child: Text(
                      s,
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.focusBorder,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
