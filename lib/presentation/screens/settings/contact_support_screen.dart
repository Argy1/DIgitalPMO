import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/pmo_button.dart';

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen>
    with SingleTickerProviderStateMixin {
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _category = 'bug';
  bool _isLoading = false;
  bool _submitted = false;
  String _ticketNumber = '';

  late final AnimationController _entryCtrl;
  late final List<Animation<double>> _anims;
  late final AnimationController _successCtrl;

  static const _categories = [
    ('bug', 'Laporan Bug', Icons.bug_report_outlined),
    ('feature', 'Saran Fitur', Icons.lightbulb_outline_rounded),
    ('account', 'Masalah Akun', Icons.manage_accounts_outlined),
    ('other', 'Lainnya', Icons.help_outline_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anims = List.generate(4, (i) {
      final s = i * 0.15;
      final e = (s + 0.6).clamp(0.0, 1.0);
      return CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic));
    });
    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _successCtrl.dispose();
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.instance.submitSupportTicket(
        category: _category,
        subject: _subjectCtrl.text.trim(),
        message: _messageCtrl.text.trim(),
      );
      if (mounted) {
        setState(() {
          _submitted = true;
          _ticketNumber = res['ticket_number'] as String? ?? '-';
          _isLoading = false;
        });
        _successCtrl.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiErrorMessage(e)),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, Color(0xFF15594B)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 28),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hubungi Dukungan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Kami siap membantu dalam 1×24 jam',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: _submitted ? _buildSuccess() : _buildForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return FadeTransition(
      opacity: _successCtrl,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: AppColors.successGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Laporan Terkirim!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Tim kami akan meninjau laporanmu dan '
                'merespons dalam 1×24 jam melalui notifikasi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textMute,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.tealSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Text(
                      'NOMOR TIKET',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.textMute,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _ticketNumber,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: PMOButton(
                  'Kembali ke Pengaturan',
                  onPressed: () => context.pop(),
                  variant: ButtonVariant.ghost,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          _anim(
            _sectionLabel('KATEGORI LAPORAN', Icons.category_outlined),
            0,
          ),
          const SizedBox(height: 10),
          _anim(_categoryChips(), 0),
          const SizedBox(height: 20),
          _anim(
            _sectionLabel('DETAIL LAPORAN', Icons.description_outlined),
            1,
          ),
          const SizedBox(height: 10),
          _anim(
            _card(
              child: Column(
                children: [
                  _textField(
                    controller: _subjectCtrl,
                    label: 'Subjek',
                    hint: 'Contoh: Tombol konfirmasi tidak berfungsi',
                    icon: Icons.title_rounded,
                    validator: (v) {
                      if (v == null || v.trim().length < 5) {
                        return 'Subjek minimal 5 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _textField(
                    controller: _messageCtrl,
                    label: 'Pesan / Detail Masalah',
                    hint: 'Deskripsikan masalah secara detail agar kami bisa '
                        'membantu dengan cepat...',
                    icon: Icons.message_outlined,
                    maxLines: 6,
                    validator: (v) {
                      if (v == null || v.trim().length < 20) {
                        return 'Pesan minimal 20 karakter';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            2,
          ),
          const SizedBox(height: 10),
          _anim(
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.amberSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.amber, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Untuk darurat medis, hubungi faskes atau doktermu langsung.',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFFA66A00),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            2,
          ),
          const SizedBox(height: 24),
          _anim(
            PMOButton(
              'Kirim Laporan',
              onPressed: _submit,
              isLoading: _isLoading,
              icon: Icons.send_rounded,
            ),
            3,
          ),
        ],
      ),
    );
  }

  Widget _anim(Widget child, int index) {
    final anim = _anims[index];
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) => Opacity(
        opacity: (0.3 + 0.7 * anim.value).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - anim.value)),
          child: child,
        ),
      ),
      child: child,
    );
  }

  Widget _sectionLabel(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textMute),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textMute,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _categoryChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _categories.map((cat) {
        final (value, label, icon) = cat;
        final selected = _category == value;
        return GestureDetector(
          onTap: () => setState(() => _category = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary
                  : AppColors.card,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color:
                    selected ? AppColors.primary : AppColors.border,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? Colors.white : AppColors.textMute,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        selected ? Colors.white : AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.text,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle:
            TextStyle(fontSize: 13, color: AppColors.textMute.withValues(alpha: 0.6)),
        labelStyle: const TextStyle(fontSize: 13, color: AppColors.textMute),
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? 60.0 : 0.0),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
    );
  }
}
