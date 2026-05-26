import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PMOMedPill extends StatelessWidget {
  final String kind; // R, H, Z, E
  final double size;
  final bool showLabel;

  const PMOMedPill({
    super.key,
    required this.kind,
    this.size = 32,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getMedColor(kind);
    final name = AppColors.getMedName(kind);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(0.3, 0.25),
              radius: 1.0,
              colors: [
                color,
                color.withValues(alpha: 0.85),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.33),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Text(
              kind,
              style: TextStyle(
                fontSize: size * 0.44,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 6),
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMute,
            ),
          ),
        ],
      ],
    );
  }
}
