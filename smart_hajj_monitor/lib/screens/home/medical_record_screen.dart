import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';

import '../../models/assessment_history.dart';
import '../../utils/constants.dart';

class MedicalRecordScreen extends StatelessWidget {
  final AssessmentHistory record;

  const MedicalRecordScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    Color riskColor;
    Color riskLightColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (record.tingkatRisiko) {
      case 'Tinggi':
        riskColor = AppConstants.statusTinggi;
        riskLightColor = isDark ? riskColor.withOpacity(0.15) : const Color(0xFFFFF0F0);
        break;
      case 'Sedang':
        riskColor = AppConstants.statusSedang;
        riskLightColor = isDark ? riskColor.withOpacity(0.15) : const Color(0xFFFFF9E6);
        break;
      default:
        riskColor = AppConstants.statusRendah;
        riskLightColor = isDark ? riskColor.withOpacity(0.15) : const Color(0xFFF0FDF4);
    }

    String formattedDate = record.tanggal;
    try {
      final dt = DateTime.parse(record.tanggal);
      formattedDate = DateFormat('dd MMMM yyyy, HH:mm').format(dt);
    } catch (_) {}

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 220.0,
            floating: false,
            pinned: true,
            stretch: true,
            elevation: 0,
            backgroundColor: riskColor,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              title: Text(
                'Rekam Medis',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              centerTitle: true,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient Background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          riskColor.withOpacity(0.8),
                          riskColor,
                        ],
                      ),
                    ),
                  ),
                  
                  // Animated Wave Liquid Effect
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: SizedBox(
                      height: 120,
                      child: WaveWidget(
                        config: CustomConfig(
                          gradients: [
                            [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
                            [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
                            [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
                          ],
                          durations: [35000, 19440, 10800],
                          heightPercentages: [0.20, 0.23, 0.25],
                          blur: const MaskFilter.blur(BlurStyle.solid, 10),
                          gradientBegin: Alignment.bottomLeft,
                          gradientEnd: Alignment.topRight,
                        ),
                        waveAmplitude: 20,
                        backgroundColor: Colors.transparent,
                        size: const Size(double.infinity, double.infinity),
                      ),
                    ),
                  ),

                  // Decorative Abstract Shapes (Glassmorphism blobs)
                  Positioned(
                    top: -60,
                    right: -30,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Colors.white.withOpacity(0.3), Colors.transparent],
                          stops: const [0.2, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    left: -40,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Colors.white.withOpacity(0.2), Colors.transparent],
                          stops: const [0.2, 1.0],
                        ),
                      ),
                    ),
                  ),
                  
                  // Blurry overlay for glass effect on the blobs
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(color: Colors.transparent),
                    ),
                  ),

                  // Background Floating Icon
                  Positioned(
                    bottom: 30,
                    right: 30,
                    child: Icon(
                      Icons.monitor_heart_outlined,
                      size: 90,
                      color: Colors.white.withOpacity(0.3),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .moveY(begin: -8, end: 8, duration: 3.seconds, curve: Curves.easeInOutSine)
                     .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2.seconds),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 24),
                // --- HEADER PASIEN ---
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: riskColor.withOpacity(isDark ? 0.05 : 0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: riskColor.withOpacity(0.3), width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: riskLightColor,
                            child: Text(
                              record.namaJemaah.isNotEmpty ? record.namaJemaah[0].toUpperCase() : '?',
                              style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.bold, color: riskColor),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          record.namaJemaah,
                          style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: AppConstants.textDark),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildPillInfo(Icons.calendar_month, '${record.usia} Tahun'),
                            const SizedBox(width: 12),
                            _buildPillInfo(Icons.person, record.jenisKelamin),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Divider(),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Waktu Pemeriksaan', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppConstants.textLight)),
                                const SizedBox(height: 4),
                                Text(formattedDate, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppConstants.textDark)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: riskColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                record.tingkatRisiko.toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fade(duration: 500.ms).slideY(begin: 0.1),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        
                        // --- VITAL SIGNS GRID ---
                        Text('Tanda Vital', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.textDark))
                            .animate().fade(delay: 200.ms).slideX(begin: -0.1),
                        const SizedBox(height: 16),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.4,
                          children: [
                            _buildVitalCard('Suhu Tubuh', '${record.suhuTubuh}°C', Icons.thermostat_outlined, record.suhuTubuh >= 38.0 ? AppConstants.statusTinggi : AppConstants.statusRendah, 300),
                            _buildVitalCard('Batuk', record.batuk, Icons.sick_outlined, record.batuk == 'Ya' ? Colors.orange : AppConstants.statusRendah, 400),
                            _buildVitalCard('Sesak Napas', record.sesakNapas, Icons.air_outlined, record.sesakNapas == 'Ya' ? AppConstants.statusTinggi : AppConstants.statusRendah, 500),
                            _buildVitalCard('Kondisi', record.kondisi, Icons.favorite_border, record.kondisi == 'Sakit Parah' ? AppConstants.statusTinggi : AppConstants.statusRendah, 600),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // --- HASIL ANALISIS ML (PREMIUM CARD) ---
                        Text('Analisis AI & Rekomendasi', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.textDark))
                            .animate().fade(delay: 700.ms).slideX(begin: -0.1),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF1E3A5F), // Dark Navy
                                riskColor.withOpacity(0.8), // Blended with risk color
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(color: riskColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              children: [
                                Positioned(
                                  right: -20,
                                  top: -20,
                                  child: Icon(Icons.psychology, size: 120, color: Colors.white.withOpacity(0.05)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                                            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text('AI Diagnostic System', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                                            ),
                                            child: Text(
                                              '${(record.probabilitas * 100).toStringAsFixed(1)}% Akurat',
                                              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      Text('Rekomendasi Penanganan:', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white.withOpacity(0.7))),
                                      const SizedBox(height: 8),
                                      Text(
                                        record.rekomendasi,
                                        style: GoogleFonts.plusJakartaSans(fontSize: 16, height: 1.5, color: Colors.white, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fade(delay: 800.ms).slideY(begin: 0.1),

                        const SizedBox(height: 32),

                        // --- KELUHAN & RIWAYAT ---
                        Text('Detail Keluhan', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.textDark))
                            .animate().fade(delay: 900.ms).slideX(begin: -0.1),
                        const SizedBox(height: 16),
                        _buildDetailSection('Gejala Utama', record.gejala, Icons.medical_services_outlined).animate().fade(delay: 1000.ms).slideY(begin: 0.1),
                        const SizedBox(height: 16),
                        _buildDetailSection('Riwayat Penyakit Bawaan', record.riwayatPenyakit, Icons.history_outlined).animate().fade(delay: 1100.ms).slideY(begin: 0.1),
                        if (record.lainnya.isNotEmpty && record.lainnya != 'Tidak Ada') ...[
                          const SizedBox(height: 16),
                          _buildDetailSection('Catatan Tambahan', record.lainnya, Icons.note_alt_outlined).animate().fade(delay: 1200.ms).slideY(begin: 0.1),
                        ],
                        
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ],
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillInfo(IconData icon, String text) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppConstants.textLight),
              const SizedBox(width: 6),
              Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppConstants.textDark, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      }
    );
  }

  Widget _buildVitalCard(String title, String value, IconData icon, Color color, int delay) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(isDark ? 0.2 : 0.1), width: 1.5),
            boxShadow: AppConstants.premiumShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppConstants.textLight, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const Spacer(),
              Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ).animate().fade(delay: delay.ms).scale(begin: const Offset(0.9, 0.9));
      }
    );
  }

  Widget _buildDetailSection(String title, String content, IconData icon) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white12 : Colors.grey.withOpacity(0.1)),
            boxShadow: AppConstants.premiumShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppConstants.petugasPrimary.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, size: 18, color: AppConstants.petugasPrimary),
                  ),
                  const SizedBox(width: 12),
                  Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: AppConstants.textDark)),
                ],
              ),
              const SizedBox(height: 16),
              Text(content, style: GoogleFonts.plusJakartaSans(fontSize: 15, color: AppConstants.textDark, height: 1.5)),
            ],
          ),
        );
      }
    );
  }
}
