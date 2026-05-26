import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeAnim;
  final Set<int> _expanded = {0};

  static const _sections = [
    (
      Icons.info_outline_rounded,
      'Informasi yang Kami Kumpulkan',
      'Kami mengumpulkan informasi yang kamu berikan secara langsung, termasuk:\n\n'
          '• Nama lengkap dan nomor telepon\n'
          '• Alamat email (opsional)\n'
          '• Tanggal lahir dan jenis kelamin\n'
          '• Data kesehatan: diagnosis TB, fase pengobatan, jadwal obat\n'
          '• Foto konfirmasi minum obat (diproses secara lokal)\n'
          '• Riwayat gejala dan efek samping\n'
          '• Informasi perangkat dan token FCM untuk notifikasi push',
    ),
    (
      Icons.security_outlined,
      'Bagaimana Kami Menggunakan Data',
      'Data yang dikumpulkan digunakan untuk:\n\n'
          '• Mengelola jadwal dan pengingat minum obat\n'
          '• Memantau kepatuhan pengobatan TB\n'
          '• Menyediakan analisis AI untuk deteksi risiko dini\n'
          '• Mengirim notifikasi pengingat yang dipersonalisasi\n'
          '• Menghasilkan laporan bulanan untuk PMO dan tenaga medis\n'
          '• Meningkatkan kualitas layanan aplikasi',
    ),
    (
      Icons.lock_outline_rounded,
      'Keamanan Data',
      'Kami berkomitmen melindungi data pribadimu dengan:\n\n'
          '• Enkripsi data saat transit (HTTPS/TLS 1.3)\n'
          '• Hash password menggunakan bcrypt\n'
          '• Token akses dengan masa berlaku terbatas (JWT)\n'
          '• Anonimisasi alamat IP di log audit\n'
          '• Penyimpanan data di server yang aman\n'
          '• Akses terbatas hanya untuk personil yang berwenang',
    ),
    (
      Icons.share_outlined,
      'Berbagi Data dengan Pihak Ketiga',
      'Kami tidak menjual atau menyewakan data pribadimu. Data dapat dibagikan kepada:\n\n'
          '• PMO (Pengawas Menelan Obat) yang ditunjuk\n'
          '• Tenaga kesehatan yang merawat\n'
          '• Fasilitas kesehatan terkait\n\n'
          'Setiap berbagi data dilakukan dengan persetujuanmu dan sesuai regulasi yang berlaku.',
    ),
    (
      Icons.storage_outlined,
      'Penyimpanan & Penghapusan Data',
      'Data akun aktif disimpan selama kamu menggunakan aplikasi. Kamu dapat:\n\n'
          '• Meminta penghapusan akun melalui fitur "Hubungi Dukungan"\n'
          '• Menghapus data lokal melalui menu Pengaturan → Hapus Semua Data\n\n'
          'Data medis yang menjadi bagian rekam medis resmi dapat dipertahankan sesuai peraturan perundangan yang berlaku di bidang kesehatan.',
    ),
    (
      Icons.child_care_outlined,
      'Privasi Anak',
      'Aplikasi DigitalPMO tidak ditujukan untuk anak di bawah usia 13 tahun. Jika kami mengetahui adanya data dari anak di bawah usia tersebut tanpa persetujuan orang tua, kami akan segera menghapusnya.',
    ),
    (
      Icons.update_rounded,
      'Perubahan Kebijakan',
      'Kebijakan privasi ini dapat diperbarui sewaktu-waktu. Perubahan signifikan akan diberitahukan melalui notifikasi aplikasi atau email. Penggunaan aplikasi setelah perubahan berlaku dianggap sebagai persetujuan terhadap kebijakan yang diperbarui.\n\n'
          'Terakhir diperbarui: 19 Mei 2026',
    ),
    (
      Icons.contact_support_outlined,
      'Kontak & Pertanyaan',
      'Untuk pertanyaan seputar kebijakan privasi atau permintaan data, hubungi kami melalui:\n\n'
          '• Fitur "Hubungi Dukungan" di menu Pengaturan\n'
          '• Email: privacy@digitalpmo.app\n\n'
          'Tim kami akan merespons dalam 1×24 jam kerja.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
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
                      'Kebijakan Privasi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Berlaku sejak 19 Mei 2026',
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
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.tealSoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shield_outlined,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'DigitalPMO berkomitmen melindungi privasi dan keamanan '
                            'data kesehatanmu. Bacalah kebijakan ini dengan seksama.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: AppColors.primary.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._sections.asMap().entries.map((entry) {
                    final i = entry.key;
                    final (icon, title, body) = entry.value;
                    final isOpen = _expanded.contains(i);
                    return _AccordionTile(
                      icon: icon,
                      title: title,
                      body: body,
                      isOpen: isOpen,
                      onTap: () => setState(() {
                        if (isOpen) {
                          _expanded.remove(i);
                        } else {
                          _expanded.add(i);
                        }
                      }),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccordionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool isOpen;
  final VoidCallback onTap;

  const _AccordionTile({
    required this.icon,
    required this.title,
    required this.body,
    required this.isOpen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOpen
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isOpen
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 17,
                      color: isOpen ? AppColors.primary : AppColors.textMute,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isOpen ? AppColors.primary : AppColors.text,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isOpen ? AppColors.primary : AppColors.textMute,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: isOpen
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                      color: AppColors.border, height: 1, thickness: 1),
                  const SizedBox(height: 12),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: AppColors.textMute,
                    ),
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
