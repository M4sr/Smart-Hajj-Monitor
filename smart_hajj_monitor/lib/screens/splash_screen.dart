import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkInitialRoute();
  }

  Future<void> _checkInitialRoute() async {
    // Memberikan waktu sedikit agar animasi splash screen terlihat
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    if (!hasSeenOnboarding) {
      // Jika belum pernah lihat onboarding
      context.go('/onboarding');
      return;
    }

    // Jika sudah onboarding, coba auto login
    final authProvider = context.read<AuthProvider>();
    final isLoggedIn = await authProvider.tryAutoLogin();

    if (!mounted) return;

    if (isLoggedIn) {
      final user = authProvider.user;
      if (user != null) {
        if (user.role.toLowerCase() == 'petugas' || user.role.toLowerCase() == 'admin') {
          context.go('/main-petugas');
        } else {
          context.go('/main-jemaah');
        }
      } else {
        context.go('/login');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : AppConstants.jemaahPrimary;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 80,
                height: 80,
              ),
            ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 32),
            Text(
              'Smart Hajj Monitor',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ).animate().fade(delay: 400.ms).slideY(begin: 0.2),
            const SizedBox(height: 16),
            Text(
              'Pendamping Ibadah Haji Anda',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white70,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ).animate().fade(delay: 600.ms),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ).animate().fade(delay: 800.ms),
          ],
        ),
      ),
    );
  }
}
