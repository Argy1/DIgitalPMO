import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/pmo_card.dart';
import '../../../core/widgets/pmo_header.dart';
import '../../../core/widgets/pmo_button.dart';
import '../../../core/widgets/pmo_shimmer.dart';

const _sideEffectOptions = [
  'Tidak ada',
  'Mual',
  'Urine merah/oranye',
  'Nyeri sendi',
  'Gatal',
  'Kesemutan tangan/kaki',
  'Gangguan penglihatan',
  'Ruam kulit',
];

const _dayNames = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];
const _monthNames = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

class SymptomInputScreen extends StatefulWidget {
  const SymptomInputScreen({super.key});

  @override
  State<SymptomInputScreen> createState() => _SymptomInputScreenState();
}

class _SymptomInputScreenState extends State<SymptomInputScreen> {
  bool _isLoading = true;
  bool _alreadyLoggedToday = false;
  String? _existingLogTime;

  // Slider values (1–5)
  int _coughScale = 1;
  int _breathScale = 1;
  int _appetiteScale = 1;
  int _energyScale = 1;

  // Fever card
  bool _fever = false;
  bool _nightSweats = false;
  final TextEditingController _tempController = TextEditingController();

  // Weight (Monday only)
  final TextEditingController _weightController = TextEditingController();

  // Side effects
  final Set<String> _selectedSideEffects = {};

  // Notes
  final TextEditingController _notesController = TextEditingController();

  // Submission
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  String _submittedAt = '';
  String _aiAssessment = '';

  @override
  void initState() {
    super.initState();
    _checkAlreadyLogged();
  }

