import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class PMOCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;
  final Color? backgroundColor;
  final Border? border;

  const PMOCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.constraints,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      constraints: constraints,
      padding: padding ?? const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: border ?? Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          child: card,
        ),
      );
    }

    return card;
  }
}
