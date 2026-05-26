import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pmo_button.dart';

class MedicationFailedScreen extends StatefulWidget {
  const MedicationFailedScreen({super.key});

  @override
  State<MedicationFailedScreen> createState() => _MedicationFailedScreenState();
}

class _MedicationFailedScreenState extends State<MedicationFailedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;

  static const List<
      ({
        double? top,
        double? bottom,
        double? left,
        double? right,
        Color color,
        double size,
      })> _particles = [
    (top: 40, bottom: null, left: 50, right: null, color: AppColors.amber, size: 6),
    (top: 70, bottom: null, left: 25, right: null, color: AppColors.danger, size: 5),
    (top: 100, bottom: null, left: 70, right: null, color: AppColors.amber, size: 7),
    (top: 50, bottom: null, left: null, right: 50, color: AppColors.danger, size: 5),
    (top: 90, bottom: null, left: null, right: 30, color: AppColors.amber, size: 6),
    (top: null, bottom: 40, left: null, right: 60, color: AppColors.amber, size: 5),
    (top: null, bottom: 30, left: 40, right: null, color: AppColors.danger, size: 6),
  ];

  static const _tips = [
    'Pastikan cahaya cukup terang',
    'Letakkan semua obat di permukaan datar',
    'Jarak kamera 15-20 cm dari obat',
    'Hindari bayangan di atas obat',
  ];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.card,
      body: Column(
        children: [
          SizedBox(
            height: size.height * 0.4,
            width: double.infinity,
            child: _buildIconArea(),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildIconArea() {
    return Container(
      color: const Color(0xFFFCEBEB),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.hardEdge,
        children: [
          for (final p in _particles)
            Positioned(
              top: p.top,
              bottom: p.bottom,
              left: p.left,
              right: p.right,
              child: Opacity(
                opacity: 0.5,
                child: Container(
                  width: p.size,
                  height: p.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.color,
                  ),
                ),
              ),
            ),
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, _) {
              final t = _glowController.value;
              return Container(
                width: 160 * (1 + t * 0.06),
                height: 160 * (1 + t * 0.06),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.amber
                          .withValues(alpha: 0.25 * (0.5 + t * 0.3)),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.amber.withValues(alpha: 0.2),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (context, scale, _) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment(-0.5, -1),
                      end: Alignment(0.5, 1),
                      colors: [Color(0xFFFFB547), AppColors.amber],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.amber.withValues(alpha: 0.4),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.priority_high_rounded,
                    color: Colors.white,
                    size: 52,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(
        children: [
          const Text(
            'Foto Kurang Jelas 📸',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'AI tidak dapat mendeteksi obat',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textMute),
          ),
          const SizedBox(height: 18),
          _buildTipsCard(),
          const Spacer(),
          PMOButton(
            'Coba Foto Lagi',
            icon: Icons.camera_alt_rounded,
            width: double.infinity,
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/medication/confirm');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.dark.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Coba lagi dengan:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _tips.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.amberSoft,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFA66A00),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _tips[i],
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: const BoxDecoration(
                color: AppColors.amber,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
