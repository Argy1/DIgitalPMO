import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pmo_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _agreeToTerms = false;
  bool _isLoading = false;
  String? _nameError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;

  PasswordStrength _getPasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.none;
    if (password.length < 8) return PasswordStrength.weak;
    if (password.length < 12) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  bool _validateForm() {
    bool isValid = true;
    setState(() {
      _nameError = null;
      _phoneError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    if (_nameController.text.trim().isEmpty) {
      setState(() => _nameError = 'Nama lengkap harus diisi');
      isValid = false;
    }

    final phone = normalizePhoneNumber(_phoneController.text);
    if (phone.isEmpty || phone.length < 10 || phone.length > 13) {
      setState(() => _phoneError = 'Nomor HP harus 10-13 digit');
      isValid = false;
    }

    if (_passwordController.text.length < 8) {
      setState(() => _passwordError = 'Password minimal 8 karakter');
      isValid = false;
    }

    if (_confirmPasswordController.text != _passwordController.text) {
      setState(() => _confirmPasswordError = 'Password tidak cocok');
      isValid = false;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Setujui syarat dan ketentuan terlebih dahulu'),
        ),
      );
      isValid = false;
    }

    return isValid;
  }

  Future<void> _handleRegister() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.instance.register(
        name: _nameController.text.trim(),
        phone: normalizePhoneNumber(_phoneController.text),
        password: _passwordController.text,
      );
      if (mounted) {
        final devOtp = result['dev_otp'] as String?;
        if (devOtp != null && devOtp.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('OTP local: $devOtp'),
              duration: const Duration(seconds: 6),
            ),
          );
        }
        final phone = Uri.encodeComponent(
          normalizePhoneNumber(_phoneController.text),
        );
        final name = Uri.encodeComponent(_nameController.text.trim());
        final query = devOtp == null || devOtp.isEmpty ? '' : '?devOtp=$devOtp';
        context.go('/otp/$phone/$name$query');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiErrorMessage(e)),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = (screenHeight * 0.30).clamp(230.0, 320.0);

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: headerHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDeep],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -40,
                  top: -40,
                  child: Opacity(
                    opacity: 0.12,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daftar Akun',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Mulai perjalanan sembuhmu 🌱',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Name input
                    _RegisterInput(
                      label: 'Nama Lengkap',
                      hint: 'Masukkan nama lengkap',
                      controller: _nameController,
                      prefixIcon: Icons.person,
                      error: _nameError,
                    ),
                    const SizedBox(height: 12),
                    // Phone input
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RegisterInput(
                          label: 'Nomor HP',
                          hint: '+62 812-XXXX-XXXX',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.phone,
                          error: _phoneError,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'OTP dikirim ke sini',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMute,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Password input with strength indicator
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RegisterInput(
                          label: 'Password',
                          hint: 'Minimal 8 karakter',
                          controller: _passwordController,
                          keyboardType: TextInputType.visiblePassword,
                          obscureText: true,
                          prefixIcon: Icons.lock,
                          error: _passwordError,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        _PasswordStrengthIndicator(
                          strength: _getPasswordStrength(
                            _passwordController.text,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Confirm password input
                    _RegisterInput(
                      label: 'Konfirmasi Password',
                      hint: 'Ulangi password',
                      controller: _confirmPasswordController,
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: true,
                      prefixIcon: Icons.lock_clock,
                      error: _confirmPasswordError,
                    ),
                    const SizedBox(height: 20),
                    // Terms and conditions checkbox
                    _TermsCheckbox(
                      value: _agreeToTerms,
                      onChanged: (value) {
                        setState(() => _agreeToTerms = value ?? false);
                      },
                    ),
                    const SizedBox(height: 28),
                    // Register button
                    PMOButton(
                      'Daftar Sekarang',
                      onPressed: (_isLoading || !_agreeToTerms)
                          ? null
                          : _handleRegister,
                      isLoading: _isLoading,
                      width: double.infinity,
                    ),
                    const SizedBox(height: 16),
                    // Login link
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          context.go('/login');
                        },
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            children: [
                              TextSpan(
                                text: 'Sudah punya akun? ',
                                style: TextStyle(color: AppColors.textMute),
                              ),
                              TextSpan(
                                text: 'Masuk',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
}

class _RegisterInput extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final IconData prefixIcon;
  final bool obscureText;
  final String? error;
  final ValueChanged<String>? onChanged;

  const _RegisterInput({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    required this.prefixIcon,
    this.obscureText = false,
    this.error,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAF9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: error != null
                    ? AppColors.danger
                    : const Color(0xFFD4ECE6),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: error != null
                    ? AppColors.danger
                    : const Color(0xFFD4ECE6),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: error != null ? AppColors.danger : AppColors.primary,
                width: 2,
              ),
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: error != null ? AppColors.danger : AppColors.primary,
              size: 20,
            ),
            labelStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: error != null ? AppColors.danger : AppColors.textMute,
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.danger,
            ),
          ),
        ],
      ],
    );
  }
}

class _PasswordStrengthIndicator extends StatelessWidget {
  final PasswordStrength strength;

  const _PasswordStrengthIndicator({required this.strength});

  @override
  Widget build(BuildContext context) {
    Color getColor(int index) {
      if (index >= strength.index) {
        return const Color(0xFFD4ECE6);
      }
      if (strength == PasswordStrength.weak) return AppColors.danger;
      if (strength == PasswordStrength.medium) return AppColors.amber;
      return AppColors.success;
    }

    return Row(
      children: List.generate(
        3,
        (index) => Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
            decoration: BoxDecoration(
              color: getColor(index),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;

  const _TermsCheckbox({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => onChanged?.call(!value),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              border: Border.all(
                color: value ? AppColors.primary : const Color(0xFFD4ECE6),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(6),
              color: value ? AppColors.primary : Colors.transparent,
            ),
            child: value
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              children: [
                const TextSpan(text: 'Saya setuju dengan '),
                TextSpan(
                  text: 'Syarat & Ketentuan',
                  style: TextStyle(
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(text: ' dan '),
                TextSpan(
                  text: 'Kebijakan Privasi',
                  style: TextStyle(
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

enum PasswordStrength { none, weak, medium, strong }
