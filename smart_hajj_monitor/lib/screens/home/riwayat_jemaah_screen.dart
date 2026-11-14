import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../providers/assessment_provider.dart';
import '../../utils/constants.dart';
import 'medical_record_screen.dart';

class RiwayatJemaahScreen extends StatefulWidget {
  const RiwayatJemaahScreen({super.key});

  @override
  State<RiwayatJemaahScreen> createState() => _RiwayatJemaahScreenState();
}

class _RiwayatJemaahScreenState extends State<RiwayatJemaahScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssessmentProvider>().fetchMyAssessments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssessmentProvider>();
    final histories = provider.histories;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Modern background
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: AppConstants.jemaahPrimary,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              title: Text(
                'Riwayat Periksa',
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
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0D47A1), AppConstants.jemaahPrimary],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ).animate(onPlay: (c) => c.repeat()).rotate(duration: 20.seconds),
                  ),
                  Positioned(
                    bottom: -20,
                    left: -20,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: Icon(
                      Icons.history_rounded,
                      size: 80,
                      color: Colors.white.withOpacity(0.2),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .moveY(begin: -5, end: 5, duration: 2.seconds),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: provider.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(child: CircularProgressIndicator(color: AppConstants.jemaahPrimary)),
                  )
                : histories.isEmpty
                    ? _buildEmptyState()
                    : Padding(
                        padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 80),
                        child: Column(
                          children: List.generate(histories.length, (index) {
                            return _buildHistoryCard(context, histories[index], index);
                          }),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).cardColor,
                boxShadow: AppConstants.premiumShadow,
              ),
              child: Icon(Icons.history_edu_rounded, size: 80, color: Colors.blue.shade200),
            ).animate().fade().scale(curve: Curves.easeOutBack, duration: 600.ms),
            const SizedBox(height: 32),
            Text(
              'Belum Ada Riwayat',
              style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppConstants.textDark, letterSpacing: -0.5),
            ).animate().fade(delay: 200.ms).slideY(begin: 0.2),
            const SizedBox(height: 12),
            Text(
              'Yuk periksa kondisi tubuh Anda sekarang juga untuk melihat hasil analisis cerdas AI di sini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(color: AppConstants.textLight, fontSize: 14, height: 1.5),
            ).animate().fade(delay: 300.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, dynamic history, int index) {
    Color riskColor;
    Color gradientLight;
    IconData statusIcon;
    switch (history.tingkatRisiko) {
      case 'Tinggi':
        riskColor = AppConstants.statusTinggi;
        gradientLight = Colors.red.shade300;
        statusIcon = Icons.warning_rounded;
        break;
      case 'Sedang':
        riskColor = AppConstants.statusSedang;
        gradientLight = Colors.orange.shade300;
        statusIcon = Icons.info_rounded;
        break;
      case 'Rendah':
        riskColor = AppConstants.statusRendah;
        gradientLight = Colors.green.shade300;
        statusIcon = Icons.verified_rounded;
        break;
      default:
        riskColor = Colors.blueGrey;
        gradientLight = Colors.blueGrey.shade300;
        statusIcon = Icons.help_outline_rounded;
    }

    String displayRisiko = history.tingkatRisiko;
    if (displayRisiko.toLowerCase() == 'belum diklasifikasi') {
      displayRisiko = 'Proses';
    }

    String formattedDate = history.tanggal;
    try {
      final dt = DateTime.parse(history.tanggal);
      formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (_) {}

    int delay = index > 5 ? 0 : index * 100;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MedicalRecordScreen(record: history)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.white, width: 2),
          boxShadow: AppConstants.premiumShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [gradientLight, riskColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: riskColor.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: Icon(
                statusIcon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 12, color: AppConstants.textLight),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          formattedDate,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppConstants.textLight, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kondisi: ${history.kondisi}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppConstants.textDark, letterSpacing: -0.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    history.gejala,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppConstants.textLight),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: riskColor.withOpacity(0.2)),
                ),
                child: Text(
                  displayRisiko.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(color: riskColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ).animate().fade(delay: delay.ms).slideX(begin: 0.1, curve: Curves.easeOutCubic, duration: 600.ms),
    );
  }

}
