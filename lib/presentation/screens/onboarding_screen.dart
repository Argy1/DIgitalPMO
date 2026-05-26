import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/pmo_button.dart';
import '../../core/widgets/pmo_med_pill.dart';
import '../../data/sync/sync_manager.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final box = Hive.box<dynamic>(HiveBoxes.settings);
    await box.put('hasSeenOnboarding', true);
    if (mounted) {
      context.go('/login');
    }
  }

  Future<void> _skipOnboarding() async {
    await _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            children: [
              _OnboardingSlide(
                backgroundColor: const Color(0xFFE8F5F1),
                title: 'Jangan Sampai\nLupa Minum Obat',
                description:
                    'DigitalPMO mengingatkan kamu minum obat TB setiap hari, tepat waktu, selama 180 hari penuh',
                buttonLabel: 'Lanjut →',
                illustration: _ReminderIllustration(),
                onButtonPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
              _OnboardingSlide(
                backgroundColor: const Color(0xFFFEF3E2),
                title: 'PMO Digital AI\nSiap 24 Jam',
                description:
                    'Tanya apapun soal obat, efek samping, atau sekadar butuh semangat — AI kami selalu ada untukmu',
                buttonLabel: 'Lanjut →',
                illustration: _AIIllustration(),
                onButtonPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
              _OnboardingSlide(
                backgroundColor: const Color(0xFFEBF5FB),
                title: 'Pantau Perjalanan\nSembuhmu',
                description:
                    'Lihat progress harian, grafik kepatuhan, dan laporan siap cetak untuk kontrol doktermu',
                buttonLabel: 'Mulai Sekarang 🌱',
                illustration: _ProgressIllustration(),
                onButtonPressed: _completeOnboarding,
              ),
            ],
          ),
          // Skip button - hide on last slide
          if (_currentPage < 2)
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: GestureDetector(
                  onTap: _skipOnboarding,
                  child: Text(
                    'Lewati',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMute,
                    ),
                  ),
                ),
              ),
            ),
          // Dot indicators
          Positioned(
            bottom: 120 + bottomPadding,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 32 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _currentPage == index
                          ? AppColors.primary
                          : const Color(0xFFD4ECE6),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  final Color backgroundColor;
  final String title;
  final String description;
  final String buttonLabel;
  final Widget illustration;
  final VoidCallback onButtonPressed;

  const _OnboardingSlide({
    required this.backgroundColor,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.illustration,
    required this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top 55%: colored background with illustration
        Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.55,
          decoration: BoxDecoration(color: backgroundColor),
          child: Center(child: illustration),
        ),
        // Bottom 45%: white content with curved top
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * 0.5,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMute,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                    PMOButton(
                      buttonLabel,
                      onPressed: onButtonPressed,
                      width: double.infinity,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReminderIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Phone mockup
        Container(
          width: 160,
          height: 280,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '09:00',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Waktu Minum Obat',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'RHZE - Pagi',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMute,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Floating medicine pills
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PMOMedPill(kind: 'R', size: 40),
            const SizedBox(width: 12),
            PMOMedPill(kind: 'H', size: 40),
            const SizedBox(width: 12),
            PMOMedPill(kind: 'Z', size: 40),
            const SizedBox(width: 12),
            PMOMedPill(kind: 'E', size: 40),
          ],
        ),
      ],
    );
  }
}

class _AIIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // AI Robot
        Container(
          width: 120,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.smart_toy, size: 30),
                ),
                const SizedBox(height: 8),
                const Text(
                  'PMO AI',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Chat bubbles
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Tanya apapun\nyang ingin kamu tahu',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Siap membantu 24 jam',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProgressIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Progress visualization
        Container(
          width: 200,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '75%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  widthFactor: 0.75,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Calendar checkmarks
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  5,
                  (index) => Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: index < 4
                          ? AppColors.success
                          : Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(Icons.check, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Trophy
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('🏆', style: TextStyle(fontSize: 40)),
          ),
        ),
      ],
    );
  }
}
