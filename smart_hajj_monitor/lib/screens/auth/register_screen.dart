import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';
import '../../utils/dynamic_island.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _namaController = TextEditingController();
  final _noHpController = TextEditingController();
  
  bool _isPasswordVisible = false;
  String _usia = '30';
  String _jenisKelamin = 'Laki-laki';
  String _role = 'Jemaah';

  void _doRegister() async {
    if (_usernameController.text.isEmpty || _passwordController.text.length < 6) {
       DynamicIsland.show(context, message: 'Isi form dengan benar. Password min 6 karakter.', type: IslandType.error);
       return;
    }

    final provider = Provider.of<AuthProvider>(context, listen: false);
    
    final data = {
      "username": _usernameController.text,
      "password": _passwordController.text,
      "nama": _namaController.text,
      "usia": int.tryParse(_usia) ?? 0,
      "jenis_kelamin": _jenisKelamin,
      "no_hp": _noHpController.text,
      "role": _role,
    };

    final success = await provider.register(data);
    
    if (success && mounted) {
      DynamicIsland.show(context, message: 'Pendaftaran berhasil! Silakan login.', type: IslandType.success);
      context.go('/login');
    } else {
      if (mounted) {
        DynamicIsland.show(context, message: 'Pendaftaran Gagal. Username mungkin sudah terpakai.', type: IslandType.error);
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: size.height),
          child: Stack(
            children: [
              // --- HERO HEADER GRADIENT ---
              Container(
                height: size.height * 0.40,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Color(0xFF0F4C3A),
                      Color(0xFF082C21),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: SafeArea(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        onPressed: () => context.go('/login'),
                      ),
                    ),
                  ),
                ),
              ),

              // --- KONTEN UTAMA ---
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      
                      Text(
                        'Buat Akun Baru',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ).animate().fade().slideY(begin: 0.3),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        'Lengkapi data untuk bergabung',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ).animate().fade(delay: 100.ms).slideY(begin: 0.3),
                      
                      const SizedBox(height: 40),
                      
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
                              label: 'Nama Lengkap',
                              controller: _namaController,
                              icon: Icons.badge_outlined,
                            ).animate().fade(delay: 100.ms).slideX(begin: 0.1),
                            
                            const SizedBox(height: 20),
                            
                            _buildPremiumTextField(
                              label: 'Username',
                              controller: _usernameController,
                              icon: Icons.person_outline_rounded,
                            ).animate().fade(delay: 155.ms).slideX(begin: 0.1),
                            
                            const SizedBox(height: 20),
                            
                            _buildPremiumTextField(
                              label: 'Kata Sandi',
                              controller: _passwordController,
                              icon: Icons.lock_outline_rounded,
                              isPassword: true,
                            ).animate().fade(delay: 200.ms).slideX(begin: 0.1),
                            
                            const SizedBox(height: 20),
                            
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildPremiumDropdown(
                                    label: 'Usia',
                                    value: _usia,
                                    items: List.generate(70, (i) => (i + 17).toString()), // Usia 17 - 86
                                    onChanged: (val) => setState(() => _usia = val!),
                                    icon: Icons.cake_outlined,
                                  ).animate().fade(delay: 250.ms).slideX(begin: 0.1),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 3,
                                  child: _buildPremiumDropdown(
                                    label: 'Kelamin',
                                    value: _jenisKelamin,
                                    items: const ['Laki-laki', 'Perempuan'],
                                    onChanged: (val) => setState(() => _jenisKelamin = val!),
                                    icon: Icons.male_outlined,
                                  ).animate().fade(delay: 300.ms).slideX(begin: 0.1),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            _buildPremiumTextField(
                              label: 'Nomor HP',
                              controller: _noHpController,
                              icon: Icons.phone_outlined,
                              isNumber: true,
                            ).animate().fade(delay: 350.ms).slideX(begin: 0.1),
                            
                            const SizedBox(height: 32),
                            
                            // Tombol Daftar
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _doRegister,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConstants.jemaahPrimary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                    : Text(
                                        'Daftar Sekarang',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ).animate().fade(delay: 500.ms).scale(curve: Curves.easeOutBack),

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
                            ).animate().fade(delay: 550.ms),

                            const SizedBox(height: 24),

                            // Google Register Button
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
                                  'Daftar dengan Google',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ).animate().fade(delay: 580.ms).slideY(begin: 0.1),
                          ],
                        ),
                      ),
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
    bool isNumber = false,
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
            obscureText: isPassword && !_isPasswordVisible,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
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
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
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

  Widget _buildPremiumDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
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
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            value: value,
            icon: Icon(Icons.keyboard_arrow_down, color: textLightColor),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: textLightColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.plusJakartaSans(color: textColor)))).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
