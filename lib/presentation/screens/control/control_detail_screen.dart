import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/pmo_button.dart';
import '../../../core/widgets/pmo_header.dart';

const _controlDays = [60, 150, 180];
const _controlLabels = ['Kontrol 1', 'Kontrol 2', 'Kontrol 3'];
const _controlDesc = [
  'Akhir Fase Intensif — Bulan ke-2',
  'Evaluasi Lanjutan — Bulan ke-5',
  'Selesai Pengobatan — Bulan ke-6',
];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des',
];
const _reminderLabels = ['H-3', 'H-1', 'H-0'];
const _reminderOffsets = ['3', '1', '0'];

enum _ControlStatus { upcoming, overdue, completed }

class ControlDetailScreen extends StatefulWidget {
  const ControlDetailScreen({super.key});

  @override
  State<ControlDetailScreen> createState() => _ControlDetailScreenState();
}

class _ControlDetailScreenState extends State<ControlDetailScreen> {
  bool _isLoading = true;
  // Default: 70 days ago so Kontrol 1 is overdue, 2&3 upcoming
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 70));
  Set<String> _completedIds = {};
  Map<String, DateTime> _completedDates = {};
  Map<String, bool> _reminderToggles = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final box = await Hive.openBox('control_settings');
    final completedRaw = box.get('completed_ids');
    final datesRaw = box.get('completed_dates');

    final completed = completedRaw != null
        ? Set<String>.from(completedRaw as List)
        : <String>{};

    final completedDates = <String, DateTime>{};
    if (datesRaw != null) {
      final map = Map<String, dynamic>.from(datesRaw as Map);
      map.forEach((k, v) => completedDates[k] = DateTime.parse(v as String));
    }

    final toggles = <String, bool>{};
    for (var i = 0; i < 3; i++) {
      for (final h in _reminderOffsets) {
        final key = 'reminder_${i}_$h';
        toggles[key] = box.get(key, defaultValue: true) as bool;
      }
    }

    // Ambil treatment_start_date dari API profil (sumber kebenaran utama)
    DateTime? startFromApi;
    try {
      final profileData = await ApiService.instance.getMyProfile();
      final profile = profileData['patient_profile'] as Map<String, dynamic>?;
      final s = profile?['treatment_start_date'] as String?;
      if (s != null) {
        startFromApi = DateTime.tryParse(s);
        // Simpan ke Hive agar tersedia offline
        if (startFromApi != null) {
          await box.put('start_date', startFromApi.toIso8601String());
        }
      }
    } catch (_) {
      // Fallback ke Hive cache jika offline
      final cached = box.get('start_date') as String?;
      if (cached != null) startFromApi = DateTime.tryParse(cached);
    }

    if (mounted) {
      setState(() {
        if (startFromApi != null) _startDate = startFromApi;
        _completedIds = completed;
        _completedDates = completedDates;
        _reminderToggles = toggles;
        _isLoading = false;
      });
    }
  }

  Future<void> _markCompleted(int index) async {
    final id = 'control_$index';
    final now = DateTime.now();
    setState(() {
      _completedIds.add(id);
      _completedDates[id] = now;
    });
    final box = await Hive.openBox('control_settings');
    await box.put('completed_ids', _completedIds.toList());
    final datesMap = <String, String>{};
    _completedDates.forEach((k, v) => datesMap[k] = v.toIso8601String());
    await box.put('completed_dates', datesMap);
  }

  Future<void> _setReminder(String key, bool value) async {
    setState(() => _reminderToggles[key] = value);
    final box = await Hive.openBox('control_settings');
    await box.put(key, value);
  }

  DateTime _controlDate(int index) =>
      _startDate.add(Duration(days: _controlDays[index]));

  _ControlStatus _statusOf(int index) {
    if (_completedIds.contains('control_$index')) {
      return _ControlStatus.completed;
    }
    if (DateTime.now().isAfter(_controlDate(index))) {
      return _ControlStatus.overdue;
    }
    return _ControlStatus.upcoming;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            PMOHeader(
              title: 'Jadwal Kontrol',
              subtitle: 'Kontrol rutin pengobatan TB',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      children: [
                        for (var i = 0; i < 3; i++) ...[
                          _ControlCard(
                            index: i,
                            label: _controlLabels[i],
                            desc: _controlDesc[i],
                            date: _controlDate(i),
                            status: _statusOf(i),
                            completedAt: _completedDates['control_$i'],
                            reminderToggles: _reminderToggles,
                            onMarkCompleted: () => _markCompleted(i),
                            onReminderToggle: _setReminder,
                          ),
                          const SizedBox(height: 12),
                        ],
                        const SizedBox(height: 4),
                        _AISummaryButton(
                          onTap: () {
                            final now = DateTime.now();
                            final ym =
                                '${now.year}-${now.month.toString().padLeft(2, '0')}';
                            context.push('/report/$ym');
                          },
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

// ── Control card ───────────────────────────────────────────────────────────

class _ControlCard extends StatelessWidget {
  final int index;
  final String label;
  final String desc;
  final DateTime date;
  final _ControlStatus status;
  final DateTime? completedAt;
  final Map<String, bool> reminderToggles;
  final VoidCallback onMarkCompleted;
  final void Function(String key, bool value) onReminderToggle;

  const _ControlCard({
    required this.index,
    required this.label,
    required this.desc,
    required this.date,
    required this.status,
    required this.completedAt,
    required this.reminderToggles,
    required this.onMarkCompleted,
    required this.onReminderToggle,
  });

  Color get _accentColor {
    switch (status) {
      case _ControlStatus.upcoming:
        return AppColors.primary;
      case _ControlStatus.overdue:
        return AppColors.amber;
      case _ControlStatus.completed:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.dark.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildStatusSection(context),
                  const Divider(color: AppColors.border, height: 24),
                  _buildReminders(),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.cardRadius),
                  bottomLeft: Radius.circular(AppDimensions.cardRadius),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date box
        Container(
          width: 52,
          height: 56,
          decoration: BoxDecoration(
            color: _accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _months[date.month - 1].toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _accentColor,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _accentColor,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (status == _ControlStatus.upcoming) _DaysLeftBadge(date),
                  if (status == _ControlStatus.completed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Selesai',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMute,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection(BuildContext context) {
    switch (status) {
      case _ControlStatus.upcoming:
        return PMOButton(
          'Lihat Detail',
          variant: ButtonVariant.ghost,
          onPressed: () {},
        );

      case _ControlStatus.overdue:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.amberSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.amber, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Kontrol ini sudah lewat jadwal',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.amber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            PMOButton(
              'Tandai Sudah Kontrol',
              variant: ButtonVariant.amber,
              onPressed: onMarkCompleted,
            ),
          ],
        );

      case _ControlStatus.completed:
        final at = completedAt;
        return Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 20),
            const SizedBox(width: 8),
            Text(
              at != null
                  ? 'Selesai ${at.day} ${_months[at.month - 1]} ${at.year}'
                  : 'Sudah diselesaikan',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
    }
  }

  Widget _buildReminders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pengingat',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textMute,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(_reminderLabels.length, (ri) {
            final key = 'reminder_${index}_${_reminderOffsets[ri]}';
            final isOn = reminderToggles[key] ?? true;
            return Expanded(
              child: _ReminderToggle(
                label: _reminderLabels[ri],
                value: isOn,
                onChanged: (v) => onReminderToggle(key, v),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ── Reminder toggle ─────────────────────────────────────────────────────────

class _ReminderToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ReminderToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CupertinoSwitch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primary,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: value ? AppColors.primary : AppColors.textMute,
          ),
        ),
      ],
    );
  }
}

// ── Days left badge ──────────────────────────────────────────────────────────

class _DaysLeftBadge extends StatelessWidget {
  final DateTime date;
  const _DaysLeftBadge(this.date);

  @override
  Widget build(BuildContext context) {
    final days = date.difference(DateTime.now()).inDays + 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.tealSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$days hari lagi',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ── AI summary button ────────────────────────────────────────────────────────

class _AISummaryButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AISummaryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.description_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lihat Ringkasan untuk Dokter',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Summary kondisi 1 bulan terakhir',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}
