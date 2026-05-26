import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pmo_button.dart';

class MedicationSuccessScreen extends StatefulWidget {
  final int streak;

  const MedicationSuccessScreen({super.key, required this.streak});

  @override
  State<MedicationSuccessScreen> createState() =>
      _MedicationSuccessScreenState();
}

class _MedicationSuccessScreenState extends State<MedicationSuccessScreen>
    with TickerProviderStateMixin {
  late final AnimationController _glowController;
  late final AnimationController _confettiController;

  static const _confetti = [
    (top: 30.0, left: 40.0, color: AppColors.primary, size: 6.0),
    (top: 50.0, left: 80.0, color: AppColors.amber, size: 5.0),
    (top: 90.0, left: 20.0, color: AppColors.success, size: 7.0),
    (top: 110.0, left: 70.0, color: AppColors.primary, size: 4.0),
    (top: 40.0, left: -1.0, color: AppColors.amber, size: 6.0),
    (top: 80.0, left: -1.0, color: AppColors.success, size: 5.0),
    (top: 20.0, left: -1.0, color: AppColors.amber, size: 4.0),
    (top: -1.0, left: 60.0, color: AppColors.success, size: 6.0),
    (top: 60.0, left: 150.0, color: AppColors.primary, size: 4.0),
  ];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _confettiController.dispose();
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
            child: _buildCheckArea(),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildCheckArea() {
    return Container(
      color: AppColors.tealSoft,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.hardEdge,
        children: [
          ..._buildConfetti(),
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
                      AppColors.primary.withValues(alpha: 0.2 * (0.6 + t * 0.3)),
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
              color: AppColors.primary.withValues(alpha: 0.2),
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
                      colors: [AppColors.primary, AppColors.primaryDeep],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
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

  List<Widget> _buildConfetti() {
    return [
      for (var i = 0; i < _confetti.length; i++)
        AnimatedBuilder(
          animation: _confettiController,
          builder: (context, _) {
            final phase = (i * 0.15) % 1.0;
            final t = (_confettiController.value + phase) % 1.0;
            final scale = t < 0.3 ? (t / 0.3) : (1 - (t - 0.3) * 0.6);
            final dy = t < 0.3 ? -4.0 * (t / 0.3) : 8.0 * ((t - 0.3) / 0.7);
            final opacity = t < 0.3 ? 0.6 : 0.6 - 0.2 * ((t - 0.3) / 0.7);
            final c = _confetti[i];
            return Positioned(
              top: c.top < 0 ? null : c.top + dy,
              bottom: c.top < 0 ? 40 - dy : null,
              left: c.left < 0 ? null : c.left,
              right: c.left < 0 ? 50.0 + i * 6 : null,
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: scale.clamp(0.0, 1.2),
                  child: Container(
                    width: c.size,
                    height: c.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.color,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
    ];
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(
        children: [
          const Text(
            'Obat Terverifikasi! ✅',
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
            'AI berhasil mendeteksi obatmu',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textMute),
          ),
          const SizedBox(height: 16),
          _buildStreakCard(),
          const SizedBox(height: 12),
          _buildEducationCard(),
          const Spacer(),
          _OutlineButton(
            label: 'Ada Efek Samping?',
            onTap: () => context.push('/side-effects/log'),
          ),
          const SizedBox(height: 10),
          PMOButton(
            'Kembali ke Beranda',
            width: double.infinity,
            onPressed: () => context.go('/home/dashboard'),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF15594B)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.27),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: -20,
            right: -10,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: const Center(
                  child: Text('🔥', style: TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Streak Kamu',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.streak} hari',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        height: 1.05,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Text('🔥', style: TextStyle(fontSize: 36, height: 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEducationCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
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
                  '💡 TAHUKAH KAMU?',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: Color(0xFFA66A00),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Urine kemerahan setelah minum Rifampicin itu NORMAL',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => context.push('/education/1'),
                  child: const Text(
                    'Baca Selengkapnya →',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
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

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OutlineButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
