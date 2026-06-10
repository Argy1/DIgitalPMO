import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
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
  late TextEditingController _weightController;

  // Step 2 - TB Treatment
  DateTime? _treatmentStartDate;
  bool _confirmDate = false;
  bool _isPregnant = false;

  // Step 2 - klasifikasi TB baru
  String? _tbCategory; // "SO" | "RO"
  String? _tbSoType; // nilai TB SO type (mis. "TB Paru")
  bool _isEkstraParu = false; // toggle untuk menampilkan grid lokasi
  String? _tbRoType; // "MDR" | "XDR" | "RR"
  late TextEditingController _durationController;
  String? _medicationType; // "FDC" | "Kombinasi"
  String? _fdcType; // "FDC" | "Kombipak"
  final Map<String, bool> _customMeds = {
    'R': false,
    'H': false,
    'Z': false,
    'E': false,
  };

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
    _weightController = TextEditingController();
    _durationController = TextEditingController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _faskesController.dispose();
    _doctorController.dispose();
    _weightController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  double? get _weightKg {
    final raw = _weightController.text.trim().replaceAll(',', '.');
    return raw.isEmpty ? null : double.tryParse(raw);
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

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _validateStep2() {
    if (_treatmentStartDate == null || !_confirmDate) {
      _snack('Pilih tanggal mulai pengobatan dan konfirmasi');
      return false;
    }
    if (_tbCategory == null) {
      _snack('Pilih kategori TB (SO atau RO)');
      return false;
    }
    if (_tbCategory == 'SO' && (_tbSoType == null || _tbSoType!.isEmpty)) {
      _snack('Pilih sub-tipe TB SO');
      return false;
    }
    if (_tbCategory == 'RO' && (_tbRoType == null || _tbRoType!.isEmpty)) {
      _snack('Pilih sub-tipe TB RO (MDR/XDR/RR)');
      return false;
    }
    final duration = int.tryParse(_durationController.text.trim());
    if (duration == null || duration < 42) {
      _snack('Durasi pengobatan minimal 42 hari (6 minggu)');
      return false;
    }
    if (_medicationType == null) {
      _snack('Pilih jenis obat (FDC atau Kombinasi)');
      return false;
    }
    if (_medicationType == 'FDC' && _fdcType == null) {
      _snack('Pilih jenis FDC (FDC atau Kombipak)');
      return false;
    }
    if (_medicationType == 'Kombinasi' &&
        !_customMeds.values.any((selected) => selected)) {
      _snack('Pilih minimal 1 obat untuk Kombinasi');
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
      final customMeds = _medicationType == 'Kombinasi'
          ? _customMeds.entries
                .where((entry) => entry.value)
                .map((entry) => entry.key)
                .toList()
          : null;
      await ApiService.instance.setupPatientProfile(
        dateOfBirth:
            '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}',
        gender: _gender == 'L' ? 'laki-laki' : 'perempuan',
        faksesName: _faskesController.text.trim(),
        doctorName: _doctorController.text.trim(),
        tbCategory: _tbCategory ?? 'SO',
        tbSoType: _tbCategory == 'SO' ? _tbSoType : null,
        tbRoType: _tbCategory == 'RO' ? _tbRoType : null,
        treatmentStartDate:
            '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}',
        treatmentDurationDays: int.tryParse(_durationController.text.trim()),
        medicationType: _medicationType,
        fdcType: _medicationType == 'FDC' ? _fdcType : null,
        customMedications: customMeds,
        weightKg: _weightKg,
        isPregnant: _gender == 'P' ? _isPregnant : null,
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
                    weightController: _weightController,
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
                    gender: _gender,
                    isPregnant: _isPregnant,
                    onPregnantChanged: (value) =>
                        setState(() => _isPregnant = value ?? false),
                    weightKg: _weightKg,
                    tbCategory: _tbCategory,
                    onTBCategoryChanged: (value) => setState(() {
                      _tbCategory = value;
                      // reset sub-tipe saat kategori berubah
                      _tbSoType = null;
                      _tbRoType = null;
                      _isEkstraParu = false;
                      // Kombinasi hanya untuk SO; reset bila pindah ke RO
                      if (value == 'RO' && _medicationType == 'Kombinasi') {
                        _medicationType = null;
                      }
                    }),
                    tbSoType: _tbSoType,
                    isEkstraParu: _isEkstraParu,
                    onTBSoTypeChanged: (value, isEkstra) => setState(() {
                      _tbSoType = value;
                      _isEkstraParu = isEkstra;
                    }),
                    tbRoType: _tbRoType,
                    onTBRoTypeChanged: (value) =>
                        setState(() => _tbRoType = value),
                    durationController: _durationController,
                    onDurationChanged: () => setState(() {}),
                    medicationType: _medicationType,
                    onMedicationTypeChanged: (value) => setState(() {
                      _medicationType = value;
                      if (value != 'FDC') _fdcType = null;
                    }),
                    fdcType: _fdcType,
                    onFdcTypeChanged: (value) =>
                        setState(() => _fdcType = value),
                    customMeds: _customMeds,
                    onCustomMedToggled: (code) => setState(
                      () => _customMeds[code] = !(_customMeds[code] ?? false),
                    ),
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
                    medicationType: _medicationType,
                    fdcType: _fdcType,
                    customMeds: _customMeds,
                    durationDays: int.tryParse(_durationController.text.trim()),
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
  final TextEditingController weightController;
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
    required this.weightController,
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
          const SizedBox(height: 12),
          _FormField(
            label: 'Berat Badan (kg)',
            controller: weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: Icons.monitor_weight_outlined,
          ),
          const SizedBox(height: 6),
          Text(
            'Digunakan untuk menghitung jumlah tablet FDC',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textMute,
            ),
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
  final String gender;
  final bool isPregnant;
  final ValueChanged<bool?> onPregnantChanged;
  final double? weightKg;

  final String? tbCategory;
  final ValueChanged<String?> onTBCategoryChanged;
  final String? tbSoType;
  final bool isEkstraParu;
  final void Function(String? value, bool isEkstra) onTBSoTypeChanged;
  final String? tbRoType;
  final ValueChanged<String?> onTBRoTypeChanged;
  final TextEditingController durationController;
  final VoidCallback onDurationChanged;
  final String? medicationType;
  final ValueChanged<String?> onMedicationTypeChanged;
  final String? fdcType;
  final ValueChanged<String?> onFdcTypeChanged;
  final Map<String, bool> customMeds;
  final ValueChanged<String> onCustomMedToggled;
  final VoidCallback onNext;

  const _Step2TBTreatment({
    required this.treatmentStartDate,
    required this.onSelectDate,
    required this.confirmDate,
    required this.onConfirmChanged,
    required this.gender,
    required this.isPregnant,
    required this.onPregnantChanged,
    required this.weightKg,
    required this.tbCategory,
    required this.onTBCategoryChanged,
    required this.tbSoType,
    required this.isEkstraParu,
    required this.onTBSoTypeChanged,
    required this.tbRoType,
    required this.onTBRoTypeChanged,
    required this.durationController,
    required this.onDurationChanged,
    required this.medicationType,
    required this.onMedicationTypeChanged,
    required this.fdcType,
    required this.onFdcTypeChanged,
    required this.customMeds,
    required this.onCustomMedToggled,
    required this.onNext,
  });

  static const _ekstraParuLocations = [
    'TB Ekstra Paru - Otak',
    'TB Ekstra Paru - Tulang',
    'TB Ekstra Paru - Kulit',
    'TB Ekstra Paru - Kelenjar',
    'TB Ekstra Paru - Pleura',
    'TB Ekstra Paru - Abdominal',
    'TB Ekstra Paru - Milier',
  ];

  int get _fdcTabletCount {
    final w = weightKg ?? 0;
    if (w <= 0) return 0;
    if (w < 38) return 2;
    if (w < 55) return 3;
    if (w <= 70) return 4;
    return 5;
  }

  String _durationConversion(String raw) {
    final days = int.tryParse(raw.trim());
    if (days == null || days <= 0) return '';
    final months = days ~/ 30;
    final weeks = (days % 30) ~/ 7;
    final parts = <String>[];
    if (months > 0) parts.add('$months bulan');
    if (weeks > 0) parts.add('$weeks minggu');
    if (parts.isEmpty) return '≈ $days hari';
    return '≈ ${parts.join(' ')}';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
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
          if (treatmentStartDate != null) ...[
            const SizedBox(height: 12),
            Text(
              'Mulai: ${_formatDate(treatmentStartDate!)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMute,
              ),
            ),
            const SizedBox(height: 12),
            _CheckboxField(
              value: confirmDate,
              onChanged: onConfirmChanged,
              label: 'Saya konfirmasi tanggal ini benar',
            ),
          ],
          const SizedBox(height: 24),

          // Step 2A: Kategori TB
          _SectionLabel('Kategori TB'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CategoryCard(
                  emoji: '💊',
                  title: 'SO',
                  subtitle: 'TB yang masih merespons OAT lini pertama',
                  accent: AppColors.primary,
                  isSelected: tbCategory == 'SO',
                  onTap: () => onTBCategoryChanged('SO'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CategoryCard(
                  emoji: '⚠️',
                  title: 'RO',
                  subtitle: 'TB yang resisten terhadap satu atau lebih OAT',
                  accent: AppColors.amber,
                  isSelected: tbCategory == 'RO',
                  onTap: () => onTBCategoryChanged('RO'),
                ),
              ),
            ],
          ),

          // Step 2B: Sub-tipe
          if (tbCategory == 'SO') ...[
            const SizedBox(height: 24),
            _SectionLabel('Lokasi TB'),
            const SizedBox(height: 12),
            _RadioOption(
              label: 'TB Paru',
              value: 'TB Paru',
              groupValue: (!isEkstraParu ? tbSoType : null) ?? '',
              onChanged: (_) => onTBSoTypeChanged('TB Paru', false),
            ),
            const SizedBox(height: 8),
            _RadioOption(
              label: 'TB Ekstra Paru',
              value: 'ekstra',
              groupValue: isEkstraParu ? 'ekstra' : '',
              onChanged: (_) => onTBSoTypeChanged(null, true),
            ),
            if (isEkstraParu) ...[
              const SizedBox(height: 12),
              Text(
                'Pilih lokasi:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMute,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _ekstraParuLocations.map((loc) {
                  final label = loc.replaceFirst('TB Ekstra Paru - ', '');
                  return _ChoiceChip(
                    label: label,
                    isSelected: tbSoType == loc,
                    onTap: () => onTBSoTypeChanged(loc, true),
                  );
                }).toList(),
              ),
            ],
          ],
          if (tbCategory == 'RO') ...[
            const SizedBox(height: 24),
            _SectionLabel('Tipe Resistensi'),
            const SizedBox(height: 12),
            Row(
              children: ['MDR', 'XDR', 'RR'].map((type) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: type != 'RR' ? 8 : 0),
                    child: _ChoiceChip(
                      label: type,
                      isSelected: tbRoType == type,
                      onTap: () => onTBRoTypeChanged(type),
                      fullWidth: true,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // Step 2C: Durasi
          if (tbCategory != null) ...[
            const SizedBox(height: 24),
            _SectionLabel('Durasi Pengobatan (Hari)'),
            const SizedBox(height: 8),
            TextField(
              controller: durationController,
              keyboardType: TextInputType.number,
              onChanged: (_) => onDurationChanged(),
              decoration: InputDecoration(
                hintText: 'Contoh: 180 untuk 6 bulan, 270 untuk 9 bulan',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMute,
                ),
                prefixIcon: Icon(Icons.timelapse, color: AppColors.primary),
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
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Diisi sesuai protokol dokter',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMute,
                    ),
                  ),
                ),
                Text(
                  _durationConversion(durationController.text),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],

          // Step 2D: Jenis Obat
          if (tbCategory != null) ...[
            const SizedBox(height: 24),
            _SectionLabel('Jenis Obat'),
            const SizedBox(height: 12),
            _MedicationCard(
              title: 'FDC',
              subtitle: 'Tablet kombinasi dosis tetap',
              isSelected: medicationType == 'FDC',
              onTap: () => onMedicationTypeChanged('FDC'),
            ),
            if (medicationType == 'FDC') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ChoiceChip(
                      label: 'FDC',
                      isSelected: fdcType == 'FDC',
                      onTap: () => onFdcTypeChanged('FDC'),
                      fullWidth: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ChoiceChip(
                      label: 'Kombipak',
                      isSelected: fdcType == 'Kombipak',
                      onTap: () => onFdcTypeChanged('Kombipak'),
                      fullWidth: true,
                    ),
                  ),
                ],
              ),
            ],
            if (tbCategory == 'SO') ...[
              const SizedBox(height: 12),
              _MedicationCard(
                title: 'Kombinasi/Khusus',
                subtitle: 'Pilih obat secara manual',
                isSelected: medicationType == 'Kombinasi',
                onTap: () => onMedicationTypeChanged('Kombinasi'),
              ),
              if (medicationType == 'Kombinasi') ...[
                const SizedBox(height: 12),
                Text(
                  'Pilih obat (minimal 1):',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMute,
                  ),
                ),
                const SizedBox(height: 8),
                ...['R', 'H', 'Z', 'E'].map((code) {
                  return _MedCheckbox(
                    code: code,
                    name: AppColors.getMedName(code),
                    value: customMeds[code] ?? false,
                    onChanged: () => onCustomMedToggled(code),
                  );
                }),
              ],
            ],
            // Info box FDC berdasarkan berat badan
            if (medicationType == 'FDC' && _fdcTabletCount > 0) ...[
              const SizedBox(height: 16),
              PMOCard(
                backgroundColor: AppColors.tealSoft,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 Berdasarkan berat badan ${weightKg!.toStringAsFixed(0)} kg:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Fase Intensif: $_fdcTabletCount tablet 4FDC/hari',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.6,
                      ),
                    ),
                    Text(
                      '• Fase Lanjutan: $_fdcTabletCount tablet 2FDC (3x seminggu)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

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
}

class _Step3MedicationSchedule extends StatelessWidget {
  final DateTime? treatmentStartDate;
  final TimeOfDay medicationTime;
  final VoidCallback onSelectTime;
  final Map<String, bool> reminders;
  final Function(String, bool) onReminderChanged;
  final VoidCallback onFinish;
  final bool isLoading;
  final String? medicationType;
  final String? fdcType;
  final Map<String, bool> customMeds;
  final int? durationDays;

  const _Step3MedicationSchedule({
    required this.treatmentStartDate,
    required this.medicationTime,
    required this.onSelectTime,
    required this.reminders,
    required this.onReminderChanged,
    required this.onFinish,
    this.isLoading = false,
    this.medicationType,
    this.fdcType,
    this.customMeds = const {},
    this.durationDays,
  });

  String get _medLabel {
    if (medicationType == 'FDC') return fdcType ?? 'FDC';
    if (medicationType == 'Kombinasi') {
      final selected = customMeds.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();
      return selected.isEmpty ? 'Kombinasi' : selected.join(' + ');
    }
    return 'RHZE';
  }

  String get _phaseLabel {
    final days = durationDays ?? 180;
    final intensiveDays = days <= 180 ? 56 : 84; // 2 bln SO, 3 bln RO
    final continuationDays = days - intensiveDays;
    return 'Intensif ${intensiveDays ~/ 30} bln → Lanjutan ${continuationDays ~/ 30} bln';
  }

  String get _estimasiSelesai {
    final start = treatmentStartDate ?? DateTime.now();
    final days = durationDays ?? 180;
    final end = start.add(Duration(days: days));
    const bulan = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    return '${end.day} ${bulan[end.month - 1]} ${end.year}';
  }

  @override
  Widget build(BuildContext context) {
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

          // Ringkasan pengobatan
          PMOCard(
            backgroundColor: AppColors.tealSoft,
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.medication_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Ringkasan Pengobatan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoRow(label: 'Jenis Obat', value: _medLabel),
                const SizedBox(height: 6),
                _InfoRow(label: 'Durasi', value: '${durationDays ?? 180} hari'),
                const SizedBox(height: 6),
                _InfoRow(label: 'Fase', value: _phaseLabel),
                const SizedBox(height: 6),
                _InfoRow(label: 'Estimasi Selesai', value: _estimasiSelesai),
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
  final TextInputType? keyboardType;

  const _FormField({
    required this.label,
    required this.controller,
    this.prefixIcon,
    this.minLines = 1,
    this.maxLines = 1,
    this.keyboardType,
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
          keyboardType: keyboardType,
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

// ── Step 2 helper widgets ─────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color accent;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? accent : const Color(0xFFD4ECE6),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? accent.withValues(alpha: 0.06) : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isSelected ? accent : AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textMute,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool fullWidth;

  const _ChoiceChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFD4ECE6),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.white,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.primary : AppColors.text,
          ),
        ),
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _MedicationCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
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
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFFD4ECE6),
                  width: 2,
                ),
              ),
              child: isSelected
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.primary : AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMute,
                    ),
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

class _MedCheckbox extends StatelessWidget {
  final String code;
  final String name;
  final bool value;
  final VoidCallback onChanged;

  const _MedCheckbox({
    required this.code,
    required this.name,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final medColor = AppColors.getMedColor(code);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onChanged,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: value ? AppColors.primary : const Color(0xFFD4ECE6),
              width: value ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
            color: value
                ? AppColors.primary.withValues(alpha: 0.04)
                : Colors.white,
          ),
          child: Row(
            children: [
              Container(
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
              const SizedBox(width: 12),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: medColor.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Text(
                    code,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: medColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textMute,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        ),
      ],
    );
  }
}
