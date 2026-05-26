import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pmo_med_pill.dart';
import '../../../core/widgets/pmo_shimmer.dart';
import '../../../core/widgets/pmo_empty_state.dart';
import '../../../core/utils/tb_calculator.dart';
import '../../../data/models/app_state_model.dart';
import 'widgets/hospitalized_banner.dart';
import 'widgets/milestone_widget.dart';
import 'widgets/phase_transition_dialog.dart';

enum MedicationStatus { notTaken, confirmed, late, missed }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = 'Periksa koneksi internetmu lalu coba lagi.';

  late final AnimationController _staggerCtrl;
  late final List<Animation<double>> _cardAnims;

  String _firstName = '';
  int _streak = 0;
  final bool _hasUnreadNotif = false;

  MedicationStatus _medStatus = MedicationStatus.notTaken;
  String? _confirmedAt;
  bool _isHospitalized = false;

  String _phase = 'intensive';
  double _progress = 0.0;
  int _dayNumber = 1;
  final int _totalDays = 180;
  int _daysRemaining = 180;

  int _adherence = 0;
  int _confirmedDoses = 0;
  int _totalDoses = 0;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _cardAnims = List.generate(6, (i) {
      final start = i * 0.1;
      final end = (start + 0.4).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _staggerCtrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });
    _loadDashboard();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final now = DateTime.now();
      final monthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      final profileData = await ApiService.instance.getMyProfile();
      final user = profileData['user'] as Map<String, dynamic>?;
      final profile = profileData['patient_profile'] as Map<String, dynamic>?;

      if (user != null) {
        final fullName = (user['full_name'] as String? ?? '').trim();
        _firstName = fullName.isEmpty ? 'Teman' : fullName.split(' ').first;
      }

      if (profile == null) {
        if (!mounted) return;
        final phone = Uri.encodeComponent(
          user?['phone_number'] as String? ?? '',
        );
        final name = Uri.encodeComponent(user?['full_name'] as String? ?? '');
        context.go('/setup-profile/$phone/$name');
        return;
      }

      final results = await Future.wait([
        ApiService.instance.getTodayMedication(),
        ApiService.instance.getMedicationHistory(monthStr),
      ]);

      final todayData = results[0];
      final historyData = results[1];

      _phase = profile['current_phase'] as String? ?? 'intensive';
      _isHospitalized = profile['is_hospitalized'] as bool? ?? false;
      final startStr = profile['treatment_start_date'] as String?;
      final startDate = startStr == null ? null : DateTime.tryParse(startStr);
      if (startDate != null) {
        _dayNumber = TBCalculator.getDayNumber(startDate, now);
        _daysRemaining = (_totalDays - _dayNumber).clamp(0, _totalDays);
        _progress = (_dayNumber / _totalDays).clamp(0.0, 1.0);
      }

      _streak = todayData['streak_count'] as int? ?? 0;
      final logs = todayData['logs'] as List<dynamic>? ?? [];
      final confirmedLog = logs.cast<Map<String, dynamic>>().firstWhere(
        (log) => log['status'] == 'confirmed',
        orElse: () => {},
      );
      if (confirmedLog.isNotEmpty) {
        _medStatus = MedicationStatus.confirmed;
        final rawAt = confirmedLog['confirmed_at'] as String?;
        if (rawAt != null) {
          final dt = DateTime.tryParse(rawAt);
          if (dt != null) {
            _confirmedAt =
                '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
          }
        }
      }

      final historyDays = historyData['days'] as List<dynamic>? ?? [];
      int confirmed = 0;
      int total = 0;
      for (final day in historyDays) {
        final dayLogs =
            (day as Map<String, dynamic>)['logs'] as List<dynamic>? ?? [];
        total += dayLogs.length;
        for (final log in dayLogs) {
          if ((log as Map<String, dynamic>)['status'] == 'confirmed') {
            confirmed++;
          }
        }
      }
      _confirmedDoses = confirmed;
      _totalDoses = total;
      _adherence = total > 0 ? ((confirmed / total) * 100).round() : 0;

      if (mounted) {
        setState(() => _isLoading = false);
        _staggerCtrl.forward(from: 0);
        _checkPhaseTransition();
        _checkTreatmentCompletion();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = apiErrorMessage(e);
        });
      }
    }
  }

  Future<void> _checkPhaseTransition() async {
    if (TBCalculator.shouldTransitionPhase(_dayNumber) && mounted) {
      final box = await Hive.openBox<AppStateModel>('appState');
      final appState = box.get('state');

      if (appState == null ||
          !appState.hasShownDialog('phase_transition_day_57')) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => PhaseTransitionDialog(
              currentPhase: 'intensive',
              nextPhase: 'continuation',
              oldMeds: 'RHZE',
              newMeds: 'RH',
              onConfirm: () async {
                final updatedState =
                    (appState ?? AppStateModel(patientId: 'current_user'))
                        .markDialogShown('phase_transition_day_57');
                await box.put('state', updatedState);
              },
            ),
          );
        }
      }
    }
  }

  Future<void> _checkTreatmentCompletion() async {
    if (!TBCalculator.isCompleted(_dayNumber) || !mounted) return;
    final box = await Hive.openBox<AppStateModel>('appState');
    final appState = box.get('state');
    const key = 'treatment_completed';
    if (appState != null && appState.hasShownDialog(key)) return;
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => MilestoneWidget(
        progressPercentage: 100,
        showFullscreen: true,
        onDismiss: () async {
          final updated = (appState ?? AppStateModel(patientId: 'current_user'))
              .markDialogShown(key);
          await box.put('state', updated);
        },
      ),
    );
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'pagi';
    if (hour < 15) return 'siang';
    if (hour < 19) return 'sore';
    return 'malam';
  }

  String get _todayLabel {
    final now = DateTime.now();
    const days = [
      'SENIN',
      'SELASA',
      'RABU',
      'KAMIS',
      'JUMAT',
      'SABTU',
      'MINGGU',
    ];
    const months = [
      'JANUARI',
      'FEBRUARI',
      'MARET',
      'APRIL',
      'MEI',
      'JUNI',
      'JULI',
      'AGUSTUS',
      'SEPTEMBER',
      'OKTOBER',
      'NOVEMBER',
      'DESEMBER',
    ];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  Future<void> _confirmMedication() async {
    final result = await context.push<bool>('/medication/confirm');
    if (result == true && mounted) {
      final now = TimeOfDay.now();
      setState(() {
        _medStatus = MedicationStatus.confirmed;
        _confirmedAt =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          if (_isHospitalized)
            HospitalizedBanner(
              onDisable: () => setState(() => _isHospitalized = false),
            ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    _Header(
                      greeting: _greeting,
                      firstName: _firstName,
                      todayLabel: _todayLabel,
                      streak: _streak,
                      hasUnreadNotif: _hasUnreadNotif,
                      onBellTap: () => context.push('/notification-history'),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _hasError
                          ? _buildError()
                          : _isLoading
                          ? _buildLoading()
                          : _buildContent(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: PMOEmptyState(
        title: 'Gagal memuat data',
        subtitle: _errorMessage,
        actionLabel: 'Coba Lagi',
        onAction: _loadDashboard,
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      children: const [
        PMOShimmer(height: 260),
        SizedBox(height: 14),
        PMOShimmer(height: 150),
        SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: PMOShimmer(height: 120)),
            SizedBox(width: 12),
            Expanded(child: PMOShimmer(height: 120)),
          ],
        ),
        SizedBox(height: 14),
        PMOShimmer(height: 88),
        SizedBox(height: 14),
        PMOShimmer(height: 96),
      ],
    );
  }

  Widget _animCard(Widget child, int index) {
    final anim = _cardAnims[index];
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) => Opacity(
        opacity: (0.3 + 0.7 * anim.value).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - anim.value)),
          child: child,
        ),
      ),
      child: child,
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _animCard(
          _MedicineCard(
            status: _medStatus,
            phase: _phase,
            confirmedAt: _confirmedAt,
            onConfirm: _confirmMedication,
          ),
          0,
        ),
        const SizedBox(height: 14),
        _animCard(
          _ProgressCard(
            phase: _phase,
            progress: _progress,
            dayNumber: _dayNumber,
            totalDays: _totalDays,
            daysRemaining: _daysRemaining,
          ),
          1,
        ),
        const SizedBox(height: 14),
        _animCard(
          _MiniStats(
            adherence: _adherence,
            confirmedDoses: _confirmedDoses,
            totalDoses: _totalDoses,
          ),
          2,
        ),
        const SizedBox(height: 14),
        _animCard(_AIChatCard(onTap: () => context.go('/home/ai-chat')), 3),
        const SizedBox(height: 14),
        _animCard(
          _DoctorVisitCard(onTap: () => context.push('/control/detail/1')),
          4,
        ),
        const SizedBox(height: 14),
        _animCard(_EducationCard(onTap: () => context.push('/education/1')), 5),
      ],
    );
  }
}

