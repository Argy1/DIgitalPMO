import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PMOLabel extends StatelessWidget {
  final String label;
  final Color? color;
  final TextStyle? customStyle;

  const PMOLabel(
    this.label, {
    super.key,
    this.color,
    this.customStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: customStyle ??
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: color ?? AppColors.textMute,
          ),
    );
  }
}
