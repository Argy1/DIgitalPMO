import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PMOBadge extends StatelessWidget {
  final String label;
  final BadgeTone tone;
  final bool showDot;
  final TextStyle? textStyle;

  const PMOBadge({
    super.key,
    required this.label,
    this.tone = BadgeTone.teal,
    this.showDot = false,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getToneConfig(tone);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config['bg'] as Color,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: config['dot'] as Color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          Text(
            label,
            style: textStyle ??
                TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: config['fg'] as Color,
                ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getToneConfig(BadgeTone tone) {
    switch (tone) {
      case BadgeTone.teal:
        return {
          'bg': AppColors.tealSoft,
          'fg': AppColors.primary,
          'dot': AppColors.primary,
        };
      case BadgeTone.amber:
        return {
          'bg': AppColors.amberSoft,
          'fg': const Color(0xFFA66A00),
          'dot': AppColors.amber,
        };
      case BadgeTone.success:
        return {
          'bg': const Color(0xFFE6F4EC),
          'fg': const Color(0xFF137A3F),
          'dot': AppColors.success,
        };
      case BadgeTone.danger:
        return {
          'bg': const Color(0xFFFBE5E2),
          'fg': const Color(0xFFA1281C),
          'dot': AppColors.danger,
        };
      case BadgeTone.mute:
        return {
          'bg': const Color(0xFFEEF2F0),
          'fg': AppColors.textMute,
          'dot': AppColors.textMute,
        };
    }
  }
}

enum BadgeTone { teal, amber, success, danger, mute }
