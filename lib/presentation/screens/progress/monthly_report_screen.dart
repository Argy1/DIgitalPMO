import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/pmo_button.dart';
import '../../../core/widgets/pmo_card.dart';
import '../../../core/widgets/pmo_header.dart';
import '../../../core/widgets/pmo_shimmer.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class _ReportData {
  final double adherence;
  final int confirmed;
  final int total;
  final int skipDays;
  final String phase;
  final List<_SymptomRow> symptoms;
  final List<_SideEffect> sideEffects;
  final List<String> recommendations;

  const _ReportData({
    required this.adherence,
    required this.confirmed,
    required this.total,
    required this.skipDays,
    required this.phase,
    required this.symptoms,
    required this.sideEffects,
    required this.recommendations,
  });
}

class _SymptomRow {
  final String name;
  final String startVal;
  final String endVal;
  final String trend;
  final bool isGood;

  const _SymptomRow({
    required this.name,
    required this.startVal,
    required this.endVal,
    required this.trend,
    required this.isGood,
  });
}

class _SideEffect {
  final String name;
  final int frequency;
  const _SideEffect(this.name, this.frequency);
}

// ── Helpers ───────────────────────────────────────────────────────────────────

const _monthNames = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

String _monthLabel(String ym) {
  final parts = ym.split('-');
  final year = parts[0];
  final month = int.tryParse(parts[1]) ?? 1;
  return '${_monthNames[month - 1]} $year';
}

List<String> _last6Months() {
  final now = DateTime.now();
  return List.generate(6, (i) {
    final d = DateTime(now.year, now.month - i, 1);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}';
  });
}


// ── Screen ────────────────────────────────────────────────────────────────────

class MonthlyReportScreen extends StatefulWidget {
  final String yearMonth;

  const MonthlyReportScreen({super.key, required this.yearMonth});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  late String _selectedYm;
  _ReportData? _data;
  String _aiSummaryText = '';
  bool _isLoading = true;
  bool _isLoadingAI = true;
  bool _isGeneratingPdf = false;
  late List<String> _monthOptions;

  @override
  void initState() {
    super.initState();
    _monthOptions = _last6Months();
    _selectedYm = _monthOptions.contains(widget.yearMonth)
        ? widget.yearMonth
        : _monthOptions.first;
    _loadReport(_selectedYm);
  }

  Future<void> _loadReport(String ym) async {
    setState(() {
      _isLoading = true;
      _isLoadingAI = true;
    });

    final parts = ym.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    try {
      final results = await Future.wait([
        ApiService.instance.getMonthlyReport(year, month),
        ApiService.instance.getMyProfile(),
      ]);

      final report = results[0];
      final profileData = results[1];

      final adherence =
          (report['adherence_percentage'] as num? ?? 0).toDouble() / 100;
      final confirmed = report['confirmed_doses'] as int? ?? 0;
      final total = report['total_scheduled'] as int? ?? 0;
      final missed = report['missed_doses'] as int? ?? 0;

      final patientProfile =
          profileData['patient_profile'] as Map<String, dynamic>?;
      final phase = patientProfile != null
          ? ((patientProfile['current_phase'] as String? ?? '') == 'intensive'
              ? 'Intensif'
              : 'Lanjutan')
          : 'Intensif';

      final symptoms = <_SymptomRow>[];
      final avgCough = report['avg_cough_scale'];
      if (avgCough != null) {
        final v = (avgCough as num).toDouble();
        symptoms.add(_SymptomRow(
          name: 'Batuk',
          startVal: '-',
          endVal: '${v.toStringAsFixed(1)}/5',
          trend: v <= 2 ? '↓ Membaik' : v <= 3 ? '→ Stabil' : '↑ Perlu perhatian',
          isGood: v <= 3,
        ));
      }
      final avgAppetite = report['avg_appetite_scale'];
      if (avgAppetite != null) {
        final v = (avgAppetite as num).toDouble();
        symptoms.add(_SymptomRow(
          name: 'Nafsu makan',
          startVal: '-',
          endVal: '${v.toStringAsFixed(1)}/5',
          trend: v >= 3 ? '↑ Membaik' : v >= 2 ? '→ Stabil' : '↓ Perlu perhatian',
          isGood: v >= 3,
        ));
      }
      final avgEnergy = report['avg_energy_scale'];
      if (avgEnergy != null) {
        final v = (avgEnergy as num).toDouble();
        symptoms.add(_SymptomRow(
          name: 'Energi',
          startVal: '-',
          endVal: '${v.toStringAsFixed(1)}/5',
          trend: v >= 3 ? '↑ Membaik' : v >= 2 ? '→ Stabil' : '↓ Perlu perhatian',
          isGood: v >= 3,
        ));
      }

      final sideEffectsRaw =
          report['side_effects_summary'] as Map<String, dynamic>?;
      final sideEffects = sideEffectsRaw != null
          ? sideEffectsRaw.entries
              .map((e) => _SideEffect(e.key, (e.value as num).toInt()))
              .toList()
          : <_SideEffect>[];

      final recRaw = report['ai_recommendation'];
      List<String> recommendations = [];
      if (recRaw is List) {
        recommendations = recRaw.map((e) => e.toString()).toList();
      } else if (recRaw is String && recRaw.isNotEmpty) {
        recommendations = [recRaw];
      }

      final aiSummary = report['ai_summary'] as String? ?? '';

      if (!mounted) return;
      setState(() {
        _data = _ReportData(
          adherence: adherence,
          confirmed: confirmed,
          total: total,
          skipDays: missed,
          phase: phase,
          symptoms: symptoms,
          sideEffects: sideEffects,
          recommendations: recommendations,
        );
        _aiSummaryText = aiSummary;
        _isLoading = false;
        _isLoadingAI = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingAI = false;
      });
    }
  }

