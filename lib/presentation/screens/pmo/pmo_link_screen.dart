import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pmo_button.dart';
import '../../../core/widgets/pmo_card.dart';

class PMOLinkScreen extends StatefulWidget {
  const PMOLinkScreen({super.key});

  @override
  State<PMOLinkScreen> createState() => _PMOLinkScreenState();
}

class _PMOLinkScreenState extends State<PMOLinkScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          'Tambah Pasien',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Scan QR', icon: Icon(Icons.qr_code_2)),
            Tab(text: 'Nomor HP', icon: Icon(Icons.phone)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _QRTab(),
          _PhoneTab(),
        ],
      ),
    );
  }
}

// ── Tab 1: QR ─────────────────────────────────────────────────────────────────

class _QRTab extends StatefulWidget {
  const _QRTab();

  @override
  State<_QRTab> createState() => _QRTabState();
}

class _QRTabState extends State<_QRTab>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  String? _error;
  String? _qrToken;
  DateTime? _expiresAt;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService.instance.generatePMOQR();
      setState(() {
        _qrToken = data['qr_token'] as String?;
        final exp = data['expires_at'] as String?;
        _expiresAt = exp != null ? DateTime.tryParse(exp) : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = apiErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null || _qrToken == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: AppColors.textMute),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Gagal membuat QR',
              style: TextStyle(color: AppColors.textMute),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: _generate, child: const Text('Coba lagi')),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Minta pasien scan QR berikut dari aplikasi mereka',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 24),
          PMOCard(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: QrImageView(
                data: _qrToken!,
                version: QrVersions.auto,
                size: 240,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.primary,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.dark,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _expiresAt != null
                ? 'Berlaku sampai ${_formatTime(_expiresAt!)} (24 jam)'
                : 'Berlaku 24 jam',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textMute,
            ),
          ),
          const SizedBox(height: 24),
          PMOButton(
            'Refresh QR',
            icon: Icons.refresh,
            variant: ButtonVariant.ghost,
            onPressed: _generate,
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '${local.day}/${local.month} $h:$m';
  }
}

// ── Tab 2: Nomor HP ───────────────────────────────────────────────────────────

class _PhoneTab extends StatefulWidget {
  const _PhoneTab();

  @override
  State<_PhoneTab> createState() => _PhoneTabState();
}

class _PhoneTabState extends State<_PhoneTab>
    with AutomaticKeepAliveClientMixin {
  final _phoneController = TextEditingController();
  bool _isSending = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    final phone = normalizePhoneNumber(_phoneController.text);
    if (phone.length < 10 || phone.length > 13) {
      setState(() {
        _isSuccess = false;
        _statusMessage = 'Nomor HP harus 10-13 digit';
      });
      return;
    }
    setState(() {
      _isSending = true;
      _statusMessage = null;
    });
    try {
      final res = await ApiService.instance.requestPMOLink(phone);
      setState(() {
        _isSuccess = true;
        _statusMessage =
            res['message'] as String? ?? 'Permintaan berhasil dikirim.';
        _isSending = false;
      });
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _statusMessage = apiErrorMessage(e);
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Masukkan nomor HP pasien',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '+62 812-XXXX-XXXX',
              prefixIcon: Icon(Icons.phone, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD4ECE6)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD4ECE6)),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAF9),
            ),
          ),
          const SizedBox(height: 16),
          PMOButton(
            'Kirim Permintaan',
            icon: Icons.send,
            isLoading: _isSending,
            onPressed: _isSending ? null : _sendRequest,
            width: double.infinity,
          ),
          const SizedBox(height: 16),
          PMOCard(
            backgroundColor: AppColors.tealSoft,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pasien akan mendapat notifikasi untuk menyetujui permintaan pengawasan.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (_isSuccess ? AppColors.success : AppColors.danger)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _isSuccess ? Icons.check_circle : Icons.error_outline,
                    color: _isSuccess ? AppColors.success : AppColors.danger,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isSuccess
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
