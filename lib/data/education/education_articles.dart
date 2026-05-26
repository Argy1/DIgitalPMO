import 'package:flutter/material.dart';

enum ContentType { paragraph, heading, bullet, quote, highlight }

class ContentBlock {
  final ContentType type;
  final String text;
  const ContentBlock(this.type, this.text);
}

class EducationArticle {
  final String id;
  final String title;
  final String category;
  final String preview;
  final int readMinutes;
  final DateTime publishedAt;
  final List<ContentBlock> content;
  final List<String> relatedIds;

  const EducationArticle({
    required this.id,
    required this.title,
    required this.category,
    required this.preview,
    required this.readMinutes,
    required this.publishedAt,
    required this.content,
    required this.relatedIds,
  });

  Color get categoryColor =>
      _categoryColors[category] ?? const Color(0xFF1A6B5A);
  IconData get categoryIcon =>
      _categoryIcons[category] ?? Icons.article;
  bool get isNew =>
      DateTime.now().difference(publishedAt).inDays < 7;
}

const _categoryColors = <String, Color>{
  'Tentang TB': Color(0xFF1A6B5A),
  'Obat-obatan': Color(0xFF2E86DE),
  'Efek Samping': Color(0xFFF5A623),
  'Gaya Hidup': Color(0xFF27AE60),
  'Motivasi': Color(0xFF8B5CF6),
  'Bahaya Berhenti': Color(0xFFE74C3C),
};

const _categoryIcons = <String, IconData>{
  'Tentang TB': Icons.info,
  'Obat-obatan': Icons.medication_rounded,
  'Efek Samping': Icons.warning,
  'Gaya Hidup': Icons.fitness_center,
  'Motivasi': Icons.emoji_events,
  'Bahaya Berhenti': Icons.do_not_disturb_on,
};

// Shorthand builders for content blocks
ContentBlock _p(String t) => ContentBlock(ContentType.paragraph, t);
ContentBlock _h(String t) => ContentBlock(ContentType.heading, t);
ContentBlock _b(String t) => ContentBlock(ContentType.bullet, t);
ContentBlock _q(String t) => ContentBlock(ContentType.quote, t);
ContentBlock _hl(String t) => ContentBlock(ContentType.highlight, t);

final _now = DateTime.now();

