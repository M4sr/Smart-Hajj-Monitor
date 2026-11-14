import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';
import '../../utils/dynamic_island.dart';

class AutentikasiBiometrikScreen extends StatefulWidget {
  const AutentikasiBiometrikScreen({super.key});

  @override
  State<AutentikasiBiometrikScreen> createState() => _AutentikasiBiometrikScreenState();
}

class _AutentikasiBiometrikScreenState extends State<AutentikasiBiometrikScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isSupported = false;
  bool _isEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSupportAndLoadPreferences();
  }

  Future<void> _checkSupportAndLoadPreferences() async {
    try {
      final isDeviceSupported = await _auth.isDeviceSupported();
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _isSupported = isDeviceSupported && canCheckBiometrics;
        _isEnabled = prefs.getBool('is_biometric_enabled') ?? false;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Biometric Check Error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (!_isSupported) {
      DynamicIsland.show(
        context,
        message: 'Perangkat tidak mendukung autentikasi biometrik.',
        type: IslandType.error,
      );
      return;
    }

    if (value) {
      // Prompt biometric authentication to enable it
      try {
        final authenticated = await _auth.authenticate(
          localizedReason: 'Pindai sidik jari Anda untuk mengaktifkan login biometrik',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );

        if (authenticated) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_biometric_enabled', true);
          setState(() => _isEnabled = true);
          
          if (mounted) {
            DynamicIsland.show(
              context,
              message: '🔒 Login Sidik Jari berhasil diaktifkan!',
              type: IslandType.success,
            );
          }
        }
      } catch (e) {
        debugPrint("Biometric Auth Error: $e");
        if (mounted) {
          DynamicIsland.show(
            context,
            message: 'Autentikasi gagal. Gagal mengaktifkan biometrik.',
            type: IslandType.error,
          );
        }
      }
    } else {
      // Disable biometric
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_biometric_enabled', false);
      setState(() => _isEnabled = false);
      
      if (mounted) {
        DynamicIsland.show(
          context,
          message: '🔓 Login Sidik Jari dinonaktifkan.',
          type: IslandType.info,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF1A1D1E);
    final textLightColor = isDark ? const Color(0xFFA0A5AD) : const Color(0xFF6C757D);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Autentikasi Biometrik',
          style: GoogleFonts.plusJakartaSans(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        iconTheme: IconThemeData(color: textColor),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.withOpacity(0.1), height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  
                  // Visual Fingerprint pulsing
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ripple circles
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppConstants.jemaahPrimary.withOpacity(0.05),
                          ),
                        ).animate(onPlay: (c) => c.repeat(reverse: true))
                         .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.2, 1.2), duration: 2.seconds)
                         .fade(begin: 0.8, end: 0.1),
                        
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (_isEnabled ? AppConstants.jemaahPrimary : Colors.grey).withOpacity(0.1),
                            boxShadow: _isEnabled
                                ? [
                                    BoxShadow(
                                      color: AppConstants.jemaahPrimary.withOpacity(0.2),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : [],
                          ),
                          child: Icon(
                            Icons.fingerprint_rounded,
                            size: 60,
                            color: _isEnabled ? AppConstants.jemaahPrimary : Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  Text(
                    _isEnabled ? 'Biometrik Aktif' : 'Biometrik Nonaktif',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ).animate().fadeIn(duration: 400.ms),

                  const SizedBox(height: 12),

                  Text(
                    _isSupported
                        ? 'Masuk ke aplikasi Smart Hajj Monitor lebih cepat dan aman menggunakan sidik jari atau pengenalan wajah Anda.'
                        : 'Perangkat Anda tidak mendukung atau belum mengonfigurasi autentikasi biometrik.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: textLightColor,
                      height: 1.5,
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 48),

                  // Card Setting Switch
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppConstants.premiumShadow,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.security_rounded,
                              color: _isEnabled ? AppConstants.jemaahPrimary : textLightColor,
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Login Sidik Jari',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Aktifkan verifikasi biometrik',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: textLightColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch(
                          value: _isEnabled,
                          onChanged: _isSupported ? _toggleBiometric : null,
                          activeColor: AppConstants.jemaahPrimary,
                        ),
                      ],
                    ),
                  ).animate().fade(delay: 300.ms).slideY(begin: 0.1),
                ],
              ),
            ),
    );
  }
}
