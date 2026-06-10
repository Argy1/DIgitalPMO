import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pmo_button.dart';
import '../../../core/widgets/pmo_card.dart';

class PMOLinkApprovalScreen extends StatefulWidget {
  final String linkRequestId;
  final String pmoName;

  const PMOLinkApprovalScreen({
    super.key,
    required this.linkRequestId,
    required this.pmoName,
  });

  @override
  State<PMOLinkApprovalScreen> createState() => _PMOLinkApprovalScreenState();
}

class _PMOLinkApprovalScreenState extends State<PMOLinkApprovalScreen> {
  bool _isApproving = false;
  bool _isRejecting = false;

  Future<void> _approve() async {
    setState(() => _isApproving = true);
    try {
      await ApiService.instance.approvePMOLink(widget.linkRequestId);
      if (!mounted) return;
      _showResult(
        success: true,
        message: 'Berhasil terhubung dengan PMO ${widget.pmoName}.',
      );
    } catch (e) {
      if (!mounted) return;
      _showResult(success: false, message: apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isApproving = false);
    }
  }

  Future<void> _reject() async {
    setState(() => _isRejecting = true);
    try {
      await ApiService.instance.rejectPMOLink(widget.linkRequestId);
      if (!mounted) return;
      _showResult(
        success: true,
        message: 'Permintaan pengawasan berhasil ditolak.',
        isReject: true,
      );
    } catch (e) {
      if (!mounted) return;
      _showResult(success: false, message: apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isRejecting = false);
    }
  }

  void _showResult({
    required bool success,
    required String message,
    bool isReject = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (success
                        ? (isReject ? AppColors.amber : AppColors.success)
                        : AppColors.danger)
                    .withValues(alpha: 0.12),
              ),
              child: Icon(
                success
                    ? (isReject ? Icons.block : Icons.check_circle)
                    : Icons.error_outline,
                size: 36,
                color: success
                    ? (isReject ? AppColors.amber : AppColors.success)
                    : AppColors.danger,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              success
                  ? (isReject ? 'Ditolak' : 'Berhasil!')
                  : 'Gagal',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMute,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/home/dashboard');
                },
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Permintaan Pengawasan',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.supervisor_account_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.pmoName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'ingin mengawasi pengobatan Anda',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textMute,
                ),
              ),
              const SizedBox(height: 32),
              PMOCard(
                backgroundColor: AppColors.tealSoft,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Apa artinya ini?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.visibility,
                      text:
                          'PMO dapat memantau jadwal dan kepatuhan minum obat Anda.',
                    ),
                    const SizedBox(height: 6),
                    _InfoRow(
                      icon: Icons.notifications_active_outlined,
                      text:
                          'PMO akan mendapat notifikasi jika Anda melewatkan obat.',
                    ),
                    const SizedBox(height: 6),
                    _InfoRow(
                      icon: Icons.lock_outline,
                      text: 'Anda bisa memutus hubungan kapan saja dari Setelan.',
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: PMOButton(
                      'Tolak',
                      icon: Icons.close,
                      variant: ButtonVariant.ghost,
                      isLoading: _isRejecting,
                      onPressed: (_isApproving || _isRejecting) ? null : _reject,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PMOButton(
                      'Setujui',
                      icon: Icons.check,
                      isLoading: _isApproving,
                      onPressed: (_isApproving || _isRejecting) ? null : _approve,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.text,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
