import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/tb_calculator.dart';
import '../../../core/widgets/pmo_button.dart';
import '../../../core/widgets/pmo_card.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String phoneNumber;
  final String fullName;

  const ProfileSetupScreen({
    super.key,
    required this.phoneNumber,
    required this.fullName,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  late PageController _pageController;
  int _currentStep = 0;

  // Step 1 - Personal Data
  late TextEditingController _nameController;
  DateTime? _dateOfBirth;
  String _gender = 'L';
  late TextEditingController _addressController;
  late TextEditingController _faskesController;
  late TextEditingController _doctorController;

  // Step 2 - TB Treatment
  DateTime? _treatmentStartDate;
  bool _confirmDate = false;
  String _tbType = 'paru';
  bool _isPregnant = false;

  // Step 3 - Medication Schedule
  TimeOfDay _medicationTime = const TimeOfDay(hour: 7, minute: 0);
  final Map<String, bool> _reminders = {
    'before': true,
    'onTime': true,
    'after': true,
  };

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _nameController = TextEditingController(text: widget.fullName);
    _addressController = TextEditingController();
    _faskesController = TextEditingController();
    _doctorController = TextEditingController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _faskesController.dispose();
    _doctorController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isDateOfBirth) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDateOfBirth ? DateTime(2000) : DateTime.now(),
      firstDate: isDateOfBirth ? DateTime(1950) : DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isDateOfBirth) {
          _dateOfBirth = picked;
        } else {
          _treatmentStartDate = picked;
          _confirmDate = false;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _medicationTime,
    );
    if (picked != null) {
      setState(() => _medicationTime = picked);
    }
  }

  bool _validateStep1() {
    if (_nameController.text.isEmpty || _dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan tanggal lahir harus diisi')),
      );
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (_treatmentStartDate == null || !_confirmDate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal dan konfirmasi')),
      );
      return false;
    }
    return true;
  }

  Future<void> _finishSetup() async {
    if (_dateOfBirth == null || _treatmentStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi tanggal lahir dan tanggal mulai pengobatan'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final dob = _dateOfBirth!;
      final start = _treatmentStartDate!;
      await ApiService.instance.setupPatientProfile(
        dateOfBirth:
            '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}',
        gender: _gender == 'L' ? 'laki-laki' : 'perempuan',
        faksesName: _faskesController.text.trim(),
        doctorName: _doctorController.text.trim(),
        tbType: _tbType == 'paru' ? 'TB Paru' : 'TB Ekstra Paru',
        treatmentStartDate:
            '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}',
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
      );
      if (mounted) context.go('/home/dashboard');
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step Indicator
            _StepIndicator(
              currentStep: _currentStep,
              stepLabels: ['Data Diri', 'Pengobatan TB', 'Jadwal Obat'],
            ),
            const SizedBox(height: 24),
            // PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentStep = index);
                },
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Step1PersonalData(
                    nameController: _nameController,
                    dateOfBirth: _dateOfBirth,
                    onSelectDate: () => _selectDate(context, true),
                    gender: _gender,
                    onGenderChanged: (value) =>
                        setState(() => _gender = value ?? 'L'),
                    addressController: _addressController,
                    faskesController: _faskesController,
                    doctorController: _doctorController,
                    onNext: () {
                      if (_validateStep1()) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                  _Step2TBTreatment(
                    treatmentStartDate: _treatmentStartDate,
                    onSelectDate: () => _selectDate(context, false),
                    confirmDate: _confirmDate,
                    onConfirmChanged: (value) =>
                        setState(() => _confirmDate = value ?? false),
                    tbType: _tbType,
                    onTBTypeChanged: (value) =>
                        setState(() => _tbType = value ?? 'paru'),
                    isPregnant: _isPregnant,
                    gender: _gender,
                    onPregnantChanged: (value) =>
                        setState(() => _isPregnant = value ?? false),
                    onNext: () {
                      if (_validateStep2()) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                  _Step3MedicationSchedule(
                    treatmentStartDate: _treatmentStartDate,
                    medicationTime: _medicationTime,
                    onSelectTime: () => _selectTime(context),
                    reminders: _reminders,
                    onReminderChanged: (key, value) {
                      setState(() => _reminders[key] = value);
                    },
                    onFinish: _finishSetup,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> stepLabels;

  const _StepIndicator({required this.currentStep, required this.stepLabels});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: List.generate(stepLabels.length, (index) {
              return Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 2,
                            color: index < currentStep
                                ? AppColors.primary
                                : const Color(0xFFD4ECE6),
                          ),
                        ),
                        if (index < stepLabels.length - 1)
                          Expanded(
                            child: Container(
                              height: 2,
                              color: index < currentStep - 1
                                  ? AppColors.primary
                                  : const Color(0xFFD4ECE6),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index <= currentStep
                            ? AppColors.primary
                            : Colors.white,
                        border: Border.all(
                          color: index <= currentStep
                              ? AppColors.primary
                              : const Color(0xFFD4ECE6),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: index < currentStep
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: index <= currentStep
                                      ? Colors.white
                                      : AppColors.textMute,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: stepLabels
                .asMap()
                .entries
                .map(
                  (entry) => Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: entry.key <= currentStep
                          ? AppColors.primary
                          : AppColors.textMute,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _Step1PersonalData extends StatelessWidget {
  final TextEditingController nameController;
  final DateTime? dateOfBirth;
  final VoidCallback onSelectDate;
  final String gender;
  final ValueChanged<String?> onGenderChanged;
  final TextEditingController addressController;
  final TextEditingController faskesController;
  final TextEditingController doctorController;
  final VoidCallback onNext;

  const _Step1PersonalData({
    required this.nameController,
    required this.dateOfBirth,
    required this.onSelectDate,
    required this.gender,
    required this.onGenderChanged,
    required this.addressController,
    required this.faskesController,
    required this.doctorController,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Lengkapi Data Diri Kamu',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          _FormField(
            label: 'Nama Lengkap',
            controller: nameController,
            prefixIcon: Icons.person,
          ),
          const SizedBox(height: 12),
          _DateField(
            label: 'Tanggal Lahir',
            value: dateOfBirth,
            onTap: onSelectDate,
            prefixIcon: Icons.calendar_today,
          ),
          const SizedBox(height: 12),
          Text(
            'Jenis Kelamin',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textMute,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _GenderCard(
                  label: 'Laki-laki',
                  icon: Icons.male,
                  value: 'L',
                  groupValue: gender,
                  onChanged: onGenderChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GenderCard(
                  label: 'Perempuan',
                  icon: Icons.female,
                  value: 'P',
                  groupValue: gender,
                  onChanged: onGenderChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FormField(
            label: 'Alamat (Opsional)',
            controller: addressController,
            minLines: 3,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          _FormField(
            label: 'Nama Faskes (Opsional)',
            controller: faskesController,
          ),
          const SizedBox(height: 12),
          _FormField(
            label: 'Nama Dokter (Opsional)',
            controller: doctorController,
          ),
          const SizedBox(height: 32),
          PMOButton('Lanjut →', onPressed: onNext, width: double.infinity),
        ],
      ),
    );
  }
}

class _Step2TBTreatment extends StatelessWidget {
  final DateTime? treatmentStartDate;
  final VoidCallback onSelectDate;
  final bool confirmDate;
  final ValueChanged<bool?> onConfirmChanged;
  final String tbType;
  final ValueChanged<String?> onTBTypeChanged;
  final bool isPregnant;
  final String gender;
  final ValueChanged<bool?> onPregnantChanged;
  final VoidCallback onNext;

  const _Step2TBTreatment({
    required this.treatmentStartDate,
    required this.onSelectDate,
    required this.confirmDate,
    required this.onConfirmChanged,
    required this.tbType,
    required this.onTBTypeChanged,
    required this.isPregnant,
    required this.gender,
    required this.onPregnantChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final currentPhase = treatmentStartDate != null
        ? TBCalculator.getCurrentPhase(
            TBCalculator.getDayNumber(treatmentStartDate!, DateTime.now()),
          )
        : null;
    final estimatedEnd = treatmentStartDate != null
        ? TBCalculator.getCompletionDate(treatmentStartDate!)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Data Pengobatan TB',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          _DateField(
            label: 'Tanggal Mulai Pengobatan',
            value: treatmentStartDate,
            onTap: onSelectDate,
            prefixIcon: Icons.calendar_today,
          ),
          const SizedBox(height: 20),
          // Warning card
          PMOCard(
            backgroundColor: const Color(0xFFFEF3E2),
            border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber, color: AppColors.amber, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Tanggal Sangat Penting!',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFA66A00),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tanggal ini menentukan seluruh jadwal obat kamu selama 180 hari. Jika salah, hubungi doktermu segera.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFA66A00),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (treatmentStartDate != null) ...[
            const SizedBox(height: 20),
            PMOCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Berdasarkan tanggal tersebut:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMute,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: 'Fase Saat Ini',
                    value: currentPhase == 'intensive'
                        ? 'Intensif (2 bulan)'
                        : 'Lanjutan (4 bulan)',
                  ),
                  _InfoRow(
                    label: 'Hari Ke',
                    value:
                        '${TBCalculator.getDayNumber(treatmentStartDate!, DateTime.now())} dari 180',
                  ),
                  _InfoRow(
                    label: 'Estimasi Selesai',
                    value: estimatedEnd != null
                        ? _formatDate(estimatedEnd)
                        : '-',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _CheckboxField(
              value: confirmDate,
              onChanged: onConfirmChanged,
              label: 'Saya konfirmasi tanggal ini benar',
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'Tipe TB',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textMute,
            ),
          ),
          const SizedBox(height: 8),
          _RadioOption(
            label: 'TB Paru',
            value: 'paru',
            groupValue: tbType,
            onChanged: onTBTypeChanged,
          ),
          const SizedBox(height: 8),
          _RadioOption(
            label: 'TB Ekstra Paru',
            value: 'ekstraparu',
            groupValue: tbType,
            onChanged: onTBTypeChanged,
          ),
          if (gender == 'P') ...[
            const SizedBox(height: 20),
            _CheckboxField(
              value: isPregnant,
              onChanged: onPregnantChanged,
              label: 'Saya sedang hamil atau menyusui',
            ),
          ],
          const SizedBox(height: 32),
          PMOButton('Lanjut →', onPressed: onNext, width: double.infinity),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _Step3MedicationSchedule extends StatelessWidget {
  final DateTime? treatmentStartDate;
  final TimeOfDay medicationTime;
  final VoidCallback onSelectTime;
  final Map<String, bool> reminders;
  final Function(String, bool) onReminderChanged;
  final VoidCallback onFinish;
  final bool isLoading;

  const _Step3MedicationSchedule({
    required this.treatmentStartDate,
    required this.medicationTime,
    required this.onSelectTime,
    required this.reminders,
    required this.onReminderChanged,
    required this.onFinish,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final startDate = treatmentStartDate ?? DateTime.now();
    final dayNumber = TBCalculator.getDayNumber(startDate, DateTime.now());
    final currentPhase = TBCalculator.getCurrentPhase(dayNumber);
    final medications = TBCalculator.getMedicationsForPhase(currentPhase);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Jadwal Pengobatan Kamu',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          PMOCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Obat-obatan:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMute,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: medications
                      .map(
                        (med) => Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Chip(
                            label: Text(med),
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.1,
                            ),
                            labelStyle: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sesuai protokol TB Indonesia',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMute,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Jam Minum Obat',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onSelectTime,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD4ECE6)),
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFF8FAF9),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${medicationTime.hour.toString().padLeft(2, '0')}:${medicationTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  Icon(Icons.schedule, color: AppColors.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Disarankan diminum saat perut kosong',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textMute,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Notifikasi Pengingat',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Kamu akan diingatkan pada:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMute,
            ),
          ),
          const SizedBox(height: 12),
          _ReminderToggle(
            label:
                '${medicationTime.hour.toString().padLeft(2, '0')}:${medicationTime.minute.toString().padLeft(2, '0')} - 15 menit sebelumnya',
            value: reminders['before'] ?? true,
            onChanged: (v) => onReminderChanged('before', v),
          ),
          const SizedBox(height: 8),
          _ReminderToggle(
            label:
                '${medicationTime.hour.toString().padLeft(2, '0')}:${medicationTime.minute.toString().padLeft(2, '0')} Tepat waktu',
            value: reminders['onTime'] ?? true,
            onChanged: (v) => onReminderChanged('onTime', v),
          ),
          const SizedBox(height: 8),
          _ReminderToggle(
            label:
                '${(medicationTime.hour).toString().padLeft(2, '0')}:${(medicationTime.minute + 30) % 60 > medicationTime.minute ? (medicationTime.minute + 30).toString().padLeft(2, '0') : ((medicationTime.minute + 30) - 60).toString().padLeft(2, '0')} Jika belum konfirmasi',
            value: reminders['after'] ?? true,
            onChanged: (v) => onReminderChanged('after', v),
          ),
          const SizedBox(height: 32),
          PMOButton(
            'Mulai Pengobatanku 🌱',
            onPressed: isLoading ? null : onFinish,
            isLoading: isLoading,
            width: double.infinity,
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData? prefixIcon;
  final int minLines;
  final int maxLines;

  const _FormField({
    required this.label,
    required this.controller,
    this.prefixIcon,
    this.minLines = 1,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textMute,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: label,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.primary)
                : null,
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
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final IconData prefixIcon;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.prefixIcon,
  });

  String _formatDate(DateTime date) {
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textMute,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD4ECE6)),
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFF8FAF9),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value != null ? _formatDate(value!) : 'Pilih tanggal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: value != null ? Colors.black87 : AppColors.textMute,
                  ),
                ),
                Icon(prefixIcon, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GenderCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _GenderCard({
    required this.label,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFD4ECE6),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.white,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textMute,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckboxField extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;

  const _CheckboxField({
    required this.value,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => onChanged(!value),
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
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class _RadioOption extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _RadioOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: value == groupValue
                ? AppColors.primary
                : const Color(0xFFD4ECE6),
            width: value == groupValue ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: value == groupValue
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: value == groupValue
                      ? AppColors.primary
                      : const Color(0xFFD4ECE6),
                  width: 2,
                ),
              ),
              child: value == groupValue
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: value == groupValue ? AppColors.primary : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
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
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ReminderToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
        ),
      ],
    );
  }
}
