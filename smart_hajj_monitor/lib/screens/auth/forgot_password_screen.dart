import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';
import '../../utils/dynamic_island.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _identifierController = TextEditingController();

  void _doReset() async {
    final identifier = _identifierController.text.trim();

    if (identifier.isEmpty) {
      DynamicIsland.show(
        context,
        message: 'Username atau nomor WhatsApp tidak boleh kosong.',
        type: IslandType.error,
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.forgotPassword(identifier);

    if (mounted) {
      if (success) {
        DynamicIsland.show(
          context,
          message: 'Sandi baru telah dikirim ke nomor WhatsApp Anda!',
          type: IslandType.success,
        );
        // Kembali ke login setelah beberapa saat
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            context.pop();
          }
        });
      } else {
        DynamicIsland.show(
          context,
          message: 'Akun tidak ditemukan. Periksa kembali input Anda.',
          type: IslandType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final isLoading = context.watch<AuthProvider>().isLoading;
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF1A1D1E);
    final textLightColor = isDark ? const Color(0xFFA0A5AD) : const Color(0xFF6C757D);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppConstants.textDark),
          onPressed: () => context.pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: size.height),
          child: Stack(
            children: [
              // --- HERO HEADER GRADIENT ---
              Container(
                height: size.height * 0.4,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F4C3A), // jemaahPrimary
                      Color(0xFF082C21), // Lebih pekat
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -50,
                      right: -30,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- KONTEN UTAMA ---
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      
                      // Ikon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock_reset_rounded, size: 48, color: AppConstants.jemaahAccent),
                      ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                      
                      const SizedBox(height: 16),
                      
                      Text(
                        'Lupa Sandi',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ).animate().fade().slideY(begin: 0.3),
                      
                      const SizedBox(height: 6),
                      
                      Text(
                        'Masukkan data terdaftar untuk pemulihan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fade(delay: 100.ms).slideY(begin: 0.3),
                      
                      const SizedBox(height: 36),
                      
                      // FORM CARD
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                              blurRadius: 32,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildPremiumTextField(
                              label: 'Username atau Nomor WhatsApp',
                              controller: _identifierController,
                              icon: Icons.person_outline_rounded,
                              hint: 'Masukkan username atau nomor WhatsApp',
                            ).animate().fade(delay: 200.ms).slideX(begin: 0.1),
                            
                            const SizedBox(height: 24),
                            
                            // Tombol Reset
                            SizedBox(
                              height: 56,
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _doReset,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConstants.jemaahPrimary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shadowColor: AppConstants.jemaahPrimary.withOpacity(0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        height: 24, 
                                        width: 24, 
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                                      )
                                    : Text(
                                        'Pulihkan Kata Sandi',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ).animate().fade(delay: 400.ms).scale(curve: Curves.easeOutBack),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF1A1D1E);
    final textLightColor = isDark ? const Color(0xFFA0A5AD) : const Color(0xFF6C757D);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFE2E8F0), width: 1),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.plusJakartaSans(color: textColor, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.plusJakartaSans(color: textLightColor.withOpacity(0.5), fontSize: 14),
              prefixIcon: Icon(icon, color: textLightColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
