import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../providers/assessment_provider.dart';
import '../../utils/constants.dart';
import '../../utils/dynamic_island.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final assessmentProvider = context.watch<AssessmentProvider>();
    final result = assessmentProvider.lastResult;
    final lastInput = assessmentProvider.lastInput;

    if (result == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Hasil Analisis'),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Tidak ada data analisis terbaru.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textLight,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/main-jemaah'),
                child: const Text('Kembali ke Dashboard'),
              )
            ],
          ),
        ),
      );
    }

    // Determine colors and layouts based on risk level (Adaptive for Dark Mode)
    Color riskColor;
    Color lightBgColor;
    IconData riskIcon;
    String riskTitle;
    String riskDescription;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (result.tingkatRisiko) {
      case 'Tinggi':
        riskColor = const Color(0xFFD32F2F); // Solid dark red for high contrast
        lightBgColor = isDark ? riskColor.withOpacity(0.15) : const Color(0xFFFFEBEE); // Soft pinkish red
        riskIcon = Icons.dangerous_rounded;
        riskTitle = 'Risiko Tinggi';
        riskDescription = 'AI mendeteksi tingkat risiko kesehatan yang tinggi. Harap segera beristirahat dan hubungi petugas medis.';
        break;
      case 'Sedang':
        riskColor = const Color(0xFFE65100); // Solid dark orange
        lightBgColor = isDark ? riskColor.withOpacity(0.15) : const Color(0xFFFFF3E0); // Soft orange-yellow
        riskIcon = Icons.warning_amber_rounded;
        riskTitle = 'Risiko Sedang';
        riskDescription = 'AI mendeteksi tingkat risiko kesehatan sedang. Disarankan untuk membatasi aktivitas fisik berat.';
        break;
      default:
        riskColor = const Color(0xFF1B5E20); // Solid dark green
        lightBgColor = isDark ? riskColor.withOpacity(0.15) : const Color(0xFFE8F5E9); // Soft light green
        riskIcon = Icons.check_circle_rounded;
        riskTitle = 'Risiko Rendah';
        riskDescription = 'Kondisi kesehatan Anda dinilai baik dan stabil untuk saat ini. Tetap jaga kondisi tubuh.';
    }

    final double confidence = result.probabilitas * 100;
    final textColorDark = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B); // Slate 800 for high contrast
    final textColorLight = isDark ? const Color(0xFFA0A5AD) : const Color(0xFF475569); // Slate 600
    final appBgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: appBgColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<AssessmentProvider>().fetchMyAssessments();
        },
        color: riskColor,
        backgroundColor: Colors.white,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverAppBar(
              expandedHeight: 240.0,
              pinned: true,
              stretch: true,
              backgroundColor: riskColor,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => context.go('/main-jemaah'),
              ),
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [
                  StretchMode.zoomBackground,
                ],
                background: Container(
                  color: riskColor,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40), // Push down below appbar
                      Icon(riskIcon, size: 64, color: Colors.white)
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(begin: const Offset(1, 1), end: const Offset(1.08, 1.08), duration: 1.5.seconds),
                      const SizedBox(height: 12),
                      Text(
                        riskTitle.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tingkat Keyakinan ML: ${confidence.toStringAsFixed(0)}%',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Explanation Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppConstants.premiumShadow,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, color: riskColor, size: 28),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status Deteksi',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: textColorDark,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  riskDescription,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: textColorLight,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fade(duration: 400.ms).slideY(begin: 0.05),
                    
                    const SizedBox(height: 16),
                    
                    // Medical Recommendation Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: lightBgColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: riskColor.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.assignment_turned_in_rounded, color: riskColor, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                'Rekomendasi Petugas Medis',
                                style: GoogleFonts.plusJakartaSans(
                                  color: riskColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              HealthMascot(tingkatRisiko: result.tingkatRisiko),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  result.rekomendasi,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A), // Dark slate for max readability
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          // SOS button for High Risk
                          if (result.tingkatRisiko == 'Tinggi') ...[
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFC62828), // Dark red
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 2,
                                ),
                                icon: const Icon(Icons.emergency_share_rounded, size: 22)
                                    .animate(onPlay: (c) => c.repeat())
                                    .shake(),
                                label: Text(
                                  'PANGGIL PETUGAS SEKARANG (SOS)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                onPressed: () {
                                  HapticFeedback.heavyImpact();
                                  DynamicIsland.show(
                                    context,
                                    message: '🚨 Sinyal SOS Terkirim via Halaman Hasil!',
                                    type: IslandType.error,
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ).animate().fade(delay: 150.ms, duration: 400.ms).slideY(begin: 0.05),

                    const SizedBox(height: 20),

                    // Submitted Metrics Section
                    if (lastInput != null) ...[
                      Text(
                        'Ringkasan Data yang Anda Laporkan:',
                        style: GoogleFonts.plusJakartaSans(
                          color: textColorDark,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.6,
                        children: [
                          _buildMetricTile(
                            icon: Icons.thermostat_rounded,
                            iconColor: Colors.red.shade700,
                            label: 'Suhu Tubuh',
                            value: '${lastInput['suhu_tubuh']}°C',
                            isDanger: (lastInput['suhu_tubuh'] as double) >= 38.0,
                          ),
                          _buildMetricTile(
                            icon: Icons.healing_rounded,
                            iconColor: Colors.blue.shade700,
                            label: 'Kondisi Fisik',
                            value: lastInput['kondisi'] ?? 'Sehat',
                            isDanger: lastInput['kondisi'] == 'Sakit Parah',
                          ),
                          _buildMetricTile(
                            icon: Icons.coronavirus_rounded,
                            iconColor: Colors.purple.shade700,
                            label: 'Gejala Utama',
                            value: lastInput['gejala'] ?? 'Tidak Ada',
                            isDanger: lastInput['gejala'] != 'Tidak Ada',
                          ),
                          _buildMetricTile(
                            icon: Icons.medical_information_rounded,
                            iconColor: Colors.teal.shade700,
                            label: 'Riwayat Penyakit',
                            value: lastInput['riwayat_penyakit'] ?? 'Tidak Ada',
                            isDanger: lastInput['riwayat_penyakit'] != 'Tidak Ada',
                          ),
                          _buildMetricTile(
                            icon: Icons.air_rounded,
                            iconColor: Colors.orange.shade800,
                            label: 'Sesak Napas',
                            value: lastInput['sesak_napas'] == 'Ya' ? 'YA' : 'TIDAK',
                            isDanger: lastInput['sesak_napas'] == 'Ya',
                          ),
                          _buildMetricTile(
                            icon: Icons.personal_injury_rounded,
                            iconColor: Colors.brown.shade700,
                            label: 'Keluhan Lain',
                            value: lastInput['lainnya'] ?? 'Tidak Ada',
                            isDanger: lastInput['lainnya'] != null && lastInput['lainnya'] != 'Tidak Ada',
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Bottom Action Buttons
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.jemaahPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 1,
                            ),
                            onPressed: () => context.go('/main-jemaah'),
                            child: Text(
                              'KEMBALI KE DASHBOARD',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.primary,
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => context.push('/riwayat-jemaah'),
                            child: Text(
                              'LIHAT RIWAYAT KESEHATAN',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isDanger,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDanger 
                ? Colors.red.shade300 
                : (isDark ? Colors.white10 : Colors.grey.shade200),
              width: isDanger ? 1.5 : 1,
            ),
            boxShadow: AppConstants.premiumShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: iconColor, size: 22),
                  if (isDanger)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isDark ? Colors.red.shade700 : Colors.red.shade200),
                      ),
                      child: Text(
                        'Perlu Cek',
                        style: GoogleFonts.plusJakartaSans(
                          color: isDark ? Colors.red.shade200 : Colors.red.shade800,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.plusJakartaSans(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        );
      }
    );
  }
}

class HealthMascot extends StatelessWidget {
  final String tingkatRisiko;
  const HealthMascot({super.key, required this.tingkatRisiko});

  @override
  Widget build(BuildContext context) {
    Color mascotColor;
    IconData faceIcon;
    List<Widget> mascotDetails = [];
    Widget handsWidget;
    Widget headAccessory = const SizedBox.shrink();

    switch (tingkatRisiko) {
      case 'Tinggi':
        mascotColor = const Color(0xFFD32F2F);
        faceIcon = Icons.sentiment_very_dissatisfied_rounded;
        
        // Siren lights on top
        headAccessory = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.blueAccent),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 200.ms),
            const SizedBox(width: 12),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 200.ms),
          ],
        );

        // Flashing warning badge on chest
        mascotDetails.add(
          const Icon(Icons.add_circle, color: Colors.white, size: 14)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(1, 1), end: const Offset(1.25, 1.25), duration: 400.ms)
        );

        // Frantic waving hands
        handsWidget = Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(width: 5, height: 14, decoration: BoxDecoration(color: mascotColor, borderRadius: BorderRadius.circular(3)))
                .animate(onPlay: (c) => c.repeat(reverse: true)).rotate(begin: -0.6, end: 0.6, duration: 200.ms),
            const Spacer(),
            Container(width: 5, height: 14, decoration: BoxDecoration(color: mascotColor, borderRadius: BorderRadius.circular(3)))
                .animate(onPlay: (c) => c.repeat(reverse: true)).rotate(begin: 0.6, end: -0.6, duration: 200.ms),
          ],
        );
        break;

      case 'Sedang':
        mascotColor = const Color(0xFFE65100);
        faceIcon = Icons.sentiment_neutral_rounded;

        // Sweat droplet on side
        headAccessory = Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: const Icon(Icons.water_drop_rounded, color: Colors.blueAccent, size: 12)
                .animate(onPlay: (c) => c.repeat())
                .slideY(begin: -0.2, end: 0.2, duration: 1.5.seconds)
                .fade(duration: 1.5.seconds),
          ),
        );

        // Warning badge on chest
        mascotDetails.add(
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 12)
        );

        // Slow breathing hands
        handsWidget = Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(width: 5, height: 14, decoration: BoxDecoration(color: mascotColor, borderRadius: BorderRadius.circular(3))),
            const Spacer(),
            Container(width: 5, height: 14, decoration: BoxDecoration(color: mascotColor, borderRadius: BorderRadius.circular(3))),
          ],
        ).animate(onPlay: (c) => c.repeat(reverse: true))
         .scaleY(begin: 0.85, end: 1.15, duration: 1.seconds);
        break;

      default: // Rendah
        mascotColor = const Color(0xFF1B5E20);
        faceIcon = Icons.sentiment_very_satisfied_rounded;

        // Heart pulsing on chest
        mascotDetails.add(
          const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 12)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 600.ms)
        );

        // Waving hand
        handsWidget = Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(width: 5, height: 14, decoration: BoxDecoration(color: mascotColor, borderRadius: BorderRadius.circular(3)))
                .animate(onPlay: (c) => c.repeat(reverse: true)).rotate(begin: -0.4, end: 0.4, duration: 500.ms),
            const Spacer(),
            Container(width: 5, height: 14, decoration: BoxDecoration(color: mascotColor, borderRadius: BorderRadius.circular(3))),
          ],
        );
    }

    return SizedBox(
      width: 76,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background soft glow
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: mascotColor.withValues(alpha: 0.12),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 2.seconds),

          // Siren/accessory layer
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: headAccessory,
          ),

          // Waving/breathing hands
          Positioned(
            left: 2,
            right: 2,
            bottom: 18,
            child: handsWidget,
          ),

          // Main Capsule Body
          Positioned(
            bottom: 8,
            child: Container(
              width: 48,
              height: 62,
              decoration: BoxDecoration(
                color: mascotColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: mascotColor.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Face Screen
                  Container(
                    width: 36,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Icon(faceIcon, color: mascotColor, size: 20),
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Chest accessory
                  ...mascotDetails,
                ],
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .slideY(begin: 0, end: -0.06, duration: 1.seconds),
        ],
      ),
    );
  }
}
