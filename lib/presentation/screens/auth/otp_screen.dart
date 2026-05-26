import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pmo_button.dart';

class OTPScreen extends StatefulWidget {
  final String phoneNumber;
  final String fullName;
  final String? devOtp;

  const OTPScreen({
    super.key,
    required this.phoneNumber,
    required this.fullName,
    this.devOtp,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  late List<TextEditingController> _otpControllers;
  late List<FocusNode> _otpFocusNodes;
  late Timer _countdownTimer;
  int _secondsRemaining = 60;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _otpControllers = List.generate(6, (_) => TextEditingController());
    _otpFocusNodes = List.generate(6, (_) => FocusNode());
    final localOtp = widget.devOtp;
    if (localOtp != null && localOtp.length == 6) {
      for (var i = 0; i < 6; i++) {
        _otpControllers[i].text = localOtp[i];
      }
    }
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _countdownTimer.cancel();
        }
      });
    });
  }

  void _resendOTP() {
    setState(() {
      _secondsRemaining = 60;
      for (var controller in _otpControllers) {
        controller.clear();
      }
    });
    _otpFocusNodes[0].requestFocus();
    _startCountdown();
    // TODO: Call resend OTP API
  }

  Future<void> _verifyOTP() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Masukkan 6 digit OTP')));
      return;
    }

    setState(() => _isVerifying = true);

    try {
      await ApiService.instance.verifyOTP(phone: widget.phoneNumber, otp: otp);
      if (mounted) {
        final phone = Uri.encodeComponent(widget.phoneNumber);
        final name = Uri.encodeComponent(widget.fullName);
        context.go('/setup-profile/$phone/$name');
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
        setState(() => _isVerifying = false);
      }
    }
  }

  String _getMaskedPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 10) {
      final firstPart = digits.substring(0, 2);
      final lastPart = digits.substring(max(2, digits.length - 4));
      return '+$firstPart XXX-XXXX-$lastPart';
    }
    return phone;
  }

  void _handleOTPInput(String value, int index) {
    if (value.isNotEmpty) {
      if (value.length > 1) {
        // Paste multiple digits
        _otpControllers[index].text = value[0];
        for (int i = 1; i < value.length && index + i < 6; i++) {
          _otpControllers[index + i].text = value[i];
        }
        if (index + value.length - 1 < 6) {
          _otpFocusNodes[index + 1].requestFocus();
        } else {
          _otpFocusNodes[5].unfocus();
          _verifyOTP();
        }
      } else {
        if (index < 5) {
          _otpFocusNodes[index + 1].requestFocus();
        } else {
          _otpFocusNodes[index].unfocus();
          _verifyOTP();
        }
      }
    }
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // SMS Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.mail_outline,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              // Title
              const Text(
                'Masukkan Kode OTP',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              // Phone number
              Text(
                'Kode dikirim ke ${_getMaskedPhone(widget.phoneNumber)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMute,
                ),
              ),
              const SizedBox(height: 32),
              // OTP Input Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  6,
                  (index) => _OTPBox(
                    controller: _otpControllers[index],
                    focusNode: _otpFocusNodes[index],
                    onChanged: (value) => _handleOTPInput(value, index),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Countdown Timer
              if (_secondsRemaining > 0)
                Text(
                  'Kirim ulang dalam ${_formatTime(_secondsRemaining)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMute,
                  ),
                )
              else
                GestureDetector(
                  onTap: _resendOTP,
                  child: Text(
                    'Kirim Ulang',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              // Verify Button
              PMOButton(
                'Verifikasi ✓',
                onPressed: _isVerifying ? null : _verifyOTP,
                isLoading: _isVerifying,
                width: double.infinity,
              ),
              const SizedBox(height: 16),
              // Change Phone Number Link
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  'Ganti Nomor HP',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class _OTPBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OTPBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  State<_OTPBox> createState() => _OTPBoxState();
}

class _OTPBoxState extends State<_OTPBox> {
  late FocusNode _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _internalFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _internalFocusNode.hasFocus;

    return Container(
      width: 44,
      height: 56,
      decoration: BoxDecoration(
        border: Border.all(
          color: isFocused ? AppColors.primary : const Color(0xFFD4ECE6),
          width: isFocused ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _internalFocusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        onChanged: widget.onChanged,
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
          contentPadding: EdgeInsets.zero,
        ),
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }
}

int max(int a, int b) => a > b ? a : b;
