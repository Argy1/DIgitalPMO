import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/pmo_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameCtrl = TextEditingController(text: 'Budi Santoso');
  final _emailCtrl = TextEditingController(text: '');
  final _addressCtrl = TextEditingController(text: '');
  final _faskesCtrl = TextEditingController(text: 'RSUD Cipto Mangunkusumo');
  final _doctorCtrl = TextEditingController(text: 'dr. Siti Rahayu, Sp.P');

  DateTime? _dob = DateTime(1990, 5, 15);
  String _gender = 'laki-laki';

  bool _isLoading = false;

  late final AnimationController _entryCtrl;
  late final List<Animation<double>> _sectionAnims;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _sectionAnims = List.generate(5, (i) {
      final start = i * 0.15;
      final end = (start + 0.55).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _entryCtrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });
    _entryCtrl.forward();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ApiService.instance.getMyProfile();
      if (!mounted) return;
      final user = data['user'] as Map<String, dynamic>?;
      final profile = data['patient_profile'] as Map<String, dynamic>?;
      if (user != null) {
        _nameCtrl.text = user['full_name'] as String? ?? _nameCtrl.text;
        _emailCtrl.text = user['email'] as String? ?? '';
      }
      if (profile != null) {
        _addressCtrl.text = profile['address'] as String? ?? '';
        _faskesCtrl.text = profile['faskes_name'] as String? ?? _faskesCtrl.text;
        _doctorCtrl.text = profile['doctor_name'] as String? ?? _doctorCtrl.text;
        final g = profile['gender'] as String?;
        if (g != null) _gender = g;
        final dobStr = profile['date_of_birth'] as String?;
        if (dobStr != null) _dob = DateTime.tryParse(dobStr);
      }
      setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _faskesCtrl.dispose();
    _doctorCtrl.dispose();
    super.dispose();
  }

  String get _initials {
    final parts = _nameCtrl.text.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    final n = _nameCtrl.text.trim();
    return n.isEmpty ? 'U' : n.substring(0, n.length.clamp(1, 2)).toUpperCase();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1990),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  String _formatDob(DateTime? d) {
    if (d == null) return 'Pilih tanggal';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ApiService.instance.updateUserProfile(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      );
      await ApiService.instance.updatePatientProfile({
        'gender': _gender,
        'address': _addressCtrl.text.trim(),
        'faskes_name': _faskesCtrl.text.trim(),
        'doctor_name': _doctorCtrl.text.trim(),
        if (_dob != null)
          'date_of_birth':
              '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}',
      });
      if (mounted) {
        _showSuccess();
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) _showError(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Profil berhasil diperbarui'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                children: [
                  _animated(
                    _buildSection(
                      title: 'INFORMASI PRIBADI',
                      icon: Icons.person_outline_rounded,
                      children: [
                        _field(
                          controller: _nameCtrl,
                          label: 'Nama Lengkap',
                          icon: Icons.badge_outlined,
                          validator: (v) =>
                              (v == null || v.trim().length < 3)
                                  ? 'Nama minimal 3 karakter'
                                  : null,
                        ),
                        const SizedBox(height: 14),
                        _field(
                          controller: _emailCtrl,
                          label: 'Email (opsional)',
                          icon: Icons.email_outlined,
                          keyboard: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final emailRx = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                            return emailRx.hasMatch(v.trim())
                                ? null
                                : 'Format email tidak valid';
                          },
                        ),
                        const SizedBox(height: 14),
                        _dobField(),
                        const SizedBox(height: 14),
                        _genderField(),
                      ],
                    ),
                    0,
                  ),
                  const SizedBox(height: 16),
                  _animated(
                    _buildSection(
                      title: 'ALAMAT & KONTAK',
                      icon: Icons.location_on_outlined,
                      children: [
                        _field(
                          controller: _addressCtrl,
                          label: 'Alamat Lengkap',
                          icon: Icons.home_outlined,
                          maxLines: 3,
                        ),
                      ],
                    ),
                    1,
                  ),
                  const SizedBox(height: 16),
                  _animated(
                    _buildSection(
                      title: 'INFORMASI MEDIS',
                      icon: Icons.local_hospital_outlined,
                      children: [
                        _field(
                          controller: _faskesCtrl,
                          label: 'Fasilitas Kesehatan',
                          icon: Icons.apartment_outlined,
                        ),
                        const SizedBox(height: 14),
                        _field(
                          controller: _doctorCtrl,
                          label: 'Nama Dokter',
                          icon: Icons.medical_information_outlined,
                        ),
                      ],
                    ),
                    2,
                  ),
                  const SizedBox(height: 24),
                  _animated(
                    PMOButton(
                      'Simpan Perubahan',
                      onPressed: _save,
                      isLoading: _isLoading,
                      icon: Icons.save_rounded,
                    ),
                    3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _animated(Widget child, int index) {
    final anim = _sectionAnims[index];
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) => Opacity(
        opacity: (0.2 + 0.8 * anim.value).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - anim.value)),
          child: child,
        ),
      ),
      child: child,
    );
  }

  Widget _buildHeader() {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
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
      child: Column(
        children: [
          Row(
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
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Edit Profil',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Avatar
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4), width: 2.5),
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.amber,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Nama Pengguna',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textMute),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
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
            borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
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
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      validator: validator,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.text,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: AppColors.textMute),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
    );
  }

  Widget _dobField() {
    return GestureDetector(
      onTap: _pickDob,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.cake_outlined, color: AppColors.primary, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tanggal Lahir',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMute,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDob(_dob),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.calendar_today_rounded,
                color: AppColors.textMute, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _genderField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Icon(Icons.wc_rounded, color: AppColors.primary, size: 18),
                SizedBox(width: 12),
                Text(
                  'Jenis Kelamin',
                  style: TextStyle(fontSize: 13, color: AppColors.textMute),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _genderOption('laki-laki', 'Laki-laki', Icons.male_rounded),
              const SizedBox(width: 12),
              _genderOption(
                  'perempuan', 'Perempuan', Icons.female_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _genderOption(String value, String label, IconData icon) {
    final selected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? AppColors.primary : AppColors.textMute,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.primary : AppColors.textMute,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
