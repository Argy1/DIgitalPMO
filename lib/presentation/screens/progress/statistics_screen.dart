import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/pmo_card.dart';
import '../../../core/widgets/pmo_header.dart';
import '../../../core/widgets/pmo_button.dart';
import '../../../core/widgets/pmo_shimmer.dart';
import '../../../core/widgets/pmo_empty_state.dart';

enum _DayStatus { confirmed, missed, late, future }

class _SideEffectEntry {
  final String name;
  final String date;
  final String severity;
  const _SideEffectEntry(this.name, this.date, this.severity);
}

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = true;
  int _chartDays = 7;

  int _adherencePct = 0;
  int _confirmedDoses = 0;
  int _totalDoses = 0;

  List<_DayStatus> _calendarDays = [];

  int _streak = 0;
  int _longestStreak = 0;
  double _lanjutanProgress = 0.0;

  final List<_SideEffectEntry> _sideEffects = const [];

  late Map<String, List<FlSpot>> _symptomData7;
  late Map<String, List<FlSpot>> _symptomData30;

  @override
  void initState() {
    super.initState();
    _symptomData7 = _emptySpots(7);
    _symptomData30 = _emptySpots(30);
    _loadData();
  }

  Map<String, List<FlSpot>> _emptySpots(int count) => {
    'batuk': List.generate(count, (i) => FlSpot(i.toDouble(), 0)),
    'sesak': List.generate(count, (i) => FlSpot(i.toDouble(), 0)),
    'demam': List.generate(count, (i) => FlSpot(i.toDouble(), 0)),
  };

  Future<void> _loadData() async {
    final now = DateTime.now();
    final monthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    try {
      final results = await Future.wait([
        ApiService.instance.getMedicationHistory(monthStr),
        ApiService.instance.getMyProfile(),
        ApiService.instance.getTodayMedication(),
      ]);

      final histData = results[0];
      final profileData = results[1];
      final todayData = results[2];

      // Build calendar from history
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final dayMap = <int, _DayStatus>{};
      final histDays = histData['days'] as List<dynamic>? ?? [];
      for (final d in histDays) {
        final dateStr = (d as Map<String, dynamic>)['date'] as String?;
        if (dateStr == null) continue;
        final day = int.tryParse(dateStr.split('-').last) ?? 0;
        final logs = d['logs'] as List<dynamic>? ?? [];
        if (logs.isEmpty) continue;
        final statuses = logs
            .whereType<Map<String, dynamic>>()
            .map((l) => l['status'] as String? ?? '')
            .toList();
        if (statuses.contains('confirmed')) {
          dayMap[day] = _DayStatus.confirmed;
        } else if (statuses.contains('late')) {
          dayMap[day] = _DayStatus.late;
        } else {
          dayMap[day] = _DayStatus.missed;
        }
      }

      // Ambil treatment_start_date untuk kalender — hari sebelum mulai berobat = future (netral)
      DateTime? treatmentStart;
      final profileForCal = (results[1])['patient_profile'] as Map<String, dynamic>?;
      if (profileForCal != null) {
        final s = profileForCal['treatment_start_date'] as String?;
        if (s != null) treatmentStart = DateTime.tryParse(s);
      }

      final calDays = List.generate(daysInMonth, (i) {
        final day = i + 1;
        final date = DateTime(now.year, now.month, day);
        // Hari di masa depan = future
        if (day > now.day) return _DayStatus.future;
        // Hari sebelum mulai berobat = future (belum mulai)
        if (treatmentStart != null && date.isBefore(DateTime(treatmentStart.year, treatmentStart.month, treatmentStart.day))) {
          return _DayStatus.future;
        }
        return dayMap[day] ?? _DayStatus.missed;
      });

      // Adherence from history
      int confirmed = 0, total = 0;
      for (final d in histDays) {
        final logs =
            (d as Map<String, dynamic>)['logs'] as List<dynamic>? ?? [];
        total += logs.length;
        for (final l in logs) {
          if ((l as Map<String, dynamic>)['status'] == 'confirmed') confirmed++;
        }
      }

      // Streak from today data
      final streak = todayData['streak_count'] as int? ?? 0;

      // Phase progress from profile
      double lanjutanProg = 0.0;
      final profile = profileData['patient_profile'] as Map<String, dynamic>?;
      if (profile != null) {
        final startStr = profile['treatment_start_date'] as String?;
        if (startStr != null) {
          final startDate = DateTime.parse(startStr);
          final dayNum = now.difference(startDate).inDays + 1;
          lanjutanProg = ((dayNum - 56) / 124).clamp(0.0, 1.0);
        }
      }

      if (mounted) {
        setState(() {
          _calendarDays = calDays;
          _confirmedDoses = confirmed;
          _totalDoses = total;
          _adherencePct = total > 0 ? ((confirmed / total) * 100).round() : 0;
          _streak = streak;
          _longestStreak = streak;
          _lanjutanProgress = lanjutanProg;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static const List<String> _monthNames = [
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final subtitle = '${_monthNames[now.month - 1]} ${now.year}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            PMOHeader(
              title: 'Progress & Statistik',
              subtitle: subtitle,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home/dashboard');
                }
              },
            ),
            Expanded(child: _isLoading ? _buildLoadingView() : _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: const [
          SizedBox(height: 8),
          PMOShimmer(height: 240),
          SizedBox(height: 16),
          PMOShimmer(height: 260),
          SizedBox(height: 16),
          PMOShimmer(height: 120),
          SizedBox(height: 16),
          PMOShimmer(height: 160),
          SizedBox(height: 16),
          PMOShimmer(height: 140),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final now = DateTime.now();
    final yearMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.pageMargin),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildAdherenceCard(),
          const SizedBox(height: 16),
          _buildSymptomChart(),
          const SizedBox(height: 16),
          _buildStreakCard(),
          const SizedBox(height: 16),
          _buildPhaseProgressCard(),
          const SizedBox(height: 16),
          _buildSideEffectsCard(),
          const SizedBox(height: 24),
          PMOButton(
            '📄 Unduh Laporan PDF Bulan Ini',
            variant: ButtonVariant.ghost,
            width: double.infinity,
            onPressed: () => context.push('/report/$yearMonth'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Card 1: Adherence ──────────────────────────────────────────────────────

  Widget _buildAdherenceCard() {
    final color = _adherencePct >= 90
        ? AppColors.success
        : _adherencePct >= 70
        ? AppColors.amber
        : AppColors.danger;

    return PMOCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Kepatuhan Bulan Ini'),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: _adherencePct.toDouble()),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOut,
                builder: (ctx, val, _) => Text(
                  '${val.toInt()}%',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_confirmedDoses dari $_totalDoses dosis',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _adherencePct >= 90
                          ? '✅ Sangat Baik'
                          : _adherencePct >= 70
                          ? '⚠️ Perlu Ditingkatkan'
                          : '❌ Perlu Perhatian',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'KALENDER KEPATUHAN',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textMute,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          _CalendarGrid(days: _calendarDays),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _CalendarLegend(AppColors.success, 'Minum'),
              SizedBox(width: 12),
              _CalendarLegend(AppColors.amber, 'Terlambat'),
              SizedBox(width: 12),
              _CalendarLegend(AppColors.danger, 'Lewat'),
              SizedBox(width: 12),
              _CalendarLegend(AppColors.border, 'Belum'),
            ],
          ),
        ],
      ),
    );
  }

  // ── Card 2: Symptom Chart ──────────────────────────────────────────────────

  Widget _buildSymptomChart() {
    final data = _chartDays == 7 ? _symptomData7 : _symptomData30;
    final batukSpots = data['batuk']!;
    final sesakSpots = data['sesak']!;
    final demamSpots = data['demam']!;
    final maxX = (_chartDays - 1).toDouble();
    final bottomInterval = _chartDays == 7 ? 1.0 : 5.0;

    return PMOCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionTitle('Grafik Gejala'),
              Row(
                children: [
                  _ChartToggle(
                    '7H',
                    _chartDays == 7,
                    () => setState(() => _chartDays = 7),
                  ),
                  const SizedBox(width: 8),
                  _ChartToggle(
                    '30H',
                    _chartDays == 30,
                    () => setState(() => _chartDays = 30),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              _ChartLegendDot(AppColors.primary, 'Batuk'),
              SizedBox(width: 12),
              _ChartLegendDot(AppColors.amber, 'Sesak'),
              SizedBox(width: 12),
              _ChartLegendDot(AppColors.danger, 'Demam'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: maxX,
                minY: 0,
                maxY: 5,
                lineBarsData: [
                  _lineBar(batukSpots, AppColors.primary),
                  _lineBar(sesakSpots, AppColors.amber),
                  _lineBar(demamSpots, AppColors.danger),
                ],
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AppColors.border, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (val, meta) => Text(
                        val.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMute,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: bottomInterval,
                      getTitlesWidget: (val, meta) => Text(
                        'H${val.toInt() + 1}',
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.textMute,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.dark,
                    getTooltipItems: (spots) {
                      const labels = ['Batuk', 'Sesak', 'Demam'];
                      const colors = [
                        AppColors.primary,
                        AppColors.amber,
                        AppColors.danger,
                      ];
                      return spots.map((s) {
                        final idx = s.barIndex < colors.length ? s.barIndex : 0;
                        return LineTooltipItem(
                          '${labels[idx]}: ${s.y.toInt()}',
                          TextStyle(
                            color: colors[idx],
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _lineBar(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2.5,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.06),
      ),
    );
  }

  // ── Card 3: Streak ─────────────────────────────────────────────────────────

  Widget _buildStreakCard() {
    return PMOCard(
      backgroundColor: AppColors.dark,
      border: Border.all(color: Colors.transparent),
      child: Column(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _streak.toDouble()),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOut,
            builder: (ctx, val, _) => Text(
              '${val.toInt()} hari',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Streak saat ini',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, color: AppColors.amber, size: 16),
              const SizedBox(width: 6),
              Text(
                'Terpanjang: $_longestStreak hari',
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Card 4: Phase Progress ─────────────────────────────────────────────────

  Widget _buildPhaseProgressCard() {
    return PMOCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Progress Fase'),
          const SizedBox(height: 16),
          _PhaseProgressBar(
            label: 'Fase Intensif',
            pills: 'RHZE · 2 bulan',
            progress: 1.0,
            color: AppColors.primary,
            isComplete: true,
          ),
          const SizedBox(height: 16),
          _PhaseProgressBar(
            label: 'Fase Lanjutan',
            pills: 'RH · 4 bulan',
            progress: _lanjutanProgress,
            color: AppColors.amber,
            isComplete: false,
          ),
        ],
      ),
    );
  }

  // ── Card 5: Side Effects ───────────────────────────────────────────────────

  Widget _buildSideEffectsCard() {
    return PMOCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionTitle('Efek Samping'),
              if (_sideEffects.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.tealSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_sideEffects.length} laporan',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_sideEffects.isEmpty)
            const PMOEmptyState(
              title: 'Tidak ada efek samping',
              subtitle: 'Belum ada efek samping yang dilaporkan bulan ini.',
            )
          else
            ..._sideEffects.map((e) => _SideEffectTile(entry: e)),
        ],
      ),
    );
  }
}

// ── Private helper widgets ─────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

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

class _CalendarGrid extends StatelessWidget {
  final List<_DayStatus> days;
  const _CalendarGrid({required this.days});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: days.length,
      itemBuilder: (ctx, i) {
        final status = days[i];
        final Color statusColor = switch (status) {
          _DayStatus.confirmed => AppColors.success,
          _DayStatus.late => AppColors.amber,
          _DayStatus.missed => AppColors.danger,
          _DayStatus.future => AppColors.border,
        };
        final isFuture = status == _DayStatus.future;
        return Container(
          decoration: BoxDecoration(
            color: isFuture
                ? AppColors.background
                : statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isFuture
                  ? AppColors.border
                  : statusColor.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              '${i + 1}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isFuture ? AppColors.textMute : statusColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _CalendarLegend(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textMute),
        ),
      ],
    );
  }
}

class _ChartToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChartToggle(this.label, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textMute,
          ),
        ),
      ),
    );
  }
}

class _ChartLegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _ChartLegendDot(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMute),
        ),
      ],
    );
  }
}

class _PhaseProgressBar extends StatelessWidget {
  final String label;
  final String pills;
  final double progress;
  final Color color;
  final bool isComplete;

  const _PhaseProgressBar({
    required this.label,
    required this.pills,
    required this.progress,
    required this.color,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  pills,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMute,
                  ),
                ),
              ],
            ),
            if (isComplete)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '✓ Selesai',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              )
            else
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOut,
            builder: (ctx, val, _) => LinearProgressIndicator(
              value: val,
              minHeight: 10,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}

class _SideEffectTile extends StatelessWidget {
  final _SideEffectEntry entry;
  const _SideEffectTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.amberSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_amber,
              color: AppColors.amber,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.date,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMute,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.tealSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              entry.severity,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
