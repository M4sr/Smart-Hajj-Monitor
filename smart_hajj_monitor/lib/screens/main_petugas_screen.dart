import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home/dashboard_petugas_screen.dart';
import 'home/directory_jemaah_screen.dart';
import 'analytics/medical_analytics_screen.dart';
import 'sos/sos_map_screen.dart';
import 'profile/profile_screen.dart';
import 'profile/ubah_kata_sandi_screen.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/custom_bottom_bar.dart';

class MainPetugasScreen extends StatefulWidget {
  const MainPetugasScreen({super.key});

  @override
  State<MainPetugasScreen> createState() => _MainPetugasScreenState();
}

class _MainPetugasScreenState extends State<MainPetugasScreen> {
  int _currentIndex = 0;
  bool _sosListVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTemporaryPassword();
    });
  }

  void _checkTemporaryPassword() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.isTemporaryPassword == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Theme.of(context).cardColor,
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.amber,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Sandi Sementara',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textDark,
                ),
              ),
            ],
          ),
          content: Text(
            'Anda masuk menggunakan kata sandi sementara dari WhatsApp. Untuk keamanan akun Anda, silakan ubah kata sandi sekarang juga.',
            style: GoogleFonts.plusJakartaSans(
              color: AppConstants.textLight,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                'Nanti Saja',
                style: GoogleFonts.plusJakartaSans(
                  color: AppConstants.textLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UbahKataSandiScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.petugasPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Ubah Sekarang',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  List<Widget> get _screens => [
    const DashboardPetugasScreen(),
    const MedicalAnalyticsScreen(),
    const DirectoryJemaahScreen(),
    SosMapScreen(
      onListVisibilityChanged: (visible) =>
          setState(() => _sosListVisible = visible),
    ),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AnimatedSlide(
        offset: _sosListVisible ? const Offset(0, 1.5) : Offset.zero,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
        child: AnimatedOpacity(
          opacity: _sosListVisible ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 280),
          child: CustomBottomBar(
            currentIndex: _currentIndex,
            activeColor: AppConstants.petugasPrimary,
            onTap: (index) => setState(() => _currentIndex = index),
            items: [
              CustomBottomBarItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard_rounded,
                label: 'Pantauan',
              ),
              CustomBottomBarItem(
                icon: Icons.pie_chart_outline,
                activeIcon: Icons.pie_chart_rounded,
                label: 'Analitik',
              ),
              CustomBottomBarItem(
                icon: Icons.people_alt_outlined,
                activeIcon: Icons.people_alt_rounded,
                label: 'Jemaah',
              ),
              CustomBottomBarItem(
                icon: Icons.sos_outlined,
                activeIcon: Icons.sos_rounded,
                label: 'Peta SOS',
              ),
              CustomBottomBarItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
