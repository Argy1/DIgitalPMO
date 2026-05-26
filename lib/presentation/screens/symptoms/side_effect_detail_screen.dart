import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/pmo_card.dart';
import '../../../core/widgets/pmo_header.dart';
import '../../../core/widgets/pmo_button.dart';

const _effectOptions = [
  'Tidak ada',
  'Mual',
  'Urine merah/oranye',
  'Nyeri sendi',
  'Gatal',
  'Kesemutan tangan/kaki',
  'Gangguan penglihatan',
  'Ruam kulit',
];

class _AIResponse {
  final String severity;
  final Color color;
  final IconData icon;
  final String message;
  final bool showFaskesButton;

  const _AIResponse({
    required this.severity,
    required this.color,
    required this.icon,
    required this.message,
    required this.showFaskesButton,
  });
}

class SideEffectDetailScreen extends StatefulWidget {
  const SideEffectDetailScreen({super.key});

  @override
  State<SideEffectDetailScreen> createState() => _SideEffectDetailScreenState();
}

class _SideEffectDetailScreenState extends State<SideEffectDetailScreen> {
  final Set<String> _selected = {};
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  _AIResponse? _response;

  bool get _canSubmit => _selected.isNotEmpty;

  _AIResponse _computeResponse() {
    if (_selected.contains('Ruam kulit') ||
        _selected.contains('Gangguan penglihatan')) {
      return const _AIResponse(
        severity: 'BERAT',
        color: AppColors.danger,
        icon: Icons.emergency_rounded,
        message:
            'Segera ke fasilitas kesehatan!\nHentikan obat sementara dan tunjukkan kartu pengobatan TB-mu kepada petugas.',
        showFaskesButton: true,
      );
    }

    if (_selected.contains('Nyeri sendi') ||
        (_selected.length >= 3 && !_selected.contains('Tidak ada'))) {
      return const _AIResponse(
        severity: 'SEDANG',
        color: AppColors.amber,
        icon: Icons.warning_rounded,
        message:
            'Efek ini perlu diperhatikan.\nMonitor selama 2–3 hari.\nJika memburuk, hubungi doktermu.',
        showFaskesButton: false,
      );
    }

    // RINGAN
    String msg;
    if (_selected.contains('Urine merah/oranye')) {
      msg =
          'Ini normal karena Rifampicin.\nTidak perlu khawatir, tetap minum obat sesuai jadwal.';
    } else if (_selected.contains('Mual')) {
      msg =
          'Mual ringan biasanya berkurang setelah beberapa minggu.\nCoba minum obat setelah makan dan tetap lanjutkan.';
    } else if (_selected.contains('Tidak ada')) {
      msg =
          'Bagus! Tidak ada efek samping yang dilaporkan hari ini.\nTetap lanjutkan pengobatan sesuai jadwal.';
    } else {
      msg =
          'Efek samping yang dilaporkan masih dalam batas wajar.\nTetap lanjutkan pengobatan dan pantau perkembangannya.';
    }

    return _AIResponse(
      severity: 'RINGAN',
      color: AppColors.success,
      icon: Icons.check_circle_rounded,
      message: msg,
      showFaskesButton: false,
    );
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final response = _computeResponse();
    try {
      await ApiService.instance.logSideEffect({
        'side_effects': _selected.toList(),
        'severity': response.severity.toLowerCase(),
        'ai_response': response.message,
        'is_emergency': response.showFaskesButton,
      });
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isSubmitted = true;
          _response = response;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiErrorMessage(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            PMOHeader(
              title: 'Efek Samping Obat',
              subtitle: 'Laporan hari ini',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: _isSubmitted ? _buildResultView() : _buildFormView(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Form ───────────────────────────────────────────────────────────────────

  Widget _buildFormView() {
    final hasRash = _selected.contains('Ruam kulit');
    final hasVision = _selected.contains('Gangguan penglihatan');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.pageMargin),
      child: Column(
        children: [
          const SizedBox(height: 8),
          PMOCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Efek Samping',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pilih efek samping yang kamu rasakan hari ini',
                  style: TextStyle(fontSize: 13, color: AppColors.textMute),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _effectOptions.map((opt) {
                    final selected = _selected.contains(opt);
                    return FilterChip(
                      label: Text(opt),
                      selected: selected,
                      onSelected: (val) {
                        setState(() {
                          if (opt == 'Tidak ada') {
                            _selected.clear();
                            if (val) _selected.add(opt);
                          } else {
                            _selected.remove('Tidak ada');
                            if (val) {
                              _selected.add(opt);
                            } else {
                              _selected.remove(opt);
                            }
                          }
                        });
                      },
                      selectedColor: AppColors.tealSoft,
                      checkmarkColor: AppColors.primary,
                      backgroundColor: AppColors.background,
                      labelStyle: TextStyle(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textMute,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 13,
                      ),
                      side: BorderSide(
                        color: selected ? AppColors.primary : AppColors.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }).toList(),
                ),
                // Ruam kulit — danger warning
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: hasRash
                      ? _WarningBanner(
                          color: AppColors.danger,
                          icon: Icons.warning_rounded,
                          title: '⚠️ Perhatian!',
                          body:
                              'Ruam kulit parah bisa jadi reaksi alergi obat TB yang serius. Pertimbangkan untuk segera ke faskes.',
                        )
                      : const SizedBox.shrink(),
                ),
                // Gangguan penglihatan — amber warning
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: hasVision
                      ? _WarningBanner(
                          color: AppColors.amber,
                          icon: Icons.visibility_off_rounded,
                          title: 'Perhatian Penglihatan',
                          body:
                              'Gangguan penglihatan perlu segera dilaporkan ke dokter. Bisa berkaitan dengan Etambutol.',
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PMOButton(
            'Simpan Laporan Efek Samping',
            isDisabled: !_canSubmit,
            isLoading: _isSubmitting,
            width: double.infinity,
            onPressed: _canSubmit ? _submit : null,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Result ─────────────────────────────────────────────────────────────────

  Widget _buildResultView() {
    final r = _response!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.pageMargin),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Severity icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: r.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(r.icon, color: r.color, size: 40),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: r.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              r.severity,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: r.color,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 24),
          PMOCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.tealSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.smart_toy,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI PMO',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.text,
                          ),
                        ),
                        Text(
                          'Penilaian efek samping',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMute,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  r.message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.text,
                    height: 1.6,
                  ),
                ),
                if (r.showFaskesButton) ...[
                  const SizedBox(height: 16),
                  PMOButton(
                    '🏥 Cari Faskes Terdekat',
                    variant: ButtonVariant.amber,
                    width: double.infinity,
                    onPressed: () {
                      // TODO: navigate to faskes finder / url_launcher maps
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Selected effects summary
          PMOCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Efek samping yang dilaporkan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMute,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _selected
                      .map(
                        (e) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.tealSoft,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            e,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PMOButton(
            'Kembali ke Beranda',
            width: double.infinity,
            onPressed: () => context.go('/home/dashboard'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Private helpers ────────────────────────────────────────────────────────

class _WarningBanner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String body;

  const _WarningBanner({
    required this.color,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(fontSize: 13, color: color, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
