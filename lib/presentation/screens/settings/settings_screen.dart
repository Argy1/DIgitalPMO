import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/pmo_card.dart';
import '../../../core/widgets/pmo_header.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Ags',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _name = 'Pengguna';
  String _phone = '-';
  bool _isVerified = false;

  // Notification prefs
  TimeOfDay _medTime = const TimeOfDay(hour: 7, minute: 0);
  int _reminderBefore = 30; // 15 | 30 | 60
  bool _secondReminder = true;
  bool _controlReminder = true;
  bool _educationTips = false;
  bool _motivationNotif = true;

  String _phase = '-';
  DateTime _startDate = DateTime.now();

  // Hospitalized mode
  bool _isHospitalized = false;

  // Security
  bool _biometricEnabled = false;

  // App info
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _loadVersion();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ApiService.instance.getMyProfile();
      if (!mounted) return;
      final user = data['user'] as Map<String, dynamic>?;
      final profile = data['patient_profile'] as Map<String, dynamic>?;
      setState(() {
        _name = user?['full_name'] as String? ?? _name;
        _phone = user?['phone_number'] as String? ?? _phone;
        _isVerified = user?['is_verified'] as bool? ?? _isVerified;
        _phase = profile?['current_phase'] as String? ?? _phase;
        final start = profile?['treatment_start_date'] as String?;
        if (start != null) {
          _startDate = DateTime.tryParse(start) ?? _startDate;
        }
      });
    } catch (_) {}
  }

  Future<void> _loadPrefs() async {
    final box = await Hive.openBox('user_settings');
    if (!mounted) return;
    setState(() {
      final h = box.get('medication_hour', defaultValue: 7) as int;
      final m = box.get('medication_minute', defaultValue: 0) as int;
      _medTime = TimeOfDay(hour: h, minute: m);
      _reminderBefore =
          box.get('reminder_minutes_before', defaultValue: 30) as int;
      _secondReminder = box.get('second_reminder', defaultValue: true) as bool;
      _controlReminder =
          box.get('control_reminder', defaultValue: true) as bool;
      _educationTips = box.get('education_tips', defaultValue: false) as bool;
      _motivationNotif =
          box.get('motivation_notif', defaultValue: true) as bool;
      _biometricEnabled =
          box.get('biometric_enabled', defaultValue: false) as bool;
      _isHospitalized =
          box.get('hospitalized_mode', defaultValue: false) as bool;
    });
  }

  Future<void> _savePref(String key, dynamic value) async {
    final box = await Hive.openBox('user_settings');
    await box.put(key, value);
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = info.version);
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _pickMedTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _medTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _medTime = picked);
      await _savePref('medication_hour', picked.hour);
      await _savePref('medication_minute', picked.minute);
      // TODO: reschedule local notification
    }
  }

  void _showReminderOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final options = [
          (15, '15 menit sebelumnya'),
          (30, '30 menit sebelumnya'),
          (60, '1 jam sebelumnya'),
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Reminder sebelum obat',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 8),
                for (final (minutes, label) in options)
                  ListTile(
                    title: Text(label, style: const TextStyle(fontSize: 14)),
                    trailing: _reminderBefore == minutes
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () async {
                      setState(() => _reminderBefore = minutes);
                      await _savePref('reminder_minutes_before', minutes);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleHospitalized(bool value) {
    if (!value) {
      setState(() => _isHospitalized = false);
      _savePref('hospitalized_mode', false);
      ApiService.instance.updateHospitalized(false);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mode Rawat Inap'),
        content: const Text(
          'Aktifkan mode ini jika kamu sedang dirawat di RS. '
          'Reminder akan dinonaktifkan sementara.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isHospitalized = true);
              _savePref('hospitalized_mode', true);
              ApiService.instance.updateHospitalized(true);
            },
            child: const Text(
              'Aktifkan',
              style: TextStyle(color: AppColors.amber),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final auth = LocalAuthentication();
      final canCheck = await auth.canCheckBiometrics;
      if (!canCheck) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometrik tidak tersedia di perangkat ini'),
            ),
          );
        }
        return;
      }
      final authenticated = await auth.authenticate(
        localizedReason: 'Konfirmasi untuk mengaktifkan login biometrik',
      );
      if (!authenticated) return;
    }
    setState(() => _biometricEnabled = value);
    await _savePref('biometric_enabled', value);
  }

  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua Data?'),
        content: const Text(
          'Semua data lokal termasuk riwayat pengobatan dan gejala akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _confirmDeleteData();
            },
            child: const Text(
              'Lanjutkan',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Terakhir'),
        content: const Text(
          'Apakah kamu yakin? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Hive.deleteFromDisk();
              if (mounted) context.go('/login');
            },
            child: const Text(
              'Hapus Semua',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Akun?'),
        content: const Text('Semua data lokal akan tetap tersimpan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.instance.logout();
              await _savePref('is_logged_in', false);
              if (mounted) context.go('/login');
            },
            child: const Text(
              'Keluar',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final estimatedEnd = _startDate.add(const Duration(days: 168));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            PMOHeader(
              title: 'Pengaturan',
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home/dashboard');
                }
              },
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  // ── Profile card ───────────────────────────────────────
                  _ProfileCard(
                    name: _name,
                    phone: _phone,
                    isVerified: _isVerified,
                    onEdit: () => context.push('/settings/edit-profile'),
                  ),
                  const SizedBox(height: 16),

                  // ── Notifikasi ─────────────────────────────────────────
                  _SectionCard(
                    title: 'Notifikasi',
                    children: [
                      _SettingsTile(
                        icon: Icons.access_time_rounded,
                        label: 'Jam minum obat',
                        value: _medTime.format(context),
                        onTap: _pickMedTime,
                      ),
                      _SettingsTile(
                        icon: Icons.timer_outlined,
                        label: 'Reminder sebelum',
                        value: _reminderBefore == 60
                            ? '1 jam'
                            : '$_reminderBefore menit',
                        onTap: _showReminderOptions,
                      ),
                      _SettingsToggle(
                        icon: Icons.notifications_active_outlined,
                        label: 'Pengingat ke-2 jika tidak respons',
                        value: _secondReminder,
                        onChanged: (v) {
                          setState(() => _secondReminder = v);
                          _savePref('second_reminder', v);
                        },
                      ),
                      _SettingsToggle(
                        icon: Icons.calendar_today_outlined,
                        label: 'Reminder kontrol dokter',
                        value: _controlReminder,
                        onChanged: (v) {
                          setState(() => _controlReminder = v);
                          _savePref('control_reminder', v);
                        },
                      ),
                      _SettingsToggle(
                        icon: Icons.menu_book_outlined,
                        label: 'Tips & edukasi harian',
                        value: _educationTips,
                        onChanged: (v) {
                          setState(() => _educationTips = v);
                          _savePref('education_tips', v);
                        },
                      ),
                      _SettingsToggle(
                        icon: Icons.emoji_events_outlined,
                        label: 'Notifikasi motivasi',
                        value: _motivationNotif,
                        onChanged: (v) {
                          setState(() => _motivationNotif = v);
                          _savePref('motivation_notif', v);
                        },
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Pengobatan ─────────────────────────────────────────
                  _SectionCard(
                    title: 'Pengobatan',
                    children: [
                      _SettingsTile(
                        icon: Icons.medical_information_outlined,
                        label: 'Fase saat ini',
                        value: _phase,
                        valueColor: AppColors.primary,
                        isReadOnly: true,
                      ),
                      _SettingsTile(
                        icon: Icons.play_circle_outline,
                        label: 'Tanggal mulai',
                        value:
                            '${_startDate.day} ${_months[_startDate.month - 1]} ${_startDate.year}',
                        isReadOnly: true,
                      ),
                      _SettingsTile(
                        icon: Icons.flag_outlined,
                        label: 'Estimasi selesai',
                        value:
                            '${estimatedEnd.day} ${_months[estimatedEnd.month - 1]} ${estimatedEnd.year}',
                        isReadOnly: true,
                      ),
                      _SettingsToggle(
                        icon: Icons.local_hospital_outlined,
                        label: 'Mode Rawat Inap',
                        value: _isHospitalized,
                        onChanged: _toggleHospitalized,
                        showDivider: false,
                        valueColor: _isHospitalized ? AppColors.amber : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Keamanan ───────────────────────────────────────────
                  _SectionCard(
                    title: 'Keamanan',
                    children: [
                      _SettingsTile(
                        icon: Icons.lock_outline,
                        label: 'Ganti Password',
                        onTap: () => context.push('/settings/change-password'),
                      ),
                      _SettingsToggle(
                        icon: Icons.fingerprint,
                        label: 'Login Biometrik',
                        value: _biometricEnabled,
                        onChanged: _toggleBiometric,
                      ),
                      _SettingsTile(
                        icon: Icons.delete_outline,
                        label: 'Hapus Semua Data',
                        labelColor: AppColors.danger,
                        onTap: _showDeleteDataDialog,
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Tentang ────────────────────────────────────────────
                  _SectionCard(
                    title: 'Tentang',
                    children: [
                      _SettingsTile(
                        icon: Icons.info_outline,
                        label: 'Versi Aplikasi',
                        value: _appVersion,
                        isReadOnly: true,
                      ),
                      _SettingsTile(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Kebijakan Privasi',
                        onTap: () => context.push('/settings/privacy-policy'),
                      ),
                      _SettingsTile(
                        icon: Icons.description_outlined,
                        label: 'Syarat & Ketentuan',
                        onTap: () => context.push('/settings/terms-conditions'),
                      ),
                      _SettingsTile(
                        icon: Icons.support_agent_outlined,
                        label: 'Hubungi Dukungan',
                        onTap: () => context.push('/settings/contact-support'),
                      ),
                      _SettingsTile(
                        icon: Icons.star_outline,
                        label: 'Rate Aplikasi',
                        onTap: () => context.push('/settings/rate-app'),
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Logout ─────────────────────────────────────────────
                  _DangerGhostButton(
                    label: 'Keluar dari Akun',
                    onTap: _showLogoutDialog,
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

// ── Profile card ─────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final String name;
  final String phone;
  final bool isVerified;
  final VoidCallback onEdit;

  const _ProfileCard({
    required this.name,
    required this.phone,
    required this.isVerified,
    required this.onEdit,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return PMOCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      phone,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMute,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _VerificationBadge(isVerified: isVerified),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onEdit,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.tealSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'Edit Profil →',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
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

class _VerificationBadge extends StatelessWidget {
  final bool isVerified;
  const _VerificationBadge({required this.isVerified});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isVerified
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.verified : Icons.warning_amber_rounded,
            size: 12,
            color: isVerified ? AppColors.success : AppColors.amber,
          ),
          const SizedBox(width: 4),
          Text(
            isVerified ? 'Terverifikasi' : 'Belum Terverifikasi',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isVerified ? AppColors.success : AppColors.amber,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textMute,
              letterSpacing: 0.8,
            ),
          ),
        ),
        PMOCard(
          padding: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ── Settings tile ─────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Color? labelColor;
  final Color? valueColor;
  final bool isReadOnly;
  final VoidCallback? onTap;
  final bool showDivider;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.value,
    this.labelColor,
    this.valueColor,
    this.isReadOnly = false,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: isReadOnly ? null : onTap,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: labelColor ?? AppColors.text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (value != null)
                  Text(
                    value!,
                    style: TextStyle(
                      fontSize: 13,
                      color: valueColor ?? AppColors.textMute,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (!isReadOnly) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: labelColor ?? AppColors.textMute,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 48, color: AppColors.border),
      ],
    );
  }
}

// ── Settings toggle ───────────────────────────────────────────────────────────

class _SettingsToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;
  final Color? valueColor;

  const _SettingsToggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.showDivider = true,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.text,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              CupertinoSwitch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: valueColor ?? AppColors.primary,
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 48, color: AppColors.border),
      ],
    );
  }
}

// ── Danger ghost button ───────────────────────────────────────────────────────

class _DangerGhostButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DangerGhostButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: AppDimensions.btnHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.btnRadius),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.logout, color: AppColors.danger, size: 18),
              SizedBox(width: 8),
              Text(
                'Keluar dari Akun',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
