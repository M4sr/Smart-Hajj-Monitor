import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';
import '../../utils/dynamic_island.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isBiometricConfigured = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestNotificationPermission();
    });
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  Future<void> _checkBiometricStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('is_biometric_enabled') ?? false;
    final savedUser = prefs.getString('saved_username');
    final savedPass = prefs.getString('saved_password');
    
    if (isEnabled && savedUser != null && savedPass != null) {
      setState(() {
        _isBiometricConfigured = true;
      });
      // Otomatis memicu login biometrik setelah frame pertama selesai digambar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _doBiometricLogin();
      });
    }
  }

  Future<void> _doBiometricLogin() async {
    final auth = LocalAuthentication();
    try {
      final isSupported = await auth.isDeviceSupported() && await auth.canCheckBiometrics;
      if (!isSupported) return;

      final authenticated = await auth.authenticate(
        localizedReason: 'Pindai sidik jari Anda untuk masuk otomatis',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated && mounted) {
        final prefs = await SharedPreferences.getInstance();
        final savedUser = prefs.getString('saved_username');
        final savedPass = prefs.getString('saved_password');
        
        if (savedUser != null && savedPass != null) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final success = await authProvider.login(savedUser, savedPass);
          
          if (success && mounted) {
            final role = authProvider.user?.role.toLowerCase();
            DynamicIsland.show(
              context,
              message: '🎉 Selamat datang kembali, ${authProvider.user?.nama}!',
              type: IslandType.success,
            );
            if (role == 'petugas' || role == 'admin') {
              context.go('/main-petugas');
            } else {
              context.go('/main-jemaah');
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Biometric Login Error: $e");
    }
  }

  void _doLogin() async {
    final provider = Provider.of<AuthProvider>(context, listen: false);
    final success = await provider.login(
      _usernameController.text,
      _passwordController.text,
    );

    if (success) {
      // Simpan kredensial secara lokal untuk autentikasi biometrik selanjutnya
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_username', _usernameController.text);
      await prefs.setString('saved_password', _passwordController.text);

      if (mounted) {
        final role = provider.user?.role.toLowerCase();
        if (role == 'petugas' || role == 'admin') {
          context.go('/main-petugas');
        } else {
          context.go('/main-jemaah');
        }
      }
    } else {
      if (mounted) {
        DynamicIsland.show(
          context,
          message: 'Kredensial tidak valid. Silakan coba lagi.',
          type: IslandType.error,
        );
      }
    }
  }

  void _doGoogleLogin() async {
    final provider = Provider.of<AuthProvider>(context, listen: false);
    final success = await provider.loginWithGoogle();

    if (success && mounted) {
      final role = provider.user?.role.toLowerCase();
      if (role == 'petugas' || role == 'admin') {
        context.go('/main-petugas');
      } else {
        context.go('/main-jemaah');
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Sedikit keabu-abuan agar Card putih menonjol
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: size.height),
          child: Stack(
            children: [
              // --- HERO HEADER GRADIENT ---
              Container(
                height: size.height * 0.45,
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
                    // Ornamen abstrak
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
                    Positioned(
                      top: 100,
                      left: -50,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppConstants.jemaahAccent.withOpacity(0.1),
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
                      const SizedBox(height: 40),
                      
                      // Logo & Judul (Berada di atas area gelap)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.health_and_safety_rounded, size: 48, color: AppConstants.jemaahAccent),
                      ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                      
                      const SizedBox(height: 24),
                      
                      Text(
                        'Selamat Datang',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ).animate().fade().slideY(begin: 0.3),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        'Smart Hajj & Umrah Monitor',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ).animate().fade(delay: 100.ms).slideY(begin: 0.3),
                      
                      const SizedBox(height: 48),
                      
                      // FORM CARD (Melayang di antara gelap dan terang)
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
                              label: 'Username',
                              controller: _usernameController,
                              icon: Icons.person_outline_rounded,
                            ).animate().fade(delay: 200.ms).slideX(begin: 0.1),
                            
                            const SizedBox(height: 20),
                            
                            _buildPremiumTextField(
                              label: 'Kata Sandi',
                              controller: _passwordController,
                              icon: Icons.lock_outline_rounded,
                              isPassword: true,
                            ).animate().fade(delay: 300.ms).slideX(begin: 0.1),
                            
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () => context.push('/forgot-password'),
                                child: Text(
                                  'Lupa Kata Sandi?',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppConstants.jemaahPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ).animate().fade(delay: 350.ms).slideX(begin: 0.1),
                            
                            const SizedBox(height: 24),
                            
                            // Tombol Login
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: isLoading ? null : _doLogin,
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
                                              'Masuk ke Akun',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                if (_isBiometricConfigured) ...[
                                  const SizedBox(width: 12),
                                  Container(
                                    height: 56,
                                    width: 56,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                                        width: 1,
                                      ),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.fingerprint_rounded, color: AppConstants.jemaahAccent, size: 28),
                                      onPressed: isLoading ? null : _doBiometricLogin,
                                    ),
                                  ),
                                ],
                              ],
                            ).animate().fade(delay: 400.ms).scale(curve: Curves.easeOutBack),

                            const SizedBox(height: 24),
                            
                            // Divider
                            Row(
                              children: [
                                Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.grey.shade300)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text('Atau', style: GoogleFonts.plusJakartaSans(color: textLightColor, fontSize: 14)),
                                ),
                                Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.grey.shade300)),
                              ],
                            ).animate().fade(delay: 450.ms),

                            const SizedBox(height: 24),

                            // Google Login Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton.icon(
                                onPressed: isLoading ? null : _doGoogleLogin,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textColor,
                                  side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                icon: Image.asset('assets/images/google_logo.png', height: 24, width: 24),
                                label: Text(
                                  'Masuk dengan Google',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ).animate().fade(delay: 480.ms).slideY(begin: 0.1),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Daftar Link
                      Center(
                        child: GestureDetector(
                          onTap: () => context.push('/register'),
                          child: RichText(
                            text: TextSpan(
                              text: 'Belum punya akun? ',
                              style: GoogleFonts.plusJakartaSans(color: textLightColor, fontSize: 15),
                              children: [
                                TextSpan(
                                  text: 'Daftar Sekarang',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fade(delay: 500.ms),
                      const SizedBox(height: 40),
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
    bool isPassword = false,
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
            color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF8FAFC), // Latar yang sangat halus agar beda dari Card
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFE2E8F0), width: 1),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && !_isPasswordVisible,
            style: GoogleFonts.plusJakartaSans(color: textColor, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Masukkan $label',
              hintStyle: GoogleFonts.plusJakartaSans(color: textLightColor.withOpacity(0.5), fontSize: 14),
              prefixIcon: Icon(icon, color: textLightColor),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: textLightColor,
                      ),
                      onPressed: () {
                        setState(() => _isPasswordVisible = !_isPasswordVisible);
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
