import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'pmo_button.dart';

class PMOEmptyState extends StatelessWidget {
  final Widget? illustration;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const PMOEmptyState({
    super.key,
    this.illustration,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (illustration != null) ...[
              SizedBox(
                width: 120,
                height: 120,
                child: illustration,
              ),
              const SizedBox(height: 24),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textMute,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              PMOButton(
                actionLabel!,
                onPressed: onAction,
                width: double.infinity,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