// ── Header ───────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String greeting;
  final String firstName;
  final String todayLabel;
  final int streak;
  final bool hasUnreadNotif;
  final VoidCallback onBellTap;

  const _Header({
    required this.greeting,
    required this.firstName,
    required this.todayLabel,
    required this.streak,
    required this.hasUnreadNotif,
    required this.onBellTap,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top + 16;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.6, -1),
            end: Alignment(0.6, 1),
            colors: [AppColors.primary, Color(0xFF15594B)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(top: -40, right: -40, child: _blob(180, 0.06)),
            Positioned(bottom: -30, left: -20, child: _blob(100, 0.05)),
            Padding(
              padding: EdgeInsets.fromLTRB(20, topPad, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              todayLabel,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Selamat $greeting,',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              '$firstName! 👋',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _BellButton(hasUnread: hasUnreadNotif, onTap: onBellTap),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _StreakChip(streak: streak),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  final bool hasUnread;
  final VoidCallback onTap;

  const _BellButton({required this.hasUnread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 22,
            ),
            if (hasUnread)
              Positioned(
                top: 9,
                right: 9,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.amber,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  final int streak;

  const _StreakChip({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            '$streak hari berturut-turut',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Today's Medicine ─────────────────────────────────────────
class _MedicineCard extends StatelessWidget {
  final MedicationStatus status;
  final String phase;
  final String? confirmedAt;
  final VoidCallback onConfirm;

  const _MedicineCard({
    required this.status,
    required this.phase,
    required this.confirmedAt,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final meds = phase == 'intensive' ? ['R', 'H', 'Z', 'E'] : ['R', 'H'];
    final regimen = meds.join();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          // Card body
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.dark.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'JADWAL HARI INI',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Obat Pagi — $regimen',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 16,
                                color: AppColors.textMute,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '07:00 WIB',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textMute,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _statusBadge,
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    for (var i = 0; i < meds.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: PMOMedPill(kind: meds[i], showLabel: true),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 18),
                if (status == MedicationStatus.confirmed &&
                    confirmedAt != null) ...[
                  Text(
                    'Dikonfirmasi pukul $confirmedAt',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMute,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                _ctaButton,
              ],
            ),
          ),
          // Left accent bar (Stack-based, avoids non-uniform border + radius)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 5,
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color get _accentColor {
    switch (status) {
      case MedicationStatus.confirmed:
        return AppColors.success;
      case MedicationStatus.missed:
        return AppColors.danger;
      case MedicationStatus.late:
      case MedicationStatus.notTaken:
        return AppColors.amber;
    }
  }

  Widget get _statusBadge {
    late final Color bg;
    late final Color fg;
    late final Color dot;
    late final String label;
    switch (status) {
      case MedicationStatus.confirmed:
        bg = const Color(0xFFE6F4EC);
        fg = const Color(0xFF137A3F);
        dot = const Color(0xFF1FA15A);
        label = 'Sudah Diminum ✓';
        break;
      case MedicationStatus.late:
        bg = const Color(0xFFFBE5E2);
        fg = const Color(0xFFA1281C);
        dot = AppColors.danger;
        label = 'Terlambat!';
        break;
      case MedicationStatus.missed:
        bg = const Color(0xFFFBE5E2);
        fg = const Color(0xFFA1281C);
        dot = AppColors.danger;
        label = 'Terlewat';
        break;
      case MedicationStatus.notTaken:
        bg = AppColors.amberSoft;
        fg = const Color(0xFFA66A00);
        dot = AppColors.amber;
        label = 'Belum Diminum';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget get _ctaButton {
    late final String label;
    late final IconData icon;
    late final Gradient? gradient;
    late final bool enabled;
    switch (status) {
      case MedicationStatus.confirmed:
        label = 'Obat sudah terkonfirmasi ✓';
        icon = Icons.check_rounded;
        gradient = AppColors.successGradient;
        enabled = false;
        break;
      case MedicationStatus.late:
        label = 'Konfirmasi Sekarang';
        icon = Icons.camera_alt_rounded;
        gradient = AppColors.amberGradient;
        enabled = true;
        break;
      case MedicationStatus.missed:
        label = 'Catat Sebagai Terlewat';
        icon = Icons.edit_note_rounded;
        gradient = AppColors.amberGradient;
        enabled = true;
        break;
      case MedicationStatus.notTaken:
        label = 'Konfirmasi Minum Obat';
        icon = Icons.camera_alt_rounded;
        gradient = AppColors.primaryGradient;
        enabled = true;
        break;
    }

    return Opacity(
      opacity: enabled ? 1.0 : 0.6,
      child: GestureDetector(
        onTap: enabled ? onConfirm : null,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Progress card ────────────────────────────────────────────
class _ProgressCard extends StatelessWidget {
  final String phase;
  final double progress;
  final int dayNumber;
  final int totalDays;
  final int daysRemaining;

  const _ProgressCard({
    required this.phase,
    required this.progress,
    required this.dayNumber,
    required this.totalDays,
    required this.daysRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final estimatedEnd = DateTime.now().add(Duration(days: daysRemaining));
    final milestone = _milestoneReached(progress);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progress Pengobatan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  phase == 'intensive' ? 'Fase Intensif' : 'Fase Lanjutan',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOut,
            builder: (context, value, _) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${(value * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'selesai',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMute,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          _ProgressBar(progress: progress),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hari ke-$dayNumber dari $totalDays',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMute,
                ),
              ),
              Text(
                '$daysRemaining hari tersisa',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Estimasi selesai: ${_formatDate(estimatedEnd)}',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textMute,
              ),
            ),
          ),
          if (daysRemaining < 30) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF27AE60), Color(0xFF229954)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🏁', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    '$daysRemaining hari lagi menuju bebas TB!',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (milestone != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.amberSoft,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '🎉 $milestone% Tercapai!',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFA66A00),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  int? _milestoneReached(double progress) {
    final pct = (progress * 100).round();
    if (pct >= 75) return 75;
    if (pct >= 50) return 50;
    if (pct >= 25) return 25;
    return null;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;

  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: 16,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOut,
                builder: (context, value, _) {
                  final fillWidth = constraints.maxWidth * value;
                  return SizedBox(
                    width: fillWidth,
                    height: 16,
                    child: Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        Container(
                          height: 10,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, Color(0xFF2A8B73)],
                            ),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        if (fillWidth > 8)
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Mini stats ───────────────────────────────────────────────
class _MiniStats extends StatelessWidget {
  final int adherence;
  final int confirmedDoses;
  final int totalDoses;

  const _MiniStats({
    required this.adherence,
    required this.confirmedDoses,
    required this.totalDoses,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.verified_rounded,
              iconColor: AppColors.primary,
              iconBg: AppColors.primary.withValues(alpha: 0.1),
              value: '$adherence%',
              label: 'Kepatuhan\nbulan ini',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.medication_rounded,
              iconColor: AppColors.amber,
              iconBg: AppColors.amber.withValues(alpha: 0.15),
              valueRich: TextSpan(
                text: '$confirmedDoses',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: AppColors.text,
                ),
                children: [
                  TextSpan(
                    text: '/$totalDoses',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMute,
                    ),
                  ),
                ],
              ),
              label: 'Dosis\nterkonfirmasi',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String? value;
  final TextSpan? valueRich;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.value,
    this.valueRich,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 12),
          if (valueRich != null)
            Text.rich(valueRich!)
          else
            Text(
              value ?? '',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                color: AppColors.text,
              ),
            ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.3,
              color: AppColors.textMute,
            ),
          ),
        ],
      ),
    );
  }
}

// ── AI Chat card ─────────────────────────────────────────────
class _AIChatCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AIChatCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF15302B), Color(0xFF0F2421)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF15302B).withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, Color(0xFF2A8B73)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.smart_toy_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF3ED27E),
                        border: Border.all(
                          color: const Color(0xFF15302B),
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'PMO Digital — AI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF3ED27E,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ONLINE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: Color(0xFF3ED27E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Tanya apapun tentang pengobatanmu',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Doctor visit ─────────────────────────────────────────────
class _DoctorVisitCard extends StatelessWidget {
  final VoidCallback onTap;

  const _DoctorVisitCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.dark.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 64,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '20',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'JUN',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KUNJUNGAN BERIKUTNYA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppColors.textMute,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Kontrol Rutin Dokter',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'RSUD Cipto · 09:30',
                      style: TextStyle(fontSize: 12, color: AppColors.textMute),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.amberSoft,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text(
                  '11 hari lagi',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFA66A00),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Education card ───────────────────────────────────────────
class _EducationCard extends StatelessWidget {
  final VoidCallback onTap;

  const _EducationCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.tealSoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.amber,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EDUKASI HARI INI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Kenapa obat TB tidak boleh putus?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Baca artikel · 2 menit',
                      style: TextStyle(fontSize: 12, color: AppColors.textMute),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom nav ───────────────────────────────────────────────
