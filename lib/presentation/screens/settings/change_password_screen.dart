import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/pmo_button.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _isLoading = false;

  late final AnimationController _entryCtrl;
  late final Animation<double> _formAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _formAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Password strength ──────────────────────────────────────────────────────

  int get _strength {
    final p = _newCtrl.text;
    if (p.isEmpty) return 0;
    int score = 0;
    if (p.length >= 8) score++;
    if (p.contains(RegExp(r'[A-Z]'))) score++;
    if (p.contains(RegExp(r'[0-9]'))) score++;
    if (p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) score++;
    return score;
  }

  Color get _strengthColor {
    switch (_strength) {
      case 1:
        return AppColors.danger;
      case 2:
        return AppColors.amber;
      case 3:
        return const Color(0xFF27AE60).withValues(alpha: 0.8);
      case 4:
        return AppColors.success;
      default:
        return AppColors.border;
    }
  }

  String get _strengthLabel {
    switch (_strength) {
      case 1:
        return 'Lemah';
      case 2:
        return 'Cukup';
      case 3:
        return 'Kuat';
      case 4:
        return 'Sangat Kuat';
      default:
        return '';
    }
  }

  // ── Rules ──────────────────────────────────────────────────────────────────

  bool get _hasMinLength => _newCtrl.text.length >= 8;
  bool get _hasNumber => _newCtrl.text.contains(RegExp(r'[0-9]'));
  bool get _hasLetter => _newCtrl.text.contains(RegExp(r'[A-Za-z]'));
  bool get _passwordsMatch =>
      _newCtrl.text == _confirmCtrl.text && _newCtrl.text.isNotEmpty;

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ApiService.instance.changePassword(
        currentPassword: _currentCtrl.text,
        newPassword: _newCtrl.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Password berhasil diubah'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiErrorMessage(e)),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
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
                      'Ganti Password',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Buat password yang kuat untuk akunmu',
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

          // Body
          Expanded(
            child: FadeTransition(
              opacity: _formAnim,
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                  children: [
                    _card(
                      child: Column(
                        children: [
                          _passwordField(
                            controller: _currentCtrl,
                            label: 'Password Saat Ini',
                            show: _showCurrent,
                            onToggle: () =>
                                setState(() => _showCurrent = !_showCurrent),
                            validator: (v) =>
                                (v == null || v.isEmpty)
                                    ? 'Password tidak boleh kosong'
                                    : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _passwordField(
                            controller: _newCtrl,
                            label: 'Password Baru',
                            show: _showNew,
                            onToggle: () =>
                                setState(() => _showNew = !_showNew),
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Password tidak boleh kosong';
                              }
                              if (!_hasMinLength) return 'Minimal 8 karakter';
                              if (!_hasNumber) return 'Harus mengandung angka';
                              if (!_hasLetter) return 'Harus mengandung huruf';
                              return null;
                            },
                          ),
                          if (_newCtrl.text.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _strengthBar(),
                            const SizedBox(height: 14),
                            _rulesList(),
                          ],
                          const SizedBox(height: 16),
                          _passwordField(
                            controller: _confirmCtrl,
                            label: 'Konfirmasi Password Baru',
                            show: _showConfirm,
                            onToggle: () =>
                                setState(() => _showConfirm = !_showConfirm),
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Konfirmasi password tidak boleh kosong';
                              }
                              if (v != _newCtrl.text) {
                                return 'Password tidak cocok';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    PMOButton(
                      'Ubah Password',
                      onPressed: _submit,
                      isLoading: _isLoading,
                      icon: Icons.lock_reset_rounded,
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

  Widget _card({required Widget child}) {
    return Container(
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
      child: child,
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool show,
    required VoidCallback onToggle,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !show,
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.text,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: AppColors.textMute),
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            color: AppColors.primary, size: 18),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            show
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColors.textMute,
            size: 20,
          ),
        ),
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
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
    );
  }

  Widget _strengthBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _strength / 4,
                  backgroundColor: AppColors.border,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(_strengthColor),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _strengthLabel,
                key: ValueKey(_strengthLabel),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _strengthColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _rulesList() {
    return Column(
      children: [
        _rule(_hasMinLength, 'Minimal 8 karakter'),
        const SizedBox(height: 6),
        _rule(_hasNumber, 'Mengandung angka'),
        const SizedBox(height: 6),
        _rule(_hasLetter, 'Mengandung huruf'),
        const SizedBox(height: 6),
        _rule(
          _passwordsMatch,
          'Password cocok dengan konfirmasi',
        ),
      ],
    );
  }

  Widget _rule(bool passed, String label) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              passed ? Icons.check_circle_rounded : Icons.circle_outlined,
              key: ValueKey(passed),
              size: 16,
              color: passed ? AppColors.success : AppColors.textMute,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: passed ? AppColors.success : AppColors.textMute,
              fontWeight: passed ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
