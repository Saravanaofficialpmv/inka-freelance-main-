import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class InkaBrandLogo extends StatelessWidget {
  final double fontSize;
  final Color barColor;
  final Color textColor;
  final bool animate;

  const InkaBrandLogo({
    super.key,
    this.fontSize = 44,
    this.barColor = AppColors.primary,
    this.textColor = AppColors.textPrimary,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) {
    final barWidth = fontSize * 0.32;
    final barHeight = fontSize * 0.88;
    final spacing = fontSize * 0.36;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Slanted Orange Bar Accent (Slash)
        Transform(
          transform: Matrix4.skewX(-0.32),
          child: Container(
            width: barWidth,
            height: barHeight,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(barWidth * 0.25),
            ),
          ),
        ),
        SizedBox(width: spacing),
        // inka Lowercase Bold Wordmark
        Text(
          'inka',
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.8,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}