final educationArticles = <EducationArticle>[
  // ── Bahaya Berhenti ───────────────────────────────────────────────────────
  EducationArticle(
    id: 'bahaya-walau-sehat',
    title: 'Kenapa Tidak Boleh Berhenti Walau Sudah Sehat?',
    category: 'Bahaya Berhenti',
    preview:
        'Merasa membaik setelah 2 bulan bukan berarti bakteri TB sudah mati. Pelajari kenapa 6 bulan itu wajib.',
    readMinutes: 3,
    publishedAt: _now.subtract(const Duration(days: 3)),
    relatedIds: ['bahaya-tb-ro', 'bahaya-skip'],
    content: [
      _p('Setelah 2–3 bulan pengobatan, banyak pasien TB mulai merasa lebih baik. Batuk berkurang, nafsu makan kembali, dan energi terasa pulih. Wajar jika kamu merasa sudah sembuh — tapi ini bisa menjadi jebakan berbahaya.'),
      _q('Merasa sehat BUKAN berarti bakteri TB sudah mati sepenuhnya.'),
      _p('Bakteri TB (Mycobacterium tuberculosis) sangat licik. Sebagian besar memang mati di bulan-bulan pertama, tapi sebagian kecil "bersembunyi" dalam keadaan dorman (tidur) di sel-sel tubuhmu. Obat TB butuh waktu penuh 6 bulan untuk membunuh bakteri dorman ini.'),
      _h('Apa yang Terjadi Jika Berhenti?'),
      _b('Bakteri yang "tertidur" aktif kembali dalam 3–6 bulan'),
      _b('Kamu bisa menularkan TB ke orang-orang di sekitar'),
      _b('Bakteri belajar melawan obat → TB Resisten Obat (TB-RO)'),
      _b('Pengobatan TB-RO butuh 18–24 bulan, jauh lebih menyiksa'),
      _p('TB-RO membutuhkan pengobatan yang jauh lebih panjang dengan obat yang lebih keras dan efek samping yang lebih berat. Angka keberhasilan pengobatan TB-RO pun lebih rendah dari TB biasa.'),
      _hl('Selesaikan 6 bulan penuh — ini satu-satunya cara benar-benar sembuh dari TB!'),
    ],
  ),

  EducationArticle(
    id: 'bahaya-tb-ro',
    title: 'Apa itu TB Resisten Obat (TB-RO)?',
    category: 'Bahaya Berhenti',
    preview:
        'TB-RO adalah TB yang sudah kebal terhadap obat standar. Indonesia termasuk negara dengan kasus TB-RO tertinggi.',
    readMinutes: 4,
    publishedAt: _now.subtract(const Duration(days: 14)),
    relatedIds: ['bahaya-walau-sehat', 'bahaya-skip'],
    content: [
      _p('TB-RO adalah tuberkulosis yang disebabkan bakteri yang sudah tidak mempan dengan obat TB standar. Ini terjadi ketika bakteri "berevolusi" akibat pengobatan yang tidak tuntas atau tidak teratur.'),
      _h('Kenapa Bisa Terjadi?'),
      _b('Pasien berhenti minum obat sebelum 6 bulan selesai'),
      _b('Minum obat tidak teratur — sering skip beberapa hari'),
      _b('Dosis obat yang tidak tepat dari fasilitas kesehatan'),
      _q('TB-RO adalah salah satu ancaman kesehatan global terbesar. Indonesia adalah salah satu negara dengan kasus TB-RO tertinggi di dunia, dengan puluhan ribu kasus baru setiap tahunnya.'),
      _h('TB Biasa vs TB-RO'),
      _p('TB biasa: 6 bulan pengobatan, 4 jenis obat, efek samping ringan–sedang, tingkat kesembuhan di atas 85%.'),
      _p('TB-RO: 18–24 bulan pengobatan, 5–6 jenis obat yang lebih keras, efek samping berat termasuk kerusakan pendengaran dan ginjal, biaya jauh lebih mahal, tingkat kesembuhan sekitar 60%.'),
      _hl('Mencegah TB-RO jauh lebih mudah daripada mengobatinya: cukup selesaikan pengobatan 6 bulan dengan teratur!'),
    ],
  ),

  EducationArticle(
    id: 'bahaya-skip',
    title: 'Skip 1 Hari, Seberapa Berbahaya?',
    category: 'Bahaya Berhenti',
    preview:
        'Lewat satu hari minum obat terasa sepele, tapi efeknya bisa jauh lebih serius dari yang kamu kira.',
    readMinutes: 2,
    publishedAt: _now.subtract(const Duration(days: 5)),
    relatedIds: ['bahaya-walau-sehat', 'bahaya-tb-ro'],
    content: [
      _p('Pertanyaan yang sering ditanyakan: "Kalau cuma skip 1 hari, memangnya kenapa?" Jawabannya lebih serius dari yang kamu kira.'),
      _h('Cara Kerja Obat TB di Tubuhmu'),
      _p('Obat TB bekerja dengan mempertahankan kadar tertentu dalam darah secara terus-menerus selama 24 jam. Ketika kamu skip 1 hari, kadar obat dalam darah turun di bawah ambang batas efektif.'),
      _b('Bakteri yang tadinya "tertekan" mulai aktif kembali'),
      _b('Jika ini terjadi berulang, bakteri belajar bertahan melawan obat'),
      _b('Risiko resistensi meningkat setiap kali kamu melewatkan dosis'),
      _q('Skip 1 hari sebulan mungkin tidak terasa. Tapi skip 4–5 hari dalam 6 bulan pengobatan sudah cukup untuk mengurangi efektivitas pengobatan secara signifikan.'),
      _h('Jika Terlupa Hari Ini'),
      _p('Minum segera saat ingat — kecuali jika sudah hampir waktunya dosis berikutnya. Jangan pernah minum 2 dosis sekaligus untuk mengganti yang terlewat.'),
      _hl('Buat alarm setiap hari dan minta bantuan anggota keluarga untuk mengingatkan. Konsistensi adalah kunci!'),
    ],
  ),

  // ── Tentang TB ────────────────────────────────────────────────────────────
  EducationArticle(
    id: 'tentang-menular',
    title: 'Bagaimana TB Menular?',
    category: 'Tentang TB',
    preview:
        'TB menyebar melalui udara, bukan sentuhan. Pahami cara penularan untuk melindungi orang-orang terdekat.',
    readMinutes: 3,
    publishedAt: _now.subtract(const Duration(days: 2)),
    relatedIds: ['tentang-gejala', 'tentang-keluarga'],
    content: [
      _p('TB menyebar melalui udara, bukan melalui sentuhan fisik atau berbagi peralatan makan. Ketika penderita TB aktif batuk, bersin, berbicara, atau bahkan menyanyi, bakteri TB keluar ke udara dalam tetesan sangat kecil yang bisa terhirup orang lain.'),
      _h('Siapa yang Berisiko Tertular?'),
      _b('Orang yang tinggal serumah dengan pasien TB aktif'),
      _b('Rekan kerja atau teman dekat yang sering kontak'),
      _b('Orang dengan daya tahan tubuh rendah: HIV, diabetes, malnutrisi'),
      _b('Anak-anak dan lansia dengan imunitas lebih lemah'),
      _q('TB TIDAK menular melalui jabat tangan, berbagi makanan atau minuman, duduk berdekatan sesaat, atau menyentuh benda yang digunakan pasien TB.'),
      _h('Kapan Tidak Menular Lagi?'),
      _p('Setelah 2 minggu minum obat secara teratur, sebagian besar pasien sudah tidak lagi menular. Pastikan doktermu mengonfirmasi status ini dengan pemeriksaan dahak.'),
      _p('Selama masih menular: gunakan masker, pastikan ventilasi ruangan baik, dan batasi kontak dekat dengan anak-anak serta lansia.'),
    ],
  ),

  EducationArticle(
    id: 'tentang-gejala',
    title: 'Gejala TB yang Perlu Diwaspadai',
    category: 'Tentang TB',
    preview:
        'TB sering terlihat seperti batuk biasa di awal. Kenali tanda-tandanya agar bisa ditangani lebih cepat.',
    readMinutes: 2,
    publishedAt: _now.subtract(const Duration(days: 20)),
    relatedIds: ['tentang-menular', 'tentang-keluarga'],
    content: [
      _p('TB bisa menyerupai penyakit pernapasan biasa di awal. Banyak pasien mengira hanya batuk pilek biasa — padahal TB diam-diam merusak paru-paru. Mengenali gejalanya sejak dini sangat penting.'),
      _h('Gejala Utama TB'),
      _b('Batuk lebih dari 2 minggu, bisa disertai dahak berwarna atau darah'),
      _b('Demam, terutama di sore dan malam hari'),
      _b('Keringat malam berlebihan yang membasahi baju atau seprai'),
      _b('Penurunan berat badan tanpa sebab yang jelas'),
      _b('Kelelahan terus-menerus dan hilangnya nafsu makan'),
      _b('Nyeri dada saat bernapas atau batuk'),
      _h('Kapan Harus ke Dokter?'),
      _hl('Jika batuk lebih dari 2 minggu, segera periksa ke Puskesmas. Tes dahak gratis tersedia dan hasilnya cepat!'),
      _p('TB bisa diobati sepenuhnya. Semakin cepat dideteksi, semakin mudah pengobatannya dan semakin kecil risiko menular ke orang lain.'),
    ],
  ),

  EducationArticle(
    id: 'tentang-keluarga',
    title: 'Cara Melindungi Keluarga di Rumah',
    category: 'Tentang TB',
    preview:
        'Ada banyak langkah praktis yang bisa dilakukan untuk mencegah penularan TB di dalam rumah.',
    readMinutes: 3,
    publishedAt: _now.subtract(const Duration(days: 10)),
    relatedIds: ['tentang-menular', 'tentang-gejala'],
    content: [
      _p('Kabar baiknya: ada banyak hal yang bisa kamu dan keluarga lakukan untuk mencegah penularan TB di lingkungan rumah. Penularan bisa dikurangi secara signifikan dengan langkah-langkah sederhana.'),
      _h('Langkah Pencegahan di Rumah'),
      _b('Gunakan masker di dalam ruangan tertutup, terutama saat bersama orang lain'),
      _b('Tutup mulut dengan tisu atau siku saat batuk atau bersin'),
      _b('Buka jendela setiap pagi — ventilasi dan sinar matahari sangat penting'),
      _b('Pastikan kamar tidur mendapat sinar matahari langsung setidaknya 1 jam sehari'),
      _b('Minta anggota keluarga untuk tes TB jika ada gejala mencurigakan'),
      _q('Sinar matahari langsung dapat membunuh bakteri TB dalam hitungan menit. Buka jendela setiap pagi dan keringkan tempat tidur di bawah sinar matahari!'),
      _h('Vaksin BCG untuk Anak'),
      _p('Pastikan anak-anak di rumah sudah mendapatkan vaksin BCG. Vaksin ini efektif melindungi anak dari bentuk TB yang paling berbahaya seperti meningitis TB.'),
      _p('Pasangan dan anak-anak yang tinggal serumah sebaiknya diperiksa di Puskesmas untuk tes TB dan kemungkinan pemberian profilaksis.'),
    ],
  ),

  // ── Obat-obatan ───────────────────────────────────────────────────────────
  EducationArticle(
    id: 'obat-rifampicin',
    title: 'Panduan Lengkap Rifampicin (R)',
    category: 'Obat-obatan',
    preview:
        'Rifampicin adalah obat utama TB. Pahami cara minum yang benar dan kenapa urine bisa berubah warna.',
    readMinutes: 4,
    publishedAt: _now.subtract(const Duration(days: 25)),
    relatedIds: ['obat-isoniazid', 'obat-pirazinamid-etambutol', 'obat-interaksi'],
    content: [
      _p('Rifampicin (R) adalah "panglima" dalam pengobatan TB. Obat ini membunuh bakteri TB secara aktif dan menjadi alasan kenapa urine atau air mata bisa berubah warna menjadi oranye-merah.'),
      _h('Cara Minum yang Benar'),
      _b('Minum di pagi hari, 30–60 menit SEBELUM makan'),
      _b('Tidak boleh diminum bersamaan dengan antasida (obat maag)'),
      _b('Harus diminum setiap hari pada jam yang sama'),
      _h('Efek Samping yang Normal (Tidak Berbahaya)'),
      _b('Urine, air mata, keringat berwarna oranye/merah → NORMAL dan tidak berbahaya'),
      _b('Lensa kontak bisa ternoda permanen → gunakan kacamata selama pengobatan'),
      _b('Mual ringan di minggu-minggu awal → biasanya hilang sendiri'),
      _q('Urine berwarna oranye atau merah adalah TANDA POSITIF bahwa Rifampicin bekerja di dalam tubuhmu. Ini bukan tanda bahaya!'),
      _h('Efek Samping yang Perlu Perhatian Dokter'),
      _b('Kuning pada mata atau kulit (jaundice) → segera lapor dokter'),
      _b('Ruam kulit yang parah → segera ke faskes terdekat'),
      _b('Demam tinggi disertai menggigil setelah minum obat'),
      _p('Rifampicin berinteraksi dengan banyak obat lain termasuk pil KB hormonal. Selalu beritahu semua dokter yang merawatmu bahwa kamu sedang minum Rifampicin.'),
    ],
  ),

  EducationArticle(
    id: 'obat-isoniazid',
    title: 'Panduan Lengkap Isoniazid (H)',
    category: 'Obat-obatan',
    preview:
        'Isoniazid adalah obat TB paling lama digunakan sejak 1952. Ketahui cara minum dan efek samping kesemutan.',
    readMinutes: 3,
    publishedAt: _now.subtract(const Duration(days: 18)),
    relatedIds: ['obat-rifampicin', 'obat-pirazinamid-etambutol'],
    content: [
      _p('Isoniazid (H) adalah obat TB yang paling lama digunakan dalam sejarah — sejak tahun 1952. Obat ini sangat efektif membunuh bakteri TB yang sedang aktif berkembang biak.'),
      _h('Cara Minum yang Benar'),
      _b('Bisa diminum saat perut kosong atau setelah makan ringan jika terasa mual'),
      _b('Hindari makanan tinggi tiramin: ikan kalengan, keju tua, makanan fermentasi'),
      _b('Konsumsi bersama vitamin B6 (piridoksin) jika diresepkan dokter'),
      _h('Efek Samping yang Umum'),
      _b('Kesemutan, mati rasa, atau rasa terbakar di tangan dan kaki'),
      _b('Mual atau kurang nafsu makan — coba minum setelah makan ringan'),
      _b('Kelemahan otot yang terasa di pagi hari'),
      _q('Kesemutan di tangan dan kaki adalah efek samping Isoniazid yang paling umum. Jangan abaikan — dokter bisa memberikan vitamin B6 untuk mengatasinya dengan cepat.'),
      _p('Kesemutan terjadi karena Isoniazid mengganggu metabolisme vitamin B6 di tubuh. Supplementasi B6 biasanya menyelesaikan masalah ini dalam 1–2 minggu.'),
    ],
  ),

  EducationArticle(
    id: 'obat-pirazinamid-etambutol',
    title: 'Panduan Pirazinamid (Z) & Etambutol (E)',
    category: 'Obat-obatan',
    preview:
        'Z dan E digunakan terutama di 2 bulan pertama. Waspadai nyeri sendi dari Z dan gangguan penglihatan dari E.',
    readMinutes: 3,
    publishedAt: _now.subtract(const Duration(days: 22)),
    relatedIds: ['obat-rifampicin', 'obat-isoniazid'],
    content: [
      _p('Pirazinamid (Z) dan Etambutol (E) bekerja bersama Rifampicin dan Isoniazid terutama di fase intensif (2 bulan pertama) untuk menyerang bakteri TB dari berbagai sudut.'),
      _h('Pirazinamid (Z)'),
      _b('Sangat efektif membunuh bakteri yang "bersembunyi" di dalam sel-sel tubuh'),
      _b('Efek samping umum: nyeri sendi terutama di bahu, lutut, dan pergelangan kaki'),
      _b('Mual — coba minum bersamaan dengan atau setelah makan'),
      _b('Kadar asam urat bisa meningkat — lapor jika ada pembengkakan sendi yang parah'),
      _h('Etambutol (E)'),
      _b('Mencegah bakteri TB berkembang biak dan mencegah resistensi'),
      _b('Efek samping paling penting: gangguan penglihatan (pandangan kabur, sulit membedakan warna)'),
      _b('Laporkan SEGERA ke dokter jika ada perubahan penglihatan apapun'),
      _b('Pemeriksaan mata berkala sangat dianjurkan selama pengobatan'),
      _q('Gangguan penglihatan akibat Etambutol umumnya bisa pulih sepenuhnya jika dilaporkan dan ditangani sejak dini.'),
    ],
  ),

  EducationArticle(
    id: 'obat-interaksi',
    title: 'Boleh Minum Obat TB Bersamaan dengan...',
    category: 'Obat-obatan',
    preview:
        'Beberapa obat tidak boleh dikombinasikan dengan obat TB. Pelajari apa yang boleh dan tidak boleh.',
    readMinutes: 3,
    publishedAt: _now.subtract(const Duration(days: 30)),
    relatedIds: ['obat-rifampicin', 'obat-isoniazid'],
    content: [
      _p('Obat-obatan TB, terutama Rifampicin, berinteraksi dengan banyak obat lain. Penting untuk tahu apa yang aman dan apa yang perlu dikonsultasikan ke dokter.'),
      _h('TIDAK BOLEH Bersamaan (Tanpa Konsultasi)'),
      _b('Antasida (obat maag) → minum minimal 2 jam setelah Rifampicin'),
      _b('Pil KB hormonal → efektivitasnya berkurang drastis, gunakan kontrasepsi alternatif'),
      _b('Warfarin (pengencer darah) → perlu penyesuaian dosis oleh dokter'),
      _b('Obat antiretroviral HIV tertentu → perlu pemantauan ketat'),
      _h('BOLEH, Tapi Beritahu Dokter'),
      _b('Suplemen vitamin dan mineral → umumnya aman'),
      _b('Paracetamol untuk demam → aman dalam dosis normal'),
      _b('Vitamin B6 (piridoksin) → justru dianjurkan bersama Isoniazid'),
      _q('Selalu beritahu SEMUA dokter yang menanganimu bahwa kamu sedang menjalani pengobatan TB, termasuk dokter gigi dan dokter spesialis lainnya.'),
    ],
  ),

  // ── Gaya Hidup ────────────────────────────────────────────────────────────
  EducationArticle(
    id: 'hidup-makanan',
    title: 'Makanan Terbaik Selama Pengobatan TB',
    category: 'Gaya Hidup',
    preview:
        'Nutrisi yang baik mempercepat pemulihan dan membantu tubuh melawan infeksi. Ini pilihan makanan terbaik.',
    readMinutes: 3,
    publishedAt: _now.subtract(const Duration(days: 1)),
    relatedIds: ['hidup-olahraga', 'hidup-istirahat'],
    content: [
      _p('Nutrisi yang baik adalah bagian penting dari pengobatan TB — bukan hanya suplemen, tapi makanan sehari-hari. Banyak pasien TB mengalami penurunan berat badan sebelum didiagnosis yang perlu diperbaiki agar pengobatan lebih efektif.'),
      _h('Makanan yang Dianjurkan'),
      _b('Protein tinggi: telur, ayam, ikan segar, tahu, tempe, kacang-kacangan'),
      _b('Karbohidrat kompleks: nasi, kentang, ubi, singkong'),
      _b('Sayuran beragam warna: bayam, wortel, brokoli, tomat'),
      _b('Buah-buahan segar: pisang, jeruk, mangga, pepaya'),
      _b('Susu dan produk susu (jangan bersamaan saat minum Rifampicin)'),
      _h('Yang Perlu Dikurangi atau Dihindari'),
      _b('Alkohol → sangat berbahaya, bisa merusak hati yang terbebani obat TB'),
      _b('Rokok → memperparah gejala pernapasan dan memperlambat penyembuhan'),
      _b('Ikan kalengan, keju tua → hindari saat minum Isoniazid'),
      _q('Makan bergizi 3 kali sehari dengan porsi yang cukup adalah bagian dari pengobatan TB-mu, sama pentingnya dengan minum obat.'),
    ],
  ),

  EducationArticle(
    id: 'hidup-olahraga',
    title: 'Bolehkah Olahraga Saat Sakit TB?',
    category: 'Gaya Hidup',
    preview:
        'Olahraga bisa membantu pemulihan — tapi ada aturannya. Ketahui apa yang aman di setiap fase pengobatan.',
    readMinutes: 2,
    publishedAt: _now.subtract(const Duration(days: 12)),
    relatedIds: ['hidup-makanan', 'hidup-istirahat'],
    content: [
      _p('Pertanyaan yang sering ditanyakan pasien TB aktif: "Bolehkah saya olahraga?" Jawabannya bergantung pada fase pengobatan dan kondisi tubuhmu.'),
      _h('Fase Intensif (Bulan 1–2): Istirahat Prioritas'),
      _p('Di bulan-bulan pertama, tubuhmu sedang berjuang keras melawan infeksi aktif. Sistem imun butuh energi yang besar.'),
      _b('Olahraga intens tidak dianjurkan'),
      _b('Aktivitas sangat ringan seperti jalan santai 10–15 menit masih diperbolehkan'),
      _b('Dengarkan tubuhmu — jika lelah, beristirahat tanpa rasa bersalah'),
      _h('Fase Lanjutan (Bulan 3–6): Aktivitas Bertahap'),
      _p('Setelah dokter mengonfirmasi kondisi membaik dan tidak lagi menular:'),
      _b('Olahraga ringan–sedang diperbolehkan dan bahkan dianjurkan'),
      _b('Mulai bertahap: berjalan kaki, senam ringan, bersepeda santai'),
      _b('Hindari olahraga yang memerlukan napas sangat berat atau kontak fisik intens'),
      _hl('Selalu konsultasikan dengan doktermu sebelum memulai rutinitas olahraga baru.'),
    ],
  ),

  EducationArticle(
    id: 'hidup-istirahat',
    title: 'Istirahat dan Tidur yang Cukup',
    category: 'Gaya Hidup',
    preview:
        'Tidur adalah obat alami yang sering diremehkan. Selama tidur, sistem imun bekerja paling optimal.',
    readMinutes: 2,
    publishedAt: _now.subtract(const Duration(days: 8)),
    relatedIds: ['hidup-makanan', 'hidup-olahraga'],
    content: [
      _p('Tidur adalah obat alami yang sering diremehkan. Selama tidur, sistem imun bekerja paling aktif memperbaiki jaringan tubuh dan melawan infeksi — termasuk bakteri TB.'),
      _h('Berapa Jam yang Dibutuhkan?'),
      _p('Pasien TB dewasa membutuhkan 8–9 jam tidur per malam, lebih dari orang sehat pada umumnya. Ini karena tubuhmu sedang bekerja ekstra keras.'),
      _b('Tidur dan bangun di jam yang sama setiap hari untuk menjaga ritme sirkadian'),
      _b('Hindari layar HP atau TV minimal 1 jam sebelum tidur'),
      _b('Pastikan kamar berventilasi baik dan tidak terlalu panas atau lembab'),
      _b('Tidur siang 20–30 menit jika merasa sangat lelah — ini membantu pemulihan'),
      _q('Kelelahan adalah salah satu gejala TB yang paling mengganggu. Tidak perlu memaksakan diri — istirahat adalah bagian dari penyembuhan, bukan kemalasan.'),
      _p('Jika tidur terasa sulit karena cemas, keringat malam, atau nyeri, ceritakan ke doktermu. Ada solusi untuk setiap masalah ini dan kamu tidak perlu menanggungnya sendiri.'),
    ],
  ),
];

const educationCategories = [
  'Semua',
  'Tentang TB',
  'Obat-obatan',
  'Efek Samping',
  'Gaya Hidup',
  'Motivasi',
  'Bahaya Berhenti',
];
