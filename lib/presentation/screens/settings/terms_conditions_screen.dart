import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class TermsConditionsScreen extends StatefulWidget {
  const TermsConditionsScreen({super.key});

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeAnim;
  final Set<int> _expanded = {0};

  static const _sections = [
    (
      Icons.handshake_outlined,
      'Penerimaan Syarat',
      'Dengan menggunakan aplikasi DigitalPMO, kamu setuju untuk terikat dengan syarat dan ketentuan ini. Jika kamu tidak setuju dengan bagian mana pun dari syarat ini, kamu tidak diizinkan untuk menggunakan layanan kami.\n\n'
          'Syarat ini berlaku bagi semua pengguna, termasuk pasien TB, PMO, dan tenaga kesehatan yang menggunakan aplikasi.',
    ),
    (
      Icons.medical_services_outlined,
      'Deskripsi Layanan',
      'DigitalPMO adalah aplikasi manajemen kepatuhan pengobatan tuberkulosis (TB) yang menyediakan:\n\n'
          '• Manajemen jadwal minum obat harian\n'
          '• Konfirmasi minum obat berbasis foto\n'
          '• Pemantauan gejala dan efek samping\n'
          '• Analisis risiko berbasis AI (bersifat indikatif)\n'
          '• Komunikasi antara pasien dan PMO\n'
          '• Laporan kepatuhan bulanan\n\n'
          'Layanan ini bersifat pendukung dan tidak menggantikan konsultasi medis profesional.',
    ),
    (
      Icons.account_circle_outlined,
      'Akun Pengguna',
      'Untuk menggunakan DigitalPMO, kamu harus:\n\n'
          '• Mendaftar dengan nomor telepon yang valid\n'
          '• Memberikan informasi yang akurat dan terkini\n'
          '• Menjaga kerahasiaan kata sandi akunmu\n'
          '• Bertanggung jawab atas semua aktivitas yang terjadi di akunmu\n'
          '• Segera memberi tahu kami jika terjadi penggunaan tidak sah\n\n'
          'Kami berhak menangguhkan akun yang melanggar syarat penggunaan.',
    ),
    (
      Icons.warning_amber_outlined,
      'Batasan Medis',
      'PENTING: Aplikasi DigitalPMO bukan pengganti layanan medis profesional.\n\n'
          '• Fitur AI hanya bersifat indikatif dan edukatif\n'
          '• Keputusan medis harus selalu dikonsultasikan dengan dokter\n'
          '• Jangan menghentikan atau mengubah pengobatan tanpa rekomendasi dokter\n'
          '• Untuk kondisi darurat medis, segera hubungi fasilitas kesehatan terdekat\n\n'
          'Kami tidak bertanggung jawab atas kerugian yang timbul akibat ketergantungan berlebihan pada analisis AI aplikasi.',
    ),
    (
      Icons.photo_camera_outlined,
      'Konten yang Diunggah',
      'Dengan mengunggah foto atau konten lainnya, kamu menyatakan bahwa:\n\n'
          '• Konten tidak melanggar hak pihak ketiga\n'
          '• Konten tidak mengandung materi ilegal atau tidak pantas\n'
          '• Foto minum obat merupakan representasi akurat dari kegiatan nyata\n\n'
          'Kami berhak menghapus konten yang melanggar syarat ini dan menangguhkan akun yang bersangkutan.',
    ),
    (
      Icons.block_outlined,
      'Penggunaan yang Dilarang',
      'Kamu dilarang menggunakan DigitalPMO untuk:\n\n'
          '• Memalsukan data kepatuhan pengobatan\n'
          '• Menyebarkan informasi medis yang menyesatkan\n'
          '• Mengakses akun atau data pengguna lain\n'
          '• Melakukan reverse engineering pada aplikasi\n'
          '• Membebani server secara berlebihan\n'
          '• Tujuan komersial tanpa izin tertulis',
    ),
    (
      Icons.gavel_outlined,
      'Kekayaan Intelektual',
      'Seluruh konten, desain, dan teknologi dalam DigitalPMO dilindungi oleh hak cipta dan hak kekayaan intelektual yang dimiliki oleh tim pengembang DigitalPMO.\n\n'
          'Kamu tidak diizinkan untuk menyalin, mendistribusikan, atau memodifikasi konten aplikasi tanpa izin tertulis.',
    ),
    (
      Icons.cancel_outlined,
      'Penghentian Layanan',
      'Kami berhak menghentikan atau menangguhkan akses ke layanan kapan saja, dengan atau tanpa pemberitahuan, jika:\n\n'
          '• Terjadi pelanggaran syarat penggunaan\n'
          '• Terdapat aktivitas yang mencurigakan atau berbahaya\n'
          '• Diperlukan untuk pemeliharaan atau perbaikan sistem\n\n'
          'Penghentian layanan tidak menghilangkan kewajiban yang sudah timbul sebelumnya.',
    ),
    (
      Icons.update_rounded,
      'Perubahan Syarat',
      'Kami dapat memperbarui syarat dan ketentuan ini sewaktu-waktu. Perubahan material akan diberitahukan minimal 7 hari sebelum berlaku melalui notifikasi aplikasi.\n\n'
          'Penggunaan aplikasi setelah perubahan berlaku dianggap sebagai persetujuan terhadap syarat yang diperbarui.\n\n'
          'Terakhir diperbarui: 19 Mei 2026',
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
                      'Syarat & Ketentuan',
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
                      color: AppColors.amberSoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.gavel_outlined,
                            color: AppColors.amber, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Harap baca syarat ini dengan seksama sebelum menggunakan '
                            'aplikasi DigitalPMO. Penggunaan aplikasi berarti kamu menyetujui syarat ini.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: const Color(0xFFA66A00),
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
                  Divider(color: AppColors.border, height: 1, thickness: 1),
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
