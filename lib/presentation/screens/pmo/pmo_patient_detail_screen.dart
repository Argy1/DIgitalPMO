import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pmo_card.dart';

class PMOPatientDetailScreen extends StatefulWidget {
  final String patientId;

  const PMOPatientDetailScreen({super.key, required this.patientId});

  @override
  State<PMOPatientDetailScreen> createState() => _PMOPatientDetailScreenState();
}

class _PMOPatientDetailScreenState extends State<PMOPatientDetailScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService.instance.getPMOPatientDetail(
        widget.patientId,
      );
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = apiErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  void _showUnlinkDialog() {
    final patient = _data?['patient'] as Map<String, dynamic>?;
    final name = patient?['full_name'] as String? ?? 'pasien ini';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Putus Hubungan?'),
        content: Text('Anda tidak akan lagi bisa memantau $name.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.instance.unlinkPMOPatient(widget.patientId);
                if (mounted) context.pop();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(apiErrorMessage(e))),
                  );
                }
              }
            },
            child: const Text(
              'Putus',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patient = _data?['patient'] as Map<String, dynamic>?;
    final logs = (_data?['medication_logs_7d'] as List<dynamic>?) ?? [];
    final risk = _data?['risk'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          patient?['full_name'] as String? ?? 'Detail Pasien',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_data != null)
            IconButton(
              icon: const Icon(Icons.link_off),
              tooltip: 'Putus hubungan',
              onPressed: _showUnlinkDialog,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        style: TextStyle(color: AppColors.textMute),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    PMOCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _row('TB', _tbDisplay(patient)),
                          _row('Fase', patient?['current_phase'] as String?),
                          _row('Faskes', patient?['faskes_name'] as String?),
                          _row('Dokter', patient?['doctor_name'] as String?),
                          _row(
                            'Jenis obat',
                            patient?['medication_type'] as String?,
                          ),
                          _row(
                            'Risiko',
                            risk?['level'] as String?,
                          ),
                          _row(
                            'Kepatuhan 30 hari',
                            '${(_data?['adherence_30d'] as num?)?.toStringAsFixed(0) ?? "-"}%',
                          ),
                          _row(
                            'Streak',
                            '${_data?['current_streak'] ?? 0} hari',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Riwayat 7 Hari',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (logs.isEmpty)
                      Text(
                        'Belum ada riwayat minum obat.',
                        style: TextStyle(color: AppColors.textMute),
                      )
                    else
                      ...logs.map((log) {
                        final l = log as Map<String, dynamic>;
                        return _LogTile(
                          status: l['status'] as String? ?? 'pending',
                          scheduledTime: l['scheduled_time'] as String? ?? '',
                        );
                      }),
                  ],
                ),
    );
  }

  String? _tbDisplay(Map<String, dynamic>? p) {
    if (p == null) return null;
    final cat = p['tb_category'] as String?;
    if (cat == 'SO') return 'SO - ${p['tb_so_type'] ?? "-"}';
    if (cat == 'RO') return 'RO - ${p['tb_ro_type'] ?? "-"}';
    return cat;
  }

  Widget _row(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textMute,
            ),
          ),
          Text(
            value ?? '-',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final String status;
  final String scheduledTime;

  const _LogTile({required this.status, required this.scheduledTime});

  Color get _color {
    switch (status) {
      case 'confirmed':
        return AppColors.success;
      case 'skipped':
      case 'late':
        return AppColors.amber;
      default:
        return AppColors.textMute;
    }
  }

  String get _label {
    switch (status) {
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'skipped':
        return 'Dilewati';
      case 'late':
        return 'Terlambat';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(scheduledTime);
    final dateStr = date != null
        ? '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
        : scheduledTime;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              dateStr,
              style: TextStyle(fontSize: 12, color: AppColors.text),
            ),
          ),
          Text(
            _label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}
