import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_credential_service.dart';
import '../../../core/services/notification_service.dart';
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
  bool _isBiometricLoading = false;
  String? _phoneError;
  String? _passwordError;

  bool _biometricAvailable = false;
  bool _biometricLoginEnabled = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadInitialState());
  }

  Future<void> _loadInitialState() async {
    final creds = AuthCredentialService.instance;
    final canUse = await creds.canUseBiometrics();
    final enabled = await creds.isBiometricLoginEnabled();
    final savedPhone = await creds.loadSavedPhone();

    if (!mounted) return;
    setState(() {
      _biometricAvailable = canUse;
      _biometricLoginEnabled = enabled;
    });

    // Auto-fill phone number if we have it saved.
    if (savedPhone != null && _phoneController.text.isEmpty) {
      _phoneController.text = savedPhone;
    }

    // Auto-trigger biometric prompt if enabled and credentials are saved.
    if (canUse && enabled) {
      unawaited(_handleBiometricLogin());
    }
  }

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
      final role = user?['role'] as String? ?? 'patient';
      if (!mounted) return;

      unawaited(NotificationService.instance.requestPermissions());

      // Ask to enable biometric login if available and not yet set up.
      if (_biometricAvailable && !_biometricLoginEnabled) {
        unawaited(_promptSaveBiometric(
          phone: normalizePhoneNumber(_phoneController.text),
          password: _passwordController.text,
        ));
      } else if (_biometricLoginEnabled) {
        // Update saved credentials in case they changed.
        await AuthCredentialService.instance.saveCredentials(
          normalizePhoneNumber(_phoneController.text),
          _passwordController.text,
        );
      }

      _navigateAfterLogin(role: role, profile: profile, user: user);
    } catch (e) {
      if (mounted) {
        setState(() => _passwordError = apiErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleBiometricLogin() async {
    final creds = AuthCredentialService.instance;
    final saved = await creds.loadCredentials();
    if (saved == null) return;

    setState(() => _isBiometricLoading = true);
    try {
      final authenticated = await creds.authenticate(
        reason: 'Masuk ke DigitalPMO dengan sidik jari',
      );
      if (!authenticated || !mounted) {
        setState(() => _isBiometricLoading = false);
        return;
      }

      await ApiService.instance.login(
        phone: saved.phone,
        password: saved.password,
      );
      final profileData = await ApiService.instance.getMyProfile();
      final profile = profileData['patient_profile'] as Map<String, dynamic>?;
      final user = profileData['user'] as Map<String, dynamic>?;
      final role = user?['role'] as String? ?? 'patient';
      if (!mounted) return;

      unawaited(NotificationService.instance.requestPermissions());
      _navigateAfterLogin(role: role, profile: profile, user: user);
    } catch (e) {
      if (mounted) {
        // Show error but don't block manual login.
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Login biometrik gagal: ${apiErrorMessage(e)}'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } finally {
      if (mounted) setState(() => _isBiometricLoading = false);
    }
  }

  void _navigateAfterLogin({
    required String role,
    required Map<String, dynamic>? profile,
    required Map<String, dynamic>? user,
  }) {
    if (role == 'pmo') {
      context.go('/pmo/dashboard');
    } else if (role == 'doctor') {
      context.go('/home/dashboard');
    } else if (profile == null) {
      final phone = Uri.encodeComponent(
        normalizePhoneNumber(_phoneController.text),
      );
      final name = Uri.encodeComponent(user?['full_name'] as String? ?? '');
      context.go('/setup-profile/$phone/$name');
    } else {
      context.go('/home/dashboard');
    }
  }

  Future<void> _promptSaveBiometric({
    required String phone,
    required String password,
  }) async {
    if (!mounted) return;
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Aktifkan Login Biometrik?',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: const Text(
          'Masuk lebih cepat di lain waktu menggunakan sidik jari atau wajah, tanpa perlu mengetik password.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Nanti Saja'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Aktifkan'),
          ),
        ],
      ),
    );

    if (shouldSave == true) {
      await AuthCredentialService.instance.saveCredentials(phone, password);
      await AuthCredentialService.instance.setBiometricLoginEnabled(true);
      if (mounted) {
        setState(() => _biometricLoginEnabled = true);
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
          // ── Header ──────────────────────────────────────────────────────────
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

          // ── Form ────────────────────────────────────────────────────────────
          Expanded(
            child: Container(
              color: Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
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
                        if (_phoneError != null) _validateForm();
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
                      onSuffixTap: () =>
                          setState(() => _showPassword = !_showPassword),
                      error: _passwordError,
                      onChanged: (_) {
                        if (_passwordError != null) _validateForm();
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
                              content:
                                  Text('Fitur lupa password belum tersedia.'),
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

                    // ── Biometric login button ────────────────────────────────
                    if (_biometricAvailable && _biometricLoginEnabled) ...[
                      const SizedBox(height: 16),
                      _BiometricButton(
                        isLoading: _isBiometricLoading,
                        onTap: _isBiometricLoading || _isLoading
                            ? null
                            : _handleBiometricLogin,
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child:
                              Container(height: 1, color: AppColors.border),
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
                          child:
                              Container(height: 1, color: AppColors.border),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Register link
                    Center(
                      child: GestureDetector(
                        onTap: () => context.go('/register'),
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

// ── Biometric login button ────────────────────────────────────────────────────

class _BiometricButton extends StatelessWidget {
  const _BiometricButton({required this.isLoading, this.onTap});

  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.primary.withValues(alpha: 0.05),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              )
            else
              Icon(Icons.fingerprint, color: AppColors.primary, size: 26),
            const SizedBox(width: 10),
            Text(
              isLoading ? 'Memverifikasi...' : 'Masuk dengan Sidik Jari',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Text input widget ─────────────────────────────────────────────────────────

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
