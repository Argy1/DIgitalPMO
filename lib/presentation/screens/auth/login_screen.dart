import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pmo_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;
  String? _phoneError;
  String? _passwordError;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    bool isValid = true;
    setState(() {
      _phoneError = null;
      _passwordError = null;
    });

    final phone = normalizePhoneNumber(_phoneController.text);
    if (phone.isEmpty || phone.length < 10 || phone.length > 13) {
      setState(() => _phoneError = 'Nomor HP harus 10-13 digit');
      isValid = false;
    }

    if (_passwordController.text.length < 8) {
      setState(() => _passwordError = 'Password minimal 8 karakter');
      isValid = false;
    }

    return isValid;
  }

  Future<void> _handleLogin() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      await ApiService.instance.login(
        phone: normalizePhoneNumber(_phoneController.text),
        password: _passwordController.text,
      );
      final profileData = await ApiService.instance.getMyProfile();
      final profile = profileData['patient_profile'] as Map<String, dynamic>?;
      final user = profileData['user'] as Map<String, dynamic>?;
      if (!mounted) return;
      if (profile == null) {
        final phone = Uri.encodeComponent(
          normalizePhoneNumber(_phoneController.text),
        );
        final name = Uri.encodeComponent(user?['full_name'] as String? ?? '');
        context.go('/setup-profile/$phone/$name');
      } else {
        context.go('/home/dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _passwordError = apiErrorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = (screenHeight * 0.34).clamp(260.0, 360.0);

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
                // Decorative blobs
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
                Positioned(
                  left: -60,
                  bottom: -80,
                  child: Opacity(
                    opacity: 0.12,
                    child: Container(
                      width: 250,
                      height: 250,
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'DigitalPMO',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Solusi digital untuk kesembuhan Anda',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Selamat datang kembali 👋',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Phone input
                    _PMOInput(
                      label: 'Nomor HP',
                      hint: '+62 812-XXXX-XXXX',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone,
                      error: _phoneError,
                      onChanged: (_) {
                        if (_phoneError != null) {
                          _validateForm();
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    // Password input
                    _PMOInput(
                      label: 'Password',
                      hint: 'Masukkan password',
                      controller: _passwordController,
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: !_showPassword,
                      prefixIcon: Icons.lock,
                      suffixIcon: _showPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      onSuffixTap: () {
                        setState(() => _showPassword = !_showPassword);
                      },
                      error: _passwordError,
                      onChanged: (_) {
                        if (_passwordError != null) {
                          _validateForm();
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Fitur lupa password belum tersedia.',
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'Lupa Password?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Login button
                    PMOButton(
                      'Masuk',
                      onPressed: _isLoading ? null : _handleLogin,
                      isLoading: _isLoading,
                      width: double.infinity,
                    ),
                    const SizedBox(height: 20),
                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Container(height: 1, color: AppColors.border),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'atau',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMute,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(height: 1, color: AppColors.border),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Register button
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          context.go('/register');
                        },
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            children: [
                              TextSpan(
                                text: 'Belum punya akun? ',
                                style: TextStyle(color: AppColors.textMute),
                              ),
                              TextSpan(
                                text: 'Daftar Sekarang',
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
                    const SizedBox(height: 20),
                    // Security message
                    Center(
                      child: Text(
                        '🔒 Data kamu aman & terenkripsi',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMute,
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

class _PMOInput extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final String? error;
  final ValueChanged<String>? onChanged;

  const _PMOInput({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.error,
    this.onChanged,
  });

  @override
  State<_PMOInput> createState() => _PMOInputState();
}

class _PMOInputState extends State<_PMOInput> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
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
                color: widget.error != null
                    ? AppColors.danger
                    : const Color(0xFFD4ECE6),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.error != null
                    ? AppColors.danger
                    : const Color(0xFFD4ECE6),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.error != null
                    ? AppColors.danger
                    : AppColors.primary,
                width: 2,
              ),
            ),
            labelStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: widget.error != null
                  ? AppColors.danger
                  : AppColors.textMute,
            ),
            hintStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textMute.withValues(alpha: 0.5),
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: widget.error != null
                        ? AppColors.danger
                        : AppColors.primary,
                    size: 20,
                  )
                : null,
            suffixIcon: widget.suffixIcon != null
                ? GestureDetector(
                    onTap: widget.onSuffixTap,
                    child: Icon(
                      widget.suffixIcon,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  )
                : null,
          ),
        ),
        if (widget.error != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.error!,
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
