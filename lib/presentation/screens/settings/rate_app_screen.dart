import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/pmo_button.dart';

class RateAppScreen extends StatefulWidget {
  const RateAppScreen({super.key});

  @override
  State<RateAppScreen> createState() => _RateAppScreenState();
}

class _RateAppScreenState extends State<RateAppScreen>
    with TickerProviderStateMixin {
  int _rating = 0;
  int _hoveredRating = 0;
  final _feedbackCtrl = TextEditingController();
  bool _submitted = false;

  late final AnimationController _entryCtrl;
  late final AnimationController _successCtrl;
  late final AnimationController _starsCtrl;
  late final List<Animation<double>> _starAnims;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _starsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _starAnims = List.generate(5, (i) {
      final start = i * 0.12;
      final end = (start + 0.55).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _starsCtrl,
        curve: Interval(start, end, curve: Curves.elasticOut),
      );
    });
    _entryCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _starsCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _successCtrl.dispose();
    _starsCtrl.dispose();
    _feedbackCtrl.dispose();
    super.dispose();
  }

  String get _ratingLabel {
    switch (_rating) {
      case 1:
        return 'Sangat Buruk';
      case 2:
        return 'Buruk';
      case 3:
        return 'Cukup';
      case 4:
        return 'Bagus';
      case 5:
        return 'Luar Biasa!';
      default:
        return 'Ketuk bintang untuk menilai';
    }
  }

  Color get _ratingColor {
    switch (_rating) {
      case 1:
      case 2:
        return AppColors.danger;
      case 3:
        return AppColors.amber;
      case 4:
        return const Color(0xFF27AE60);
      case 5:
        return AppColors.success;
      default:
        return AppColors.textMute;
    }
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    _successCtrl.forward();
    if (_rating == 5) {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (mounted) _openStore();
    }
  }

  Future<void> _openStore() async {
    const url = 'https://play.google.com/store/apps/details?id=com.digitalpmo.app';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, Color(0xFF15594B)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 28),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nilai Aplikasi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Bantu kami berkembang lebih baik',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _submitted ? _buildSuccess() : _buildForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        children: [
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    const Color(0xFF15594B),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.star_rounded,
                  color: Colors.white, size: 44),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Bagaimana pengalamanmu\nmenggunakan DigitalPMO?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              height: 1.3,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Penilaianmu sangat berarti untuk membantu\nkami meningkatkan kualitas aplikasi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textMute,
            ),
          ),
          const SizedBox(height: 32),
          // Stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final starIndex = i + 1;
              final filled =
                  starIndex <= (_hoveredRating > 0 ? _hoveredRating : _rating);
              return AnimatedBuilder(
                animation: _starAnims[i],
                builder: (context, child) => Transform.scale(
                  scale: 0.4 + 0.6 * _starAnims[i].value,
                  child: Opacity(
                    opacity: (0.2 + 0.8 * _starAnims[i].value).clamp(0.0, 1.0),
                    child: child,
                  ),
                ),
                child: GestureDetector(
                  onTap: () => setState(() {
                    _rating = starIndex;
                    _hoveredRating = 0;
                  }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: anim,
                        child: child,
                      ),
                      child: Icon(
                        filled ? Icons.star_rounded : Icons.star_outline_rounded,
                        key: ValueKey(filled),
                        size: 48,
                        color: filled
                            ? const Color(0xFFFFB800)
                            : AppColors.border,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _ratingLabel,
              key: ValueKey(_rating),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: _rating > 0 ? FontWeight.w700 : FontWeight.w400,
                color: _ratingColor,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(height: 28),
          if (_rating > 0 && _rating <= 4) ...[
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded,
                          size: 14, color: AppColors.textMute),
                      const SizedBox(width: 6),
                      Text(
                        'APA YANG BISA KAMI PERBAIKI?',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMute,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.dark.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _feedbackCtrl,
                      maxLines: 4,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.text,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Ceritakan pengalamanmu agar kami bisa memperbaiki aplikasi...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMute.withValues(alpha: 0.6),
                        ),
                        filled: true,
                        fillColor: AppColors.card,
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ] else if (_rating == 5) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.tealSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.favorite_rounded,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Terima kasih! Berikan ulasan di Play Store agar lebih banyak pasien TB terbantu.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.primary.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (_rating > 0)
            PMOButton(
              _rating == 5 ? 'Nilai di Play Store' : 'Kirim Penilaian',
              onPressed: _submit,
              icon: _rating == 5
                  ? Icons.open_in_new_rounded
                  : Icons.send_rounded,
            ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return FadeTransition(
      opacity: _successCtrl,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 400 + i * 100),
                    curve: Curves.elasticOut,
                    builder: (context, v, child) => Transform.scale(
                      scale: v,
                      child: child,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(Icons.star_rounded,
                          color: Color(0xFFFFB800), size: 32),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.successGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                _rating == 5 ? 'Terima Kasih!' : 'Masukan Terkirim!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _rating == 5
                    ? 'Kamu telah memberikan ulasan bintang 5! Dukunganmu membantu kami terus berkembang.'
                    : 'Masukan berhargamu telah diterima. Kami akan terus memperbaiki pengalaman penggunamu.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textMute,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: PMOButton(
                  'Kembali ke Pengaturan',
                  onPressed: () => context.pop(),
                  variant: ButtonVariant.ghost,
                ),
              ),
              if (_rating < 5) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: PMOButton(
                    'Nilai di Play Store',
                    onPressed: _openStore,
                    icon: Icons.open_in_new_rounded,
                    variant: ButtonVariant.ghost,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
