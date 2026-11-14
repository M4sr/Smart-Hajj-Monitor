import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../utils/constants.dart';

class PanduanIbadahScreen extends StatelessWidget {
  const PanduanIbadahScreen({super.key});

  static const List<Map<String, dynamic>> _panduanData = [
    {
      'title': 'Niat Haji & Umrah',
      'subtitle': 'Lafadz niat ihram dari miqat',
      'icon': Icons.mosque_rounded,
      'arabic': 'لَبَّيْكَ اللَّهُمَّ حَجًّا وَعُمْرَةً',
      'latin': 'Labbaykallahumma Hajjan wa \'Umratan',
      'translation': 'Aku penuhi panggilan-Mu ya Allah untuk berhaji dan berumrah.',
      'explanation': 'Niat ini dibaca saat Anda telah mengenakan pakaian ihram dan berada di Miqat sebelum memasuki kota Mekkah.',
      'steps': [
        'Mandi sunnah ihram dan berwudhu sebelum memakai pakaian ihram.',
        'Mengenakan pakaian ihram dengan benar (2 lembar kain tanpa jahitan bagi laki-laki).',
        'Melakukan shalat sunnah ihram 2 rakaat.',
        'Membaca niat ihram haji & umrah di Miqat.',
        'Mulai membaca kalimat Talbiyah sepanjang perjalanan.'
      ]
    },
    {
      'title': 'Doa Tawaf',
      'subtitle': 'Doa setiap putaran tawaf di Ka\'bah',
      'icon': Icons.sync_rounded,
      'arabic': 'سُبْحَانَ اللهِ وَالْحَمْدُ للهِ وَلَا إِلَهَ إِلَّا اللهُ وَاللهُ أَكْبَرُ وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللهِ الْعَلِيِّ الْعَظِيْمِ',
      'latin': 'Subhanallah walhamdulillah wa la ilaha illallah wallahu akbar wa la hawla wa la quwwata illa billahil \'aliyyil \'adzim',
      'translation': 'Maha Suci Allah, segala puji bagi Allah, tiada Tuhan selain Allah, Allah Maha Besar, dan tiada daya serta kekuatan kecuali dengan pertolongan Allah Yang Maha Tinggi lagi Maha Agung.',
      'explanation': 'Dibaca sepanjang melakukan putaran mengelilingi Ka\'bah sebanyak 7 kali, dimulai dari Hajar Aswad.',
      'steps': [
        'Masuk ke area Masjidil Haram dengan mendahulukan kaki kanan dan membaca doa masuk masjid.',
        'Menghadap Hajar Aswad, memberi isyarat (istilam) dengan tangan kanan dan mengecupnya (atau melambaikan tangan) sambil membaca Bismillahi Allahu Akbar.',
        'Memulai putaran tawaf dengan posisi Ka\'bah di sebelah kiri.',
        'Membaca doa/dzikir ini selama berjalan mengitari Ka\'bah.',
        'Di antara Rukun Yamani dan Hajar Aswad, disunnahkan membaca doa Sapujagat: Rabbana atina fid-dunya hasanah...'
      ]
    },
    {
      'title': 'Doa Sa\'i',
      'subtitle': 'Doa perjalanan Shafa dan Marwah',
      'icon': Icons.directions_walk_rounded,
      'arabic': 'أَبْدَأُ بِمَا بَدَأَ اللهُ بِهِ وَرَسُولُهُ. إِنَّ الصَّفَا وَالْمَرْوَةَ مِنْ شَعَائِرِ اللَّهِ',
      'latin': 'Abda\'u bima bada\'allahu bihi wa rasuluh. Innas-shafa wal-marwata min sya\'a\'irillah.',
      'translation': 'Aku memulai dengan apa yang Allah dan Rasul-Nya memulai dengannya. Sesungguhnya Shafa dan Marwah adalah sebagian dari syiar-syiar Allah.',
      'explanation': 'Dibaca ketika mendaki bukit Shafa sebelum memulai perjalanan Sa\'i menuju bukit Marwah.',
      'steps': [
        'Menuju ke bukit Shafa setelah menyelesaikan shalat sunnah Tawaf dan minum air Zamzam.',
        'Mendaki bukit Shafa, menghadap ke arah Ka\'bah, lalu melafalkan doa pembuka ini.',
        'Berjalan kaki menuju bukit Marwah. Bagi laki-laki disunnahkan lari-lari kecil di antara pilar hijau.',
        'Sesampainya di bukit Marwah, menghadap kiblat dan berdoa. Ini dihitung 1 putaran.',
        'Ulangi perjalanan hingga selesai 7 putaran (berakhir di bukit Marwah).'
      ]
    },
    {
      'title': 'Doa Wukuf',
      'subtitle': 'Dzikir dan doa utama di Arafah',
      'icon': Icons.wb_sunny_rounded,
      'arabic': 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
      'latin': 'La ilaha illallah wahdahu la syarika lah, lahul mulku wa lahul hamdu, wa huwa \'ala kulli syai\'in qadir.',
      'translation': 'Tidak ada Tuhan selain Allah Yang Maha Esa, tidak ada sekutu bagi-Nya. Bagi-Nya segala kekuasaan dan bagi-Nya segala puji. Dan Dia Maha Kuasa atas segala sesuatu.',
      'explanation': 'Merupakan inti ibadah haji, dibaca pada tanggal 9 Dzulhijjah setelah matahari tergelincir hingga matahari terbenam.',
      'steps': [
        'Mendengarkan khutbah wukuf di tenda Arafah.',
        'Melaksanakan shalat Jamak Qashar Zhuhur dan Ashar di awal waktu.',
        'Memperbanyak doa, dzikir, membaca Al-Quran, dan memohon ampunan secara mandiri.',
        'Dianjurkan menghadap kiblat dan mengangkat kedua tangan saat berdoa.',
        'Bertahan di Arafah hingga matahari terbenam (waktu Maghrib).'
      ]
    },
    {
      'title': 'Tata Cara Melontar Jumrah',
      'subtitle': 'Panduan melontar di Mina',
      'icon': Icons.sports_handball_rounded,
      'arabic': 'اللَّهُ أَكْبَرُ',
      'latin': 'Allahu Akbar',
      'translation': 'Allah Maha Besar',
      'explanation': 'Wajib haji berupa melontar batu kecil ke tiang Jumrah sebagai simbol perlawanan terhadap bisikan setan.',
      'steps': [
        'Mengumpulkan kerikil (sebanyak 7 atau 21 butir) di Muzdalifah atau Mina.',
        'Melontar Jumrah Aqabah saja pada tanggal 10 Dzulhijjah (Hari Raya Idul Adha) sebanyak 7 kali lemparan.',
        'Melontar tiga Jumrah (Ula, Wustha, dan Aqabah) berurutan masing-masing 7 kali pada hari-hari Tasyriq (11, 12, dan 13 Dzulhijjah).',
        'Setiap lemparan batu harus mengenai lubang marmer jumrah.',
        'Membaca takbir "Allahu Akbar" di setiap lemparan batu.'
      ]
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Panduan Ibadah',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFF57F17),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFA726), Color(0xFFE65100)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        itemCount: _panduanData.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final data = _panduanData[index];
          return _buildPanduanCard(
            context: context,
            title: data['title']!,
            subtitle: data['subtitle']!,
            icon: data['icon'] as IconData,
            delay: 200 + (index * 100),
            onTap: () {
              context.push('/panduan-detail', extra: {
                'index': index,
                'items': _panduanData,
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildPanduanCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required int delay,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppConstants.premiumShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFFE65100).withOpacity(0.2) : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: const Color(0xFFF57F17), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppConstants.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
              ],
            ),
          ),
        ),
      ),
    ).animate().fade(delay: delay.ms).slideY(begin: 0.2);
  }
}
