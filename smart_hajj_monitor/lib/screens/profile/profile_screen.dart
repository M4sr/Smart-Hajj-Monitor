import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';

import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/dynamic_island.dart';
import 'data_diri_screen.dart';
import 'pengaturan_akun_screen.dart';
import 'pusat_bantuan_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploadingPhoto = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
      if (pickedFile != null) {
        _uploadImage(File(pickedFile.path));
      }
    } catch (e) {
      DynamicIsland.show(context, message: 'Gagal memilih gambar', type: IslandType.error);
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    setState(() => _isUploadingPhoto = true);
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imageFile.path, filename: 'profile.jpg'),
      });

      final response = await ApiService.dio.post('/users/me/upload-photo', data: formData);
      
      if (response.statusCode == 200) {
        final fotoProfil = response.data['foto_profil'];
        final provider = Provider.of<AuthProvider>(context, listen: false);
        await provider.updateFotoProfil(fotoProfil);
        DynamicIsland.show(context, message: 'Foto profil berhasil diunggah', type: IslandType.success);
      }
    } on DioException catch (e) {
      String errorMessage = 'Gagal mengunggah foto';
      if (e.response != null && e.response?.data is Map) {
        errorMessage = e.response?.data['detail'] ?? errorMessage;
      } else if (e.response?.statusCode == 500) {
        errorMessage = 'Terjadi kesalahan di server backend (500)';
      }
      DynamicIsland.show(context, message: errorMessage, type: IslandType.error);
    } catch (e) {
      DynamicIsland.show(context, message: 'Terjadi kesalahan sistem', type: IslandType.error);
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _showImagePickerModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Ubah Foto Profil',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppConstants.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pilih sumber foto untuk profil Anda',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppConstants.textLight,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: _buildPickerOption(
                        icon: Icons.camera_alt_rounded,
                        label: 'Kamera',
                        color: AppConstants.petugasPrimary,
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildPickerOption(
                        icon: Icons.photo_library_rounded,
                        label: 'Galeri',
                        color: Colors.blueAccent,
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildPickerOption({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.15 : 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(isDark ? 0.3 : 0.1), width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: AppConstants.textDark,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ).animate().fade().scale(curve: Curves.easeOutBack, duration: 400.ms),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isPetugas = user?.role.toLowerCase() == 'petugas' || user?.role.toLowerCase() == 'admin';
    final themePrimary = isPetugas ? AppConstants.petugasPrimary : AppConstants.jemaahPrimary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeBackground = isDark 
        ? Theme.of(context).scaffoldBackgroundColor 
        : (isPetugas ? const Color(0xFFF0F4F8) : const Color(0xFFF7FDF9));

    return Scaffold(
      backgroundColor: themeBackground,
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 320.0,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: themePrimary,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          themePrimary.withOpacity(0.8),
                          themePrimary,
                        ],
                      ),
                    ),
                  ),
                  // Animated Wave Liquid Effect
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: SizedBox(
                      height: 150,
                      child: WaveWidget(
                        config: CustomConfig(
                          gradients: [
                            [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.01)],
                            [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.02)],
                            [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
                            [themeBackground, themeBackground],
                          ],
                          durations: [60000, 45000, 30000, 20000],
                          heightPercentages: [0.20, 0.23, 0.25, 0.30],
                          blur: const MaskFilter.blur(BlurStyle.solid, 10),
                          gradientBegin: Alignment.bottomLeft,
                          gradientEnd: Alignment.topRight,
                        ),
                        waveAmplitude: 20,
                        backgroundColor: Colors.transparent,
                        size: const Size(double.infinity, double.infinity),
                      ),
                    ),
                  ),
                  // Big background Icon
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Icon(
                      Icons.fingerprint_rounded,
                      size: 200,
                      color: Colors.white.withOpacity(0.05),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.05,1.05), duration: 4.seconds),
                  ),
                  SafeArea(
                    child: Center(
                      child: Transform.translate(
                        offset: const Offset(0, -30),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          // GLOSSY AVATAR WITH PULSING RINGS
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                                ),
                              ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(1,1), end: const Offset(1.5,1.5), duration: 2.seconds).fade(end: 0),
                              GestureDetector(
                                onTap: _isUploadingPhoto ? null : _showImagePickerModal,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 90,
                                      height: 90,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.2),
                                        boxShadow: [
                                          BoxShadow(color: themePrimary.withOpacity(0.5), blurRadius: 20, spreadRadius: 5),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 40,
                                        backgroundColor: Colors.white,
                                        backgroundImage: user?.fotoProfil != null
                                            ? NetworkImage('${AppConstants.baseUrl}/${user!.fotoProfil!}')
                                            : null,
                                        child: user?.fotoProfil == null
                                            ? const Icon(Icons.person_rounded, size: 45, color: Colors.grey)
                                            : null,
                                      ),
                                    ),
                                    if (_isUploadingPhoto)
                                      const Positioned.fill(
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                      ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: themePrimary,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                        child: const Icon(Icons.edit, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            user?.nama ?? 'Pengguna',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ).animate().fade(delay: 200.ms).slideY(begin: 0.2),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPetugas ? Icons.verified_user_rounded : Icons.card_membership_rounded,
                                  color: themePrimary,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  (user?.role ?? 'Role').toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(color: themePrimary, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                                ),
                              ],
                            ),
                          ).animate().fade(delay: 300.ms).slideY(begin: 0.2),
                        ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, left: 24, right: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    // GLASSMORPHISM MENU CARD
                    ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? Theme.of(context).cardColor.withOpacity(0.8) : Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: isDark ? Colors.white12 : Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(color: themePrimary.withOpacity(isDark ? 0.02 : 0.08), blurRadius: 25, offset: const Offset(0, 10)),
                            ],
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 8),
                              _buildPremiumProfileMenu(
                                icon: Icons.badge_rounded,
                                title: 'Data Diri',
                                subtitle: 'Informasi personal & medis',
                                iconColor: Colors.blueAccent,
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DataDiriScreen())),
                                delay: 400,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                child: Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                              ),
                              _buildPremiumProfileMenu(
                                icon: Icons.admin_panel_settings_rounded,
                                title: 'Pengaturan Akun',
                                subtitle: 'Kata sandi & keamanan',
                                iconColor: Colors.purpleAccent,
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PengaturanAkunScreen())),
                                delay: 500,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                child: Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                              ),
                              _buildPremiumProfileMenu(
                                icon: Icons.help_center_rounded,
                                title: 'Pusat Bantuan',
                                subtitle: 'FAQ & kontak darurat',
                                iconColor: Colors.orangeAccent,
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PusatBantuanScreen())),
                                delay: 600,
                              ),
                              if (isPetugas) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                                ),
                                _buildPremiumProfileMenu(
                                  icon: Icons.api_rounded,
                                  title: 'Dokumentasi API',
                                  subtitle: 'Akses spesifikasi & rute API backend',
                                  iconColor: Colors.tealAccent.shade700,
                                  onTap: () => _launchApiDocs(context),
                                  delay: 700,
                                ),
                              ],
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fade(delay: 350.ms).slideY(begin: 0.1),
                    
                    const SizedBox(height: 40),
                    
                    // LOGOUT BUTTON
                    GestureDetector(
                      onTap: () {
                        context.read<AuthProvider>().logout();
                        context.go('/login');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark 
                                ? [Colors.red.shade900.withOpacity(0.3), Colors.red.shade900.withOpacity(0.1)]
                                : [const Color(0xFFFFF0F0), const Color(0xFFFFE0E0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                          boxShadow: isDark ? [] : [
                            BoxShadow(color: Colors.redAccent.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8)),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              'Keluar dari Akun',
                              style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fade(delay: 700.ms).slideY(begin: 0.2),
                    
                    const SizedBox(height: 48),
                    FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snapshot) {
                        final versionStr = snapshot.hasData ? 'v${snapshot.data!.version}' : 'v...';
                        return Center(
                          child: Text(
                            'Smart Hajj Monitor $versionStr',
                            style: GoogleFonts.plusJakartaSans(color: AppConstants.textLight, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1),
                          ).animate().fade(delay: 800.ms),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPremiumProfileMenu({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
    required int delay,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppConstants.textDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppConstants.textLight, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      }
    ).animate().fade(delay: delay.ms).slideX(begin: 0.1);
  }

  void _launchApiDocs(BuildContext context) async {
    final Uri docsUri = Uri.parse('${AppConstants.baseUrl}/docs');
    try {
      final success = await launchUrl(
        docsUri,
        mode: LaunchMode.externalApplication,
      );
      if (!success && context.mounted) {
        DynamicIsland.show(
          context,
          message: 'Gagal membuka dokumentasi API.',
          type: IslandType.error,
        );
      }
    } catch (e) {
      if (context.mounted) {
        DynamicIsland.show(
          context,
          message: 'Error: $e',
          type: IslandType.error,
        );
      }
    }
  }
}