  void _onMonthChanged(String? ym) {
    if (ym == null || ym == _selectedYm) return;
    setState(() => _selectedYm = ym);
    _loadReport(ym);
  }

  Future<void> _downloadPdf() async {
    final data = _data;
    if (data == null) return;
    setState(() => _isGeneratingPdf = true);
    try {
      final bytes = await _buildPdf(data, _selectedYm, _aiSummaryText);
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'Laporan_TB_$_selectedYm.pdf',
      );
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _sharePdf() async {
    final data = _data;
    if (data == null) return;
    setState(() => _isGeneratingPdf = true);
    try {
      final bytes = await _buildPdf(data, _selectedYm, _aiSummaryText);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'Laporan_TB_$_selectedYm.pdf',
      );
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            PMOHeader(
              title: 'Laporan ${_monthLabel(_selectedYm)}',
              subtitle: 'Ringkasan pengobatan bulanan',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  // Month picker
                  _MonthPicker(
                    selected: _selectedYm,
                    options: _monthOptions,
                    onChanged: _onMonthChanged,
                  ),
                  const SizedBox(height: 14),

                  // Stats grid
                  if (data != null) _StatsGrid(data: data),
                  const SizedBox(height: 14),

                  // AI summary
                  _AISummaryCard(
                      isLoading: _isLoadingAI, text: _aiSummaryText),
                  const SizedBox(height: 14),

                  // Symptom trend
                  _SectionTitle('Tren Gejala'),
                  const SizedBox(height: 8),
                  _SymptomTrendTable(rows: data?.symptoms ?? []),
                  const SizedBox(height: 14),

                  // Side effects
                  _SectionTitle('Efek Samping Bulan Ini'),
                  const SizedBox(height: 8),
                  _SideEffectList(effects: data?.sideEffects ?? []),
                  const SizedBox(height: 14),

                  // AI recommendations
                  _SectionTitle('Rekomendasi AI'),
                  const SizedBox(height: 8),
                  _RecommendationsCard(items: data?.recommendations ?? []),
                  const SizedBox(height: 20),

                  // Action buttons
                  PMOButton(
                    'Unduh PDF',
                    icon: Icons.picture_as_pdf_outlined,
                    isLoading: _isGeneratingPdf,
                    onPressed: (_isGeneratingPdf || data == null) ? null : _downloadPdf,
                  ),
                  const SizedBox(height: 10),
                  PMOButton(
                    'Bagikan ke Dokter',
                    variant: ButtonVariant.ghost,
                    icon: Icons.share_outlined,
                    isLoading: _isGeneratingPdf,
                    onPressed: (_isGeneratingPdf || data == null) ? null : _sharePdf,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Month picker ──────────────────────────────────────────────────────────────

class _MonthPicker extends StatelessWidget {
  final String selected;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _MonthPicker({
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PMOCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down,
              color: AppColors.primary),
          items: options
              .map((ym) => DropdownMenuItem(
                    value: ym,
                    child: Text(
                      _monthLabel(ym),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Stats grid ────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final _ReportData data;
  const _StatsGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final pct = (data.adherence * 100).round();
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.55,
      children: [
        _StatCard(
          label: 'Kepatuhan',
          value: '$pct%',
          icon: Icons.pie_chart_outline,
          color: pct >= 90 ? AppColors.success : AppColors.amber,
        ),
        _StatCard(
          label: 'Terkonfirmasi',
          value: '${data.confirmed}/${data.total}',
          icon: Icons.check_circle_outline,
          color: AppColors.primary,
        ),
        _StatCard(
          label: 'Hari Skip',
          value: '${data.skipDays}',
          icon: Icons.cancel_outlined,
          color: data.skipDays == 0 ? AppColors.success : AppColors.amber,
        ),
        _StatCard(
          label: 'Fase',
          value: data.phase,
          icon: Icons.medical_information_outlined,
          color: AppColors.primary,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return PMOCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMute,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── AI summary card ───────────────────────────────────────────────────────────

class _AISummaryCard extends StatelessWidget {
  final bool isLoading;
  final String text;

  const _AISummaryCard({required this.isLoading, required this.text});

  @override
  Widget build(BuildContext context) {
    return PMOCard(
      border: Border.all(
        color: AppColors.primary.withValues(alpha: 0.4),
        width: 1.5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              const Text(
                'Ringkasan AI',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.tealSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Claude AI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PMOShimmer(
                    variant: ShimmerVariant.text, width: double.infinity, height: 14),
                SizedBox(height: 8),
                PMOShimmer(
                    variant: ShimmerVariant.text, width: double.infinity, height: 14),
                SizedBox(height: 8),
                PMOShimmer(
                    variant: ShimmerVariant.text, width: 200, height: 14),
              ],
            )
          else
            Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.text,
                height: 1.65,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Symptom trend table ───────────────────────────────────────────────────────

class _SymptomTrendTable extends StatelessWidget {
  final List<_SymptomRow> rows;
  const _SymptomTrendTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    return PMOCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.tealSoft,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppDimensions.cardRadius),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                    flex: 3,
                    child: _TableHeader('Gejala')),
                Expanded(
                    flex: 2,
                    child: _TableHeader('Awal')),
                Expanded(
                    flex: 2,
                    child: _TableHeader('Akhir')),
                Expanded(
                    flex: 3,
                    child: _TableHeader('Tren')),
              ],
            ),
          ),
          // Rows
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, color: AppColors.border),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(rows[i].name,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(rows[i].startVal,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textMute)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(rows[i].endVal,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textMute)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      rows[i].trend,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: rows[i].isGood
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textMute,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ── Side effect list ──────────────────────────────────────────────────────────

class _SideEffectList extends StatelessWidget {
  final List<_SideEffect> effects;
  const _SideEffectList({required this.effects});

  @override
  Widget build(BuildContext context) {
    if (effects.isEmpty) {
      return const PMOCard(
        child: Center(
          child: Text('Tidak ada efek samping dilaporkan',
              style: TextStyle(color: AppColors.textMute, fontSize: 13)),
        ),
      );
    }
    return PMOCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < effects.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      effects[i].name,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.text),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.amberSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${effects[i].frequency}× ',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.amber,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Recommendations ───────────────────────────────────────────────────────────

class _RecommendationsCard extends StatelessWidget {
  final List<String> items;
  const _RecommendationsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return PMOCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppColors.tealSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    items[i],
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.text,
                      height: 1.5,
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
}

// ── Section title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
    );
  }
}

// ── PDF builder ───────────────────────────────────────────────────────────────

Future<Uint8List> _buildPdf(_ReportData data, String ym, String aiSummary) async {
  final doc = pw.Document();
  final label = _monthLabel(ym);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        pw.Text(
          'Laporan Pengobatan TB — $label',
          style: pw.TextStyle(
              fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 16),

        // Stats summary
        pw.Text('Ringkasan', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: ['Kepatuhan', 'Terkonfirmasi', 'Hari Skip', 'Fase'],
          data: [
            [
              '${(data.adherence * 100).round()}%',
              '${data.confirmed}/${data.total}',
              '${data.skipDays}',
              data.phase,
            ]
          ],
          cellStyle: const pw.TextStyle(fontSize: 12),
          headerStyle: pw.TextStyle(
              fontSize: 12, fontWeight: pw.FontWeight.bold),
          cellPadding: const pw.EdgeInsets.all(6),
        ),
        pw.SizedBox(height: 16),

        // AI summary
        pw.Text('Ringkasan AI', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Text(aiSummary, style: const pw.TextStyle(fontSize: 11)),
        pw.SizedBox(height: 16),

        // Symptoms
        pw.Text('Tren Gejala', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: ['Gejala', 'Awal', 'Akhir', 'Tren'],
          data: data.symptoms
              .map((s) => [s.name, s.startVal, s.endVal, s.trend])
              .toList(),
          cellStyle: const pw.TextStyle(fontSize: 11),
          headerStyle: pw.TextStyle(
              fontSize: 11, fontWeight: pw.FontWeight.bold),
          cellPadding: const pw.EdgeInsets.all(5),
        ),
        pw.SizedBox(height: 16),

        // Recommendations
        pw.Text('Rekomendasi', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        for (var i = 0; i < data.recommendations.length; i++)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(
              '${i + 1}. ${data.recommendations[i]}',
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
      ],
    ),
  );

  return doc.save();
}
