import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

enum ButtonVariant { primary, success, amber, ghost }

class PMOButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final bool isDisabled;
  final double? width;
  final IconData? icon;

  const PMOButton(
    this.label, {
    super.key,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.isDisabled = false,
    this.width,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getVariantConfig(variant);
    final isClickable = !isDisabled && !isLoading && onPressed != null;

    return Semantics(
      button: true,
      enabled: !isDisabled && !isLoading,
      label: label,
      child: SizedBox(
        width: width,
        height: AppDimensions.btnHeight,
        child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.btnRadius),
          gradient: isDisabled ? null : config['gradient'] as Gradient?,
          color: isDisabled ? AppColors.border : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isClickable ? onPressed : null,
            borderRadius: BorderRadius.circular(AppDimensions.btnRadius),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          config['textColor'] as Color,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(
                            icon,
                            color: config['textColor'] as Color,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: config['textColor'] as Color,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getVariantConfig(ButtonVariant variant) {
    switch (variant) {
      case ButtonVariant.primary:
        return {
          'gradient': AppColors.primaryGradient,
          'textColor': Colors.white,
        };
      case ButtonVariant.success:
        return {
          'gradient': AppColors.successGradient,
          'textColor': Colors.white,
        };
      case ButtonVariant.amber:
        return {
          'gradient': AppColors.amberGradient,
          'textColor': Colors.white,
        };
      case ButtonVariant.ghost:
        return {
          'gradient': null,
          'textColor': AppColors.primary,
          'backgroundColor': Colors.transparent,
        };
    }
  }
}
