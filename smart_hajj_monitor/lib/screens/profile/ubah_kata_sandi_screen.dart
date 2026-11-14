import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';
import '../../utils/dynamic_island.dart';

class UbahKataSandiScreen extends StatefulWidget {
  const UbahKataSandiScreen({super.key});

  @override
  State<UbahKataSandiScreen> createState() => _UbahKataSandiScreenState();
}

class _UbahKataSandiScreenState extends State<UbahKataSandiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<AuthProvider>(context, listen: false);
    final success = await provider.changePassword(
      _oldPasswordController.text,
      _newPasswordController.text,
    );

    if (mounted) {
      if (success) {
        DynamicIsland.show(
          context,
          message: '🔑 Kata sandi berhasil diperbarui!',
          type: IslandType.success,
        );
        Navigator.pop(context);
      } else {
        DynamicIsland.show(
          context,
          message: 'Gagal mengubah kata sandi. Periksa sandi lama Anda.',
          type: IslandType.error,
        );
      }
    }
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final isLoading = context.watch<AuthProvider>().isLoading;
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
          'Ubah Kata Sandi',
          style: GoogleFonts.plusJakartaSans(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        iconTheme: IconThemeData(color: textColor),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.withOpacity(0.1), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Perbarui Keamanan Akun Anda',
                style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: textColor),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
              
              const SizedBox(height: 8),
              
              Text(
                'Masukkan kata sandi lama Anda beserta kata sandi baru yang ingin digunakan.',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textLightColor, height: 1.4),
              ).animate().fadeIn(delay: 100.ms),
              
              const SizedBox(height: 32),

              // Card Container untuk Form Fields
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppConstants.premiumShadow,
                ),
                child: Column(
                  children: [
                    _buildPasswordField(
                      label: 'Kata Sandi Lama',
                      controller: _oldPasswordController,
                      isVisible: _isOldPasswordVisible,
                      onVisibilityToggle: () => setState(() => _isOldPasswordVisible = !_isOldPasswordVisible),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Kata sandi lama wajib diisi';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildPasswordField(
                      label: 'Kata Sandi Baru',
                      controller: _newPasswordController,
                      isVisible: _isNewPasswordVisible,
                      onVisibilityToggle: () => setState(() => _isNewPasswordVisible = !_isNewPasswordVisible),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Kata sandi baru wajib diisi';
                        if (val.length < 6) return 'Kata sandi baru minimal 6 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildPasswordField(
                      label: 'Konfirmasi Kata Sandi Baru',
                      controller: _confirmPasswordController,
                      isVisible: _isConfirmPasswordVisible,
                      onVisibilityToggle: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Konfirmasi kata sandi wajib diisi';
                        if (val != _newPasswordController.text) return 'Konfirmasi kata sandi tidak cocok';
                        return null;
                      },
                    ),
                  ],
                ),
              ).animate().fade(delay: 200.ms).slideY(begin: 0.05),

              const SizedBox(height: 40),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.jemaahPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        )
                      : Text(
                          'Perbarui Kata Sandi',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ).animate().fade(delay: 300.ms).scale(curve: Curves.easeOutBack),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback onVisibilityToggle,
    required String? Function(String?) validator,
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
          child: TextFormField(
            controller: controller,
            obscureText: !isVisible,
            style: GoogleFonts.plusJakartaSans(color: textColor, fontWeight: FontWeight.w500),
            validator: validator,
            decoration: InputDecoration(
              hintText: 'Masukkan $label',
              hintStyle: GoogleFonts.plusJakartaSans(color: textLightColor.withOpacity(0.5), fontSize: 14),
              prefixIcon: Icon(Icons.lock_outline_rounded, color: textLightColor),
              suffixIcon: IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: textLightColor,
                ),
                onPressed: onVisibilityToggle,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              errorStyle: const TextStyle(height: 0), // Menyembunyikan text error bawaan untuk menjaga kerapihan UI
            ),
          ),
        ),
      ],
    );
  }
}
