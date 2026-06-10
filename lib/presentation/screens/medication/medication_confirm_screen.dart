import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';

class MedicationConfirmScreen extends StatefulWidget {
  const MedicationConfirmScreen({super.key});

  @override
  State<MedicationConfirmScreen> createState() =>
      _MedicationConfirmScreenState();
}

class _MedicationConfirmScreenState extends State<MedicationConfirmScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _controller;
  late final AnimationController _scanController;

  bool _isInitialized = false;
  bool _isScanning = false;
  bool _cameraUnavailable = false;
  bool _permissionDenied = false;

  // Medication info loaded from backend
  String? _medicationType;   // "FDC" or "Kombinasi"
  String? _fdcType;
  int? _tabletCount;
  int _frequencyPerWeek = 7;
  List<String> _customMeds = [];
  String _phase = 'intensive';
  List<String> _meds = ['R', 'H', 'Z', 'E'];

  static const _tips = [
    'Cahaya cukup',
    'Tidak blur',
    'Semua obat ada',
    'Latar polos',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _setup();
    _loadScheduleInfo();
  }

  Future<void> _loadScheduleInfo() async {
    try {
      final today = await ApiService.instance.getTodayMedication();
      final schedule = today['schedule'] as Map<String, dynamic>?;
      if (schedule == null) return;
      final medType = schedule['medication_type'] as String?;
      final fdc = schedule['fdc_type'] as String?;
      final count = (schedule['tablet_count'] as num?)?.toInt();
      final freq = (schedule['frequency_per_week'] as num?)?.toInt() ?? 7;
      final ph = schedule['phase'] as String? ?? 'intensive';
      final rawMeds = schedule['medications'];
      List<String> meds;
      if (rawMeds is List) {
        if (rawMeds.isNotEmpty && rawMeds.first is String) {
          meds = List<String>.from(rawMeds);
        } else {
          meds = rawMeds
              .map((e) => (e as Map<String, dynamic>)['code'] as String? ?? '')
              .where((s) => s.isNotEmpty)
              .toList();
        }
      } else {
        meds = ph == 'intensive' ? ['R', 'H', 'Z', 'E'] : ['R', 'H'];
      }
      if (mounted) {
        setState(() {
          _medicationType = medType;
          _fdcType = fdc;
          _tabletCount = count;
          _frequencyPerWeek = freq;
          _phase = ph;
          _customMeds = meds;
          _meds = meds;
        });
      }
    } catch (_) {
      // keep defaults — camera still works without schedule info
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _setup() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      await _initCamera();
    } else {
      setState(() => _permissionDenied = true);
      _showPermissionDialog(permanentlyDenied: status.isPermanentlyDenied);
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _cameraUnavailable = true);
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _isInitialized = true;
        _permissionDenied = false;
        _cameraUnavailable = false;
      });
    } catch (_) {
      if (mounted) setState(() => _cameraUnavailable = true);
    }
  }

  void _showPermissionDialog({required bool permanentlyDenied}) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Izin Kamera Diperlukan'),
        content: Text(
          permanentlyDenied
              ? 'Kamera diblokir. Buka pengaturan aplikasi lalu aktifkan izin Kamera secara manual.'
              : 'Aplikasi memerlukan akses kamera untuk memfoto obatmu.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (context.canPop()) context.pop();
            },
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              openAppSettings();
            },
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }

  Future<void> _capture() async {
    if (_isScanning) return;
    HapticFeedback.lightImpact();
    setState(() => _isScanning = true);
    try {
      final controller = _controller;
      if (controller == null || !controller.value.isInitialized) {
        throw const ServerException('Kamera belum siap.');
      }
      final picture = await controller.takePicture();
      final bytes = await picture.readAsBytes();
      final today = await ApiService.instance.getTodayMedication();
      final schedule = today['schedule'] as Map<String, dynamic>?;
      final scheduleId = schedule?['id'] as String?;
      if (scheduleId == null || scheduleId.isEmpty) {
        throw const ServerException('Jadwal obat belum tersedia.');
      }
      final result = await ApiService.instance.confirmMedication(
        scheduleId: scheduleId,
        photoBase64: base64Encode(bytes),
        photoTakenAt: DateTime.now(),
      );
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      final streak = result['streak_count'] as int? ?? 0;
      context.go('/medication/success/$streak');
    } catch (e) {
      if (mounted) {
        HapticFeedback.vibrate();
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiErrorMessage(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const sheetFraction = 0.42;
    final sheetTop = size.height * (1 - sheetFraction);
    const aiBarHeight = 44.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: _buildCameraLayer()),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: size.height * sheetFraction + aiBarHeight,
            child: Center(
              child: _GuideOverlay(
                scanAnimation: _scanController,
                scanning: _isScanning,
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopBar(
              scanning: _isScanning,
              onClose: () {
                if (context.canPop()) context.pop();
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: sheetTop - aiBarHeight,
            height: aiBarHeight,
            child: _AIStatusBar(scanning: _isScanning),
          ),
          DraggableScrollableSheet(
            initialChildSize: sheetFraction,
            minChildSize: sheetFraction,
            maxChildSize: 0.82,
            builder: (context, scrollController) {
              return _BottomSheet(
                scrollController: scrollController,
                scanning: _isScanning,
                meds: _meds,
                tips: _tips,
                medicationType: _medicationType,
                fdcType: _fdcType,
                tabletCount: _tabletCount,
                frequencyPerWeek: _frequencyPerWeek,
                phase: _phase,
                customMeds: _customMeds,
                onCapture: _capture,
                onCancel: () {
                  if (context.canPop()) context.pop();
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCameraLayer() {
    final controller = _controller;
    if (_isInitialized &&
        controller != null &&
        controller.value.isInitialized) {
      final preview = controller.value.previewSize!;
      return ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: preview.height,
            height: preview.width,
            child: CameraPreview(controller),
          ),
        ),
      );
    }
    // Fallback: dark camera placeholder (no camera / permission pending).
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.1,
          colors: [Color(0xFF1A1A1A), Color(0xFF050505)],
        ),
      ),
      child: Center(
        child: _permissionDenied
            ? Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.no_photography_outlined,
                      color: Colors.white38,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Izin kamera belum diberikan',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            : _cameraUnavailable
            ? Text(
                'Kamera tidak tersedia',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              )
            : const CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}

// ── Top bar ──────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final bool scanning;
  final VoidCallback onClose;

  const _TopBar({required this.scanning, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      color: Colors.black,
      padding: EdgeInsets.fromLTRB(16, topPad + 10, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF333333),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  scanning ? 'Memverifikasi Foto' : 'Foto Obat Kamu',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pastikan semua obat terlihat',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}

// ── Scan guide overlay ───────────────────────────────────────
class _GuideOverlay extends StatelessWidget {
  final Animation<double> scanAnimation;
  final bool scanning;

  const _GuideOverlay({required this.scanAnimation, required this.scanning});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 200,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: scanAnimation,
            builder: (context, _) {
              return CustomPaint(
                size: const Size(280, 200),
                painter: _CornerBracketsPainter(
                  glow: scanning ? 0.5 + scanAnimation.value * 0.5 : 0.35,
                ),
              );
            },
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.medication_outlined,
                  size: 32,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
                const SizedBox(height: 10),
                Text(
                  scanning ? 'Menganalisis obat...' : 'Letakkan obat di sini',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: scanAnimation,
            builder: (context, _) {
              return Positioned(
                top: scanAnimation.value * 198,
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.primary,
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.8),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CornerBracketsPainter extends CustomPainter {
  final double glow;

  _CornerBracketsPainter({required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    const arm = 24.0;
    const radius = 12.0;
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final glowPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: glow)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final topLeft = Path()
      ..moveTo(0, arm)
      ..lineTo(0, radius)
      ..arcToPoint(
        const Offset(radius, 0),
        radius: const Radius.circular(radius),
      )
      ..lineTo(arm, 0);

    final topRight = Path()
      ..moveTo(w - arm, 0)
      ..lineTo(w - radius, 0)
      ..arcToPoint(Offset(w, radius), radius: const Radius.circular(radius))
      ..lineTo(w, arm);

    final bottomLeft = Path()
      ..moveTo(0, h - arm)
      ..lineTo(0, h - radius)
      ..arcToPoint(
        Offset(radius, h),
        radius: const Radius.circular(radius),
        clockwise: false,
      )
      ..lineTo(arm, h);

    final bottomRight = Path()
      ..moveTo(w, h - arm)
      ..lineTo(w, h - radius)
      ..arcToPoint(Offset(w - radius, h), radius: const Radius.circular(radius))
      ..lineTo(w - arm, h);

    for (final path in [topLeft, topRight, bottomLeft, bottomRight]) {
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CornerBracketsPainter oldDelegate) =>
      oldDelegate.glow != glow;
}

// ── AI status bar ────────────────────────────────────────────
class _AIStatusBar extends StatefulWidget {
  final bool scanning;

  const _AIStatusBar({required this.scanning});

  @override
  State<_AIStatusBar> createState() => _AIStatusBarState();
}

class _AIStatusBarState extends State<_AIStatusBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                widget.scanning
                    ? 'AI sedang memverifikasi foto...'
                    : 'AI siap memverifikasi',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9ECFC4),
                ),
              ),
            ],
          ),
          widget.scanning
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.primary,
                  ),
                )
              : AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) {
                    final t = _pulse.value;
                    return SizedBox(
                      width: 14,
                      height: 14,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.scale(
                            scale: 1 + t * 0.6,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(
                                  0xFF3ED27E,
                                ).withValues(alpha: (1 - t) * 0.7),
                              ),
                            ),
                          ),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF3ED27E),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}

// ── Bottom sheet ─────────────────────────────────────────────
class _BottomSheet extends StatelessWidget {
  final ScrollController scrollController;
  final bool scanning;
  final List<String> meds;
  final List<String> tips;
  final String? medicationType;
  final String? fdcType;
  final int? tabletCount;
  final int frequencyPerWeek;
  final String phase;
  final List<String> customMeds;
  final VoidCallback onCapture;
  final VoidCallback onCancel;

  const _BottomSheet({
    required this.scrollController,
    required this.scanning,
    required this.meds,
    required this.tips,
    this.medicationType,
    this.fdcType,
    this.tabletCount,
    this.frequencyPerWeek = 7,
    this.phase = 'intensive',
    this.customMeds = const [],
    required this.onCapture,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD4DAD8),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildMedicationInfoCard(),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          if (scanning) _buildAnalyzing() else _buildPhotoTips(),
          const SizedBox(height: 18),
          _buildCaptureButton(),
          const SizedBox(height: 6),
          if (!scanning)
            Text(
              'Tidak bisa memilih dari galeri',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppColors.textMute,
              ),
            ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: onCancel,
              child: Text(
                'Batalkan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMute,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationInfoCard() {
    final isFDC = medicationType == 'FDC';
    final fdc4or2 = phase == 'intensive' ? '4FDC' : '2FDC';
    final freqLabel = frequencyPerWeek == 3 ? '3x seminggu' : 'Setiap hari';

    final String jenisObat;
    final String? extraLine;
    if (isFDC) {
      jenisObat = '$fdc4or2 (${fdcType ?? "FDC"})';
      extraLine = tabletCount != null ? '$tabletCount tablet' : null;
    } else if (medicationType == 'Kombinasi') {
      jenisObat = 'Kombinasi Khusus';
      final medNames = {
        'R': 'Rifampicin', 'H': 'Isoniazid',
        'Z': 'Pirazinamid', 'E': 'Etambutol',
      };
      final names = customMeds.map((m) => medNames[m] ?? m).toList();
      extraLine = names.isNotEmpty ? names.join(' + ') : null;
    } else {
      jenisObat = phase == 'intensive' ? 'RHZE (Fase Intensif)' : 'RH (Fase Lanjutan)';
      extraLine = null;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.tealSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💊', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                scanning ? 'Obat yang sedang diverifikasi' : 'Obat untuk dikonfirmasi hari ini',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _infoRow('Jenis', jenisObat),
          if (extraLine != null) _infoRow(isFDC ? 'Jumlah' : 'Obat', extraLine),
          _infoRow('Frekuensi', freqLabel),
          if (!scanning) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),
            const Text(
              '📸 Foto harus menampilkan:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            _checkItem('Semua tablet di telapak tangan'),
            _checkItem(isFDC && tabletCount != null
                ? 'Jumlah tablet terlihat jelas ($tabletCount tablet)'
                : 'Semua obat terlihat jelas'),
            _checkItem('Pencahayaan cukup'),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textMute,
              ),
            ),
          ),
          const Text(':', style: TextStyle(fontSize: 12, color: AppColors.textMute)),
          const SizedBox(width: 8),
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
      ),
    );
  }

  Widget _checkItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💡 Tips foto yang baik',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < tips.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(child: _tipItem(tips[i])),
                const SizedBox(width: 12),
                Expanded(
                  child: i + 1 < tips.length
                      ? _tipItem(tips[i + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _tipItem(String text) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.tealSoft,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 11,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.text,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzing() {
    return Row(
      children: [
        const SizedBox(
          width: 56,
          height: 56,
          child: CircularProgressIndicator(
            strokeWidth: 8,
            color: AppColors.primary,
            backgroundColor: AppColors.border,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Menganalisis...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Biasanya kurang dari 3 detik',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMute,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCaptureButton() {
    if (scanning) {
      return Center(
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFC8D6D1), width: 3),
          ),
          child: Center(
            child: Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE8EFEC),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 24,
                color: Color(0xFF9AAFA8),
              ),
            ),
          ),
        ),
      );
    }
    return Center(
      child: GestureDetector(
        onTap: onCapture,
        child: Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 28,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
