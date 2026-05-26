import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/pmo_button.dart';
import '../../../../core/widgets/pmo_med_pill.dart';

class PhaseTransitionDialog extends StatefulWidget {
  final String currentPhase;
  final String nextPhase;
  final String oldMeds;
  final String newMeds;
  final VoidCallback onConfirm;

  const PhaseTransitionDialog({
    super.key,
    required this.currentPhase,
    required this.nextPhase,
    required this.oldMeds,
    required this.newMeds,
    required this.onConfirm,
  });

  @override
  State<PhaseTransitionDialog> createState() => _PhaseTransitionDialogState();
}

class _PhaseTransitionDialogState extends State<PhaseTransitionDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      _buildPhaseTransition(),
                      const SizedBox(height: 24),
                      _buildEducationCard(),
                      const SizedBox(height: 24),
                      _buildButtons(),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Text(
            'Transisi Fase Pengobatan',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hari ke-56: Selamat! Anda berhasil menyelesaikan fase intensif',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseTransition() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Saat Ini',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textMute,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            PMOMedPill(kind: 'R', size: 28),
                            const SizedBox(width: 4),
                            PMOMedPill(kind: 'H', size: 28),
                            const SizedBox(width: 4),
                            PMOMedPill(kind: 'Z', size: 28),
                            const SizedBox(width: 4),
                            PMOMedPill(kind: 'E', size: 28),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Intensive Phase\n(56 hari)',
                    style: TextStyle(fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Lanjut',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Selanjutnya',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            PMOMedPill(kind: 'R', size: 28),
                            const SizedBox(width: 4),
                            PMOMedPill(kind: 'H', size: 28),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Continuation Phase\n(112 hari)',
                    style: TextStyle(fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEducationCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.amberSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '💡',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Text(
                'TAHUKAH KAMU?',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Pada fase continuation, Anda hanya minum 2 jenis obat (RH) selama 4 bulan. Ini adalah bagian penting dari pengobatan TB untuk memastikan kuman TB benar-benar mati dan tidak ada resistensi obat.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMute,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {},
            child: Text(
              'Baca Selengkapnya →',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
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
              color: AppColors.amber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: PMOButton(
            'Siap Melanjutkan',
            onPressed: () {
              widget.onConfirm();
              Navigator.of(context).pop();
            },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            child: Text(
              'Tunda Dulu',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
