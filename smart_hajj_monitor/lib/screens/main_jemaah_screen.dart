import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home/dashboard_jemaah_screen.dart';
import 'profile/profile_screen.dart';
import 'profile/ubah_kata_sandi_screen.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/custom_bottom_bar.dart';

class MainJemaahScreen extends StatefulWidget {
  const MainJemaahScreen({super.key});

  @override
  State<MainJemaahScreen> createState() => _MainJemaahScreenState();
}

class _MainJemaahScreenState extends State<MainJemaahScreen> {
  int _currentIndex = 0;

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
                backgroundColor: AppConstants.jemaahPrimary,
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

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      extendBody: true,
      body: DashboardJemaahScreen(),
    );
  }
}
