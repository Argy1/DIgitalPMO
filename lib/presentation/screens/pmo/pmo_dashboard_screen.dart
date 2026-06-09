import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pmo_card.dart';
import '../../../data/models/pmo_patient_model.dart';

class PMODashboardScreen extends StatefulWidget {
  const PMODashboardScreen({super.key});

  @override
  State<PMODashboardScreen> createState() => _PMODashboardScreenState();
}

class _PMODashboardScreenState extends State<PMODashboardScreen> {
  bool _isLoading = true;
  String? _error;
  int _totalPatients = 0;
  int _missedToday = 0;
  List<PMOPatientSummaryModel> _patients = [];

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
      final data = await ApiService.instance.getPMODashboard();
      final rawPatients = data['patients'] as List<dynamic>? ?? [];
      setState(() {
        _totalPatients = data['total_patients'] as int? ?? 0;
        _missedToday = data['missed_today'] as int? ?? 0;
        _patients = rawPatients
            .map(
              (e) => PMOPatientSummaryModel.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = apiErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  int get _confirmedToday => _patients
      .where((p) => p.todayMedicationStatus == 'confirmed')
      .length;

  int get _pendingToday =>
      _patients.where((p) => p.todayMedicationStatus == 'pending').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Dashboard PMO',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () async {
          await context.push('/pmo/link');
          if (mounted) _load();
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah Pasien'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.cloud_off, size: 48, color: AppColors.textMute),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _error!,
              style: TextStyle(color: AppColors.textMute),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(onPressed: _load, child: const Text('Coba lagi')),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SummaryHeader(
          total: _totalPatients,
          confirmed: _confirmedToday,
          pending: _pendingToday,
          missed: _missedToday,
        ),
        const SizedBox(height: 16),
        if (_patients.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Column(
              children: [
                Icon(
                  Icons.groups_outlined,
                  size: 56,
                  color: AppColors.textMute,
                ),
                const SizedBox(height: 12),
                Text(
                  'Belum ada pasien yang diawasi.\nTambahkan pasien lewat tombol di bawah.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMute),
                ),
              ],
            ),
          )
        else
          ..._patients.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PatientTile(
                patient: p,
                onTap: () => context.push('/pmo/patient/${p.patientId}'),
              ),
            ),
          ),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final int total;
  final int confirmed;
  final int pending;
  final int missed;

  const _SummaryHeader({
    required this.total,
    required this.confirmed,
    required this.pending,
    required this.missed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Hari Ini',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatCell(label: 'Total', value: total, color: Colors.white),
              _StatCell(
                label: 'Sudah',
                value: confirmed,
                color: const Color(0xFFB8F5D0),
              ),
              _StatCell(
                label: 'Belum',
                value: pending,
                color: const Color(0xFFFFE0A3),
              ),
              _StatCell(
                label: 'Terlewat',
                value: missed,
                color: const Color(0xFFFFB3AB),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientTile extends StatelessWidget {
  final PMOPatientSummaryModel patient;
  final VoidCallback onTap;

  const _PatientTile({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final initial = patient.patientName.isNotEmpty
        ? patient.patientName[0].toUpperCase()
        : '?';
    return PMOCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: patient.statusColor.withValues(alpha: 0.15),
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: patient.statusColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.patientName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${patient.tbTypeDisplay} • Hari ke-${patient.treatmentDay}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMute,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _Badge(
                      text: patient.statusLabel,
                      color: patient.statusColor,
                    ),
                    const SizedBox(width: 6),
                    _Badge(
                      text:
                          'Patuh ${patient.adherenceLast30Days.toStringAsFixed(0)}%',
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    _Badge(
                      text: 'Risiko ${patient.riskLevel}',
                      color: patient.riskColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textMute),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
