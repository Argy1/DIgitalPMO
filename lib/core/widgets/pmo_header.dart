import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class PMOHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? rightAction;
  final List<Widget>? children;
  final bool tall;

  const PMOHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.rightAction,
    this.children,
    this.tall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDeep,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppDimensions.cardRadius),
          bottomRight: Radius.circular(AppDimensions.cardRadius),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -40,
            child: Opacity(
              opacity: 0.1,
              child: Container(
                width: 200,
                height: 200,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            left: -60,
            bottom: -80,
            child: Opacity(
              opacity: 0.08,
              child: Container(
                width: 250,
                height: 250,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (onBack != null)
                      GestureDetector(
                        onTap: onBack,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    ...(rightAction == null ? const <Widget>[] : [rightAction!]),
                  ],
                ),
                if (subtitle case final subtitle?) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                ],
                if (children case final c? when c.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...c,
                ],
                if (tall) const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
