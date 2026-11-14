import 'package:flutter/material.dart';

class AppConstants {
  static bool isDark = false;

  // Base URL Backend API (Production)
  static const String baseUrl = 'https://app-haji-monitoring.my.id';
  // static const String baseUrl = 'http://10.0.2.2:8000'; // Development Local

  // --- GOOGLE SIGN-IN ---
  static const String googleWebClientId = '662792838090-n7vtkh2b35vqnppb6g0ugh3gi79gl1ss.apps.googleusercontent.com';

  // --- TEMA JEMAAH (Spiritual & Tenang) ---
  // Mecca Midnight Green: Hijau gelap khas pintu masjid/ornamen Islam
  static const Color jemaahPrimary = Color(0xFF0F4C3A); 
  // Royal Gold: Aksen elegan mewah
  static const Color jemaahAccent = Color(0xFFD4AF37);
  // Clean Off-White: Warna latar belakang menyerupai kain Ihram
  static Color get jemaahBackground => isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);

  // --- TEMA PETUGAS (Profesional & Siaga) ---
  // Deep Ocean Teal: Biru-hijau otoritas medis
  static const Color petugasPrimary = Color(0xFF1E3A5F);
  // Ice Blue: Bersih dan steril
  static Color get petugasBackground => isDark ? const Color(0xFF121212) : const Color(0xFFF0F4F8);

  // --- WARNA GLOBAL & STATUS ---
  static Color get cardWhite => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  static Color get textDark => isDark ? const Color(0xFFE4E6EB) : const Color(0xFF1A1D1E);
  static Color get textLight => isDark ? const Color(0xFFA0A5AD) : const Color(0xFF6C757D);
  
  // Status Warna (Rendah, Sedang, Tinggi)
  static const Color statusRendah = Color(0xFF28A745);
  static const Color statusSedang = Color(0xFFFFC107);
  static const Color statusTinggi = Color(0xFFDC3545);

  // --- SHADOW STYLE ---
  static List<BoxShadow> get premiumShadow => isDark 
    ? [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 16,
          offset: const Offset(0, 4),
        )
      ]
    : [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}
