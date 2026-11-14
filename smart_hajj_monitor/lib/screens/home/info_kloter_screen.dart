import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';

class InfoKloterScreen extends StatelessWidget {
  const InfoKloterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final username = user?.username ?? '';

    // Deterministic mock data mapping based on username
    final Map<String, dynamic> kloterInfo;
    if (username == 'jemaah1') {
      kloterInfo = {
        'kloter': 'Kloter JKS-12',
        'embarkasi': 'Embarkasi Jakarta - Bekasi',
        'ketua': 'Ust. H. Ahmad Fauzi',
        'kontak': '+966 50 123 4567',
        'hotel': 'Makkah Clock Royal Tower',
        'bus': '10:30 WAS (ke Masjidil Haram)',
      };
    } else if (username == 'jemaah2') {
      kloterInfo = {
        'kloter': 'Kloter SUB-05',
        'embarkasi': 'Embarkasi Surabaya',
        'ketua': 'Ust. KH. Mustofa Bisri',
        'kontak': '+966 53 987 6543',
        'hotel': 'Dar Al Ghufran Hotel',
        'bus': '11:15 WAS (ke Masjidil Haram)',
      };
    } else {
      kloterInfo = {
        'kloter': 'Kloter KJT-08',
        'embarkasi': 'Embarkasi Kertajati - Jawa Barat',
        'ketua': 'Ust. M. Ridwan',
        'kontak': '+966 55 555 1234',
        'hotel': 'Pullman ZamZam Makkah',
        'bus': '12:00 WAS (ke Masjidil Haram)',
      };
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Info Kloter',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF8E24AA), // Purple gradient flavor
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFAB47BC), Color(0xFF4A148C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Kloter Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFAB47BC), Color(0xFF4A148C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8E24AA).withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.groups_rounded, color: Colors.white, size: 40),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kloterInfo['kloter']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          kloterInfo['embarkasi']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fade().scale(curve: Curves.easeOutBack),
            
            const SizedBox(height: 32),
            
            Text(
              'Detail Rombongan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppConstants.textDark,
              ),
            ).animate().fade(delay: 200.ms).slideX(begin: -0.1),
            const SizedBox(height: 16),
            
            _buildInfoCard(
              title: 'Ketua Rombongan',
              value: kloterInfo['ketua']!,
              icon: Icons.person_rounded,
              color: Colors.blue,
              delay: 300,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              title: 'Kontak Darurat',
              value: kloterInfo['kontak']!,
              icon: Icons.phone_in_talk_rounded,
              color: Colors.green,
              delay: 400,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              title: 'Lokasi Hotel Makkah',
              value: kloterInfo['hotel']!,
              icon: Icons.hotel_rounded,
              color: Colors.orange,
              delay: 500,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              title: 'Jadwal Bus Terdekat',
              value: kloterInfo['bus']!,
              icon: Icons.directions_bus_rounded,
              color: Colors.redAccent,
              delay: 600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required int delay,
  }) {
    return Builder(
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppConstants.premiumShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppConstants.textLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    ).animate().fade(delay: delay.ms).slideX(begin: 0.1);
  }
}
