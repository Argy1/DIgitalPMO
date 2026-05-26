import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class HospitalizedBanner extends StatefulWidget {
  final VoidCallback onDisable;

  const HospitalizedBanner({
    super.key,
    required this.onDisable,
  });

  @override
  State<HospitalizedBanner> createState() => _HospitalizedBannerState();
}

class _HospitalizedBannerState extends State<HospitalizedBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _heightAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDisable() async {
    await _controller.reverse();
    widget.onDisable();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _heightAnimation,
      alignment: Alignment.topCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.amber.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.amber.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.medical_services,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mode Rawat Inap Aktif',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Reminder ditunda. Streak & risiko tetap tersimpan.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _handleDisable,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Nonaktifkan Mode Rawat Inap',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