  @override
  void dispose() {
    _tempController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _checkAlreadyLogged() async {
    try {
      final data = await ApiService.instance.getTodaySymptom();
      final createdAt = DateTime.tryParse(data['created_at'] as String? ?? '');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _alreadyLoggedToday = true;
        _existingLogTime = createdAt == null
            ? null
            : '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
        _coughScale = data['cough_scale'] as int? ?? _coughScale;
        _breathScale = data['breath_scale'] as int? ?? _breathScale;
        _appetiteScale = data['appetite_scale'] as int? ?? _appetiteScale;
        _energyScale = data['energy_scale'] as int? ?? _energyScale;
        _fever = data['has_fever'] as bool? ?? _fever;
        _nightSweats = data['has_night_sweats'] as bool? ?? _nightSweats;
        final temp = data['fever_temp'];
        if (temp != null) _tempController.text = temp.toString();
        final weight = data['weight_kg'];
        if (weight != null) _weightController.text = weight.toString();
        _notesController.text = data['notes'] as String? ?? '';
        _aiAssessment = data['ai_assessment'] as String? ?? '';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _alreadyLoggedToday = false;
      });
    }
  }

  bool get _isPristine =>
      _coughScale == 1 &&
      _breathScale == 1 &&
      _appetiteScale == 1 &&
      _energyScale == 1;

  double get _feverTemp => double.tryParse(_tempController.text) ?? 36.5;

  String _generateAssessment() {
    final hasRash = _selectedSideEffects.contains('Ruam kulit');
    final hasVision = _selectedSideEffects.contains('Gangguan penglihatan');
    if (hasRash || hasVision) {
      return 'Terdapat efek samping yang memerlukan perhatian segera. Pertimbangkan untuk menghubungi dokter atau faskes terdekat hari ini. Jangan menghentikan obat tanpa instruksi dokter.';
    }
    if (_coughScale >= 4 ||
        _breathScale >= 4 ||
        (_fever && _feverTemp > 38.5)) {
      return 'Gejala Anda hari ini menunjukkan intensitas yang cukup tinggi. Tetap minum obat sesuai jadwal dan istirahat cukup. Jika gejala tidak membaik dalam 2–3 hari, hubungi petugas kesehatan.';
    }
    if (_coughScale <= 2 && _breathScale <= 2 && !_fever) {
      return 'Gejala Anda hari ini dalam batas normal. Tetap jaga konsistensi minum obat dan pola hidup sehat. Semangat terus!';
    }
    return 'Terima kasih telah melaporkan gejala hari ini. Gejala Anda sedang dalam pemantauan. Tetap minum obat sesuai jadwal dan pantau perkembangannya.';
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final notes = StringBuffer(_notesController.text.trim());
      final effects = _selectedSideEffects
          .where((effect) => effect != 'Tidak ada')
          .toList();
      if (effects.isNotEmpty) {
        if (notes.isNotEmpty) notes.write('\n\n');
        notes.write('Efek samping: ${effects.join(', ')}');
      }
      final data = await ApiService.instance.logSymptom({
        'cough_scale': _coughScale,
        'breath_scale': _breathScale,
        'appetite_scale': _appetiteScale,
        'energy_scale': _energyScale,
        'has_fever': _fever,
        'fever_temp': _fever ? _feverTemp : null,
        'has_night_sweats': _nightSweats,
        'weight_kg': double.tryParse(_weightController.text),
        'notes': notes.isEmpty ? null : notes.toString(),
      });
      final createdAt = DateTime.tryParse(data['created_at'] as String? ?? '');
      final now = createdAt ?? DateTime.now();
      final h = now.hour.toString().padLeft(2, '0');
      final m = now.minute.toString().padLeft(2, '0');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isSubmitted = true;
          _submittedAt = '$h:$m';
          _aiAssessment =
              data['ai_assessment'] as String? ?? _generateAssessment();
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

  String get _subtitleDate {
    final now = DateTime.now();
    final day = _dayNames[now.weekday - 1];
    final month = _monthNames[now.month - 1];
    return '$day, ${now.day} $month ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            PMOHeader(
              title: 'Gejala Hari Ini',
              subtitle: _subtitleDate,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home/dashboard');
                }
              },
            ),
            Expanded(
              child: _isLoading
                  ? _buildLoadingView()
                  : _alreadyLoggedToday
                  ? _buildAlreadyLoggedView()
                  : _isSubmitted
                  ? _buildSuccessView()
                  : _buildFormView(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Loading ────────────────────────────────────────────────────────────────

  Widget _buildLoadingView() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(height: 8),
          PMOShimmer(height: 180),
          SizedBox(height: 16),
          PMOShimmer(height: 160),
          SizedBox(height: 16),
          PMOShimmer(height: 200),
          SizedBox(height: 16),
          PMOShimmer(height: 140),
        ],
      ),
    );
  }

  // ── Already Logged ─────────────────────────────────────────────────────────

  Widget _buildAlreadyLoggedView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.pageMargin),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.tealSoft,
              borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sudah diisi hari ini',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        'Sudah diisi pukul ${_existingLogTime ?? "09:30"}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMute,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PMOCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ringkasan Hari Ini',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 12),
                _SummaryRow('Batuk', '$_coughScale/5'),
                _SummaryRow('Sesak napas', '$_breathScale/5'),
                _SummaryRow('Demam', _fever ? 'Ya' : 'Tidak'),
                _SummaryRow('Keringat malam', _nightSweats ? 'Ya' : 'Tidak'),
                _SummaryRow('Nafsu makan', '$_appetiteScale/5'),
                _SummaryRow('Energi', '$_energyScale/5'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PMOButton(
            'Kembali ke Beranda',
            variant: ButtonVariant.ghost,
            width: double.infinity,
            onPressed: () => context.go('/home/dashboard'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Form ───────────────────────────────────────────────────────────────────

  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.pageMargin),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildBreathingCard(),
          const SizedBox(height: 16),
          _buildFeverCard(),
          const SizedBox(height: 16),
          _buildGeneralCard(),
          const SizedBox(height: 16),
          _buildSideEffectsCard(),
          const SizedBox(height: 16),
          _buildNotesCard(),
          const SizedBox(height: 24),
          PMOButton(
            'Simpan Gejala Hari Ini',
            isDisabled: _isPristine,
            isLoading: _isSubmitting,
            width: double.infinity,
            onPressed: _isPristine ? null : _submit,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBreathingCard() {
    return PMOCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle('Gejala Pernapasan'),
          const SizedBox(height: 16),
          _SymptomSlider(
            label: 'Batuk',
            value: _coughScale,
            onChanged: (v) => setState(() => _coughScale = v),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border),
          const SizedBox(height: 12),
          _SymptomSlider(
            label: 'Sesak Napas',
            value: _breathScale,
            onChanged: (v) => setState(() => _breathScale = v),
          ),
        ],
      ),
    );
  }

  Widget _buildFeverCard() {
    return PMOCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle('Suhu & Demam'),
          const SizedBox(height: 16),
          _SwitchRow(
            label: 'Demam',
            value: _fever,
            onChanged: (v) => setState(() => _fever = v),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _fever
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      TextField(
                        controller: _tempController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Suhu tubuh',
                          hintText: '36.5',
                          suffixText: '°C',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.inputRadius,
                            ),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.inputRadius,
                            ),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.inputRadius,
                            ),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border),
          const SizedBox(height: 12),
          _SwitchRow(
            label: 'Keringat Malam',
            value: _nightSweats,
            onChanged: (v) => setState(() => _nightSweats = v),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralCard() {
    final isMonday = DateTime.now().weekday == DateTime.monday;
    return PMOCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle('Kondisi Umum'),
          const SizedBox(height: 16),
          _SymptomSlider(
            label: 'Nafsu Makan',
            value: _appetiteScale,
            onChanged: (v) => setState(() => _appetiteScale = v),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border),
          const SizedBox(height: 12),
          _SymptomSlider(
            label: 'Energi / Tenaga',
            value: _energyScale,
            onChanged: (v) => setState(() => _energyScale = v),
          ),
          if (isMonday) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.border),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Berat Badan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Timbang setiap Senin',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMute.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      suffixText: 'kg',
                      hintText: '60',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.inputRadius,
                        ),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.inputRadius,
                        ),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.inputRadius,
                        ),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSideEffectsCard() {
    final hasRash = _selectedSideEffects.contains('Ruam kulit');
    final hasVision = _selectedSideEffects.contains('Gangguan penglihatan');

    return PMOCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle('Efek Samping Obat'),
          const SizedBox(height: 4),
          const Text(
            'Ada efek samping hari ini?',
            style: TextStyle(fontSize: 13, color: AppColors.textMute),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sideEffectOptions.map((opt) {
              final selected = _selectedSideEffects.contains(opt);
              return FilterChip(
                label: Text(opt),
                selected: selected,
                onSelected: (val) {
                  setState(() {
                    if (opt == 'Tidak ada') {
                      _selectedSideEffects.clear();
                      if (val) _selectedSideEffects.add(opt);
                    } else {
                      _selectedSideEffects.remove('Tidak ada');
                      if (val) {
                        _selectedSideEffects.add(opt);
                      } else {
                        _selectedSideEffects.remove(opt);
                      }
                    }
                  });
                },
                selectedColor: AppColors.tealSoft,
                checkmarkColor: AppColors.primary,
                backgroundColor: AppColors.background,
                labelStyle: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textMute,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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
          // Ruam kulit warning
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: hasRash
                ? _WarningCard(
                    color: AppColors.danger,
                    icon: Icons.warning_rounded,
                    title: '⚠️ Perhatian!',
                    body:
                        'Ruam kulit parah bisa jadi reaksi alergi obat TB yang serius. Pertimbangkan untuk segera ke faskes.',
                  )
                : const SizedBox.shrink(),
          ),
          // Gangguan penglihatan warning
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: hasVision
                ? _WarningCard(
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
    );
  }

  Widget _buildNotesCard() {
    return PMOCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle('Catatan Tambahan'),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 4,
            maxLength: 300,
            decoration: InputDecoration(
              hintText: 'Ceritakan ke doktermu...',
              hintStyle: const TextStyle(
                color: AppColors.textMute,
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: AppColors.background,
              counterStyle: const TextStyle(
                fontSize: 11,
                color: AppColors.textMute,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Success View ───────────────────────────────────────────────────────────

  Widget _buildSuccessView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.pageMargin),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.tealSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Gejala Tersimpan!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tersimpan pukul $_submittedAt',
            style: const TextStyle(fontSize: 13, color: AppColors.textMute),
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
                          'Berdasarkan gejala hari ini...',
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
                  _aiAssessment,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.text,
                    height: 1.6,
                  ),
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

// ── Private helper widgets ─────────────────────────────────────────────────

class _CardTitle extends StatelessWidget {
  final String text;
  const _CardTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
    );
  }
}

class _SymptomSlider extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _SymptomSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  static const _labels = [
    '',
    'Tidak ada',
    'Ringan',
    'Cukup',
    'Parah',
    'Sangat parah',
  ];

  Color get _color {
    final t = (value - 1) / 4.0;
    return Color.lerp(AppColors.success, AppColors.danger, t)!;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$value/5',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _color,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: value.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            activeColor: _color,
            inactiveColor: AppColors.border,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _labels[1],
              style: const TextStyle(fontSize: 10, color: AppColors.textMute),
            ),
            Text(
              _labels[5],
              style: const TextStyle(fontSize: 10, color: AppColors.textMute),
            ),
          ],
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        CupertinoSwitch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primary,
        ),
      ],
    );
  }
}

class _WarningCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String body;

  const _WarningCard({
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

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textMute),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
