import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class MilestoneWidget extends StatefulWidget {
  final int progressPercentage;
  final VoidCallback? onDismiss;
  final bool showFullscreen;

  const MilestoneWidget({
    super.key,
    required this.progressPercentage,
    this.onDismiss,
    this.showFullscreen = false,
  });

  @override
  State<MilestoneWidget> createState() => _MilestoneWidgetState();
}

class _MilestoneWidgetState extends State<MilestoneWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: -100, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();

    if (!widget.showFullscreen) {
      Future.delayed(const Duration(seconds: 5), _dismiss);
    }
  }

  void _dismiss() {
    if (mounted) {
      _controller.reverse().then((_) {
        if (mounted) widget.onDismiss?.call();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _motivationalText {
    switch (widget.progressPercentage) {
      case 25:
        return 'Anda sudah 1/4 jalan! Tetap semangat!';
      case 50:
        return 'Setengah jalan! Anda luar biasa! 💪';
      case 75:
        return '3/4 selesai! Garis finish sudah dekat!';
      case 100:
        return 'Selamat! Anda telah menyelesaikan pengobatan TB!';
      default:
        return 'Lanjutkan perjalanan kesembuhan Anda!';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showFullscreen && widget.progressPercentage == 100) {
      return _buildFullscreenCelebration(context);
    }

    return SlideTransition(
      position: _slideAnimation.drive(
        Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero),
      ),
      child: GestureDetector(
        onHorizontalDragEnd: (_) => _dismiss(),
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: _getGradient(),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _getEmojiForMilestone(),
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '🎉 Pencapaian ${widget.progressPercentage}%!',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _motivationalText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _dismiss,
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullscreenCelebration(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1FA15A),
                Color(0xFF167A45),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              _buildConfetti(),
              const SizedBox(height: 40),
              const Text(
                '🎉',
                style: TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 24),
              Text(
                'Selamat!',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Anda telah menyelesaikan pengobatan TB selama 6 bulan.\nTetaplah sehat dan jangan lupa kontrol rutin!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onDismiss?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Kembali ke Beranda',
                      style: TextStyle(
                        color: Color(0xFF1FA15A),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfetti() {
    return SizedBox(
      height: 200,
      child: Stack(
        children: List.generate(15, (index) {
          final random = index % 5;
          return Positioned(
            left: (index * 30).toDouble() % 300,
            top: -50,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: -50, end: 200),
              duration: Duration(milliseconds: 2000 + random * 200),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, value),
                  child: Opacity(
                    opacity: (200 - value) / 200,
                    child: child,
                  ),
                );
              },
              child: Text(
                ['🎊', '✨', '🎁', '⭐', '🏆'][random],
                style: const TextStyle(fontSize: 24),
              ),
            ),
          );
        }),
      ),
    );
  }

  LinearGradient _getGradient() {
    switch (widget.progressPercentage) {
      case 25:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5DADE2), Color(0xFF2E86DE)],
        );
      case 50:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF48DBFB), Color(0xFF00B4D8)],
        );
      case 75:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFB347), Color(0xFFF5A623)],
        );
      default:
        return AppColors.primaryGradient;
    }
  }

  String _getEmojiForMilestone() {
    switch (widget.progressPercentage) {
      case 25:
        return '🚀';
      case 50:
        return '💪';
      case 75:
        return '🏁';
      case 100:
        return '🏆';
      default:
        return '⭐';
    }
  }
}
