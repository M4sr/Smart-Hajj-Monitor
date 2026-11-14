import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/dynamic_island.dart';
import 'edit_profile_screen.dart';

class DataDiriScreen extends StatefulWidget {
  const DataDiriScreen({super.key});

  @override
  State<DataDiriScreen> createState() => _DataDiriScreenState();
}

class _DataDiriScreenState extends State<DataDiriScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _fetchMyProfile();
  }

  Future<void> _fetchMyProfile() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.dio.get('/users/me');
      if (response.statusCode == 200) {
        setState(() {
          _profileData = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        DynamicIsland.show(context, message: 'Gagal mengambil data diri', type: IslandType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Data Diri',
          style: GoogleFonts.plusJakartaSans(color: AppConstants.textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        iconTheme: IconThemeData(color: AppConstants.textDark),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.withOpacity(0.1), height: 1),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppConstants.petugasPrimary))
          : _profileData == null
              ? Center(child: Text('Data tidak tersedia', style: GoogleFonts.plusJakartaSans()))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Avatar Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: AppConstants.premiumShadow,
                        ),
                        child: Column(
                          children: [
                            _profileData!['foto_profil'] != null
                                ? ClipOval(
                                    child: Image.network(
                                      '${AppConstants.baseUrl}/${_profileData!['foto_profil']}',
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return CircleAvatar(
                                          radius: 50,
                                          backgroundColor: AppConstants.petugasPrimary.withOpacity(0.1),
                                          child: Text(
                                            _profileData!['nama'].toString().isNotEmpty ? _profileData!['nama'].toString()[0].toUpperCase() : '?',
                                            style: GoogleFonts.plusJakartaSans(fontSize: 40, fontWeight: FontWeight.bold, color: AppConstants.petugasPrimary),
                                          ),
                                        );
                                      },
                                    ),
                                  ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack)
                                : CircleAvatar(
                                    radius: 50,
                                    backgroundColor: AppConstants.petugasPrimary.withOpacity(0.1),
                                    child: Text(
                                      _profileData!['nama'].toString().isNotEmpty ? _profileData!['nama'].toString()[0].toUpperCase() : '?',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 40, fontWeight: FontWeight.bold, color: AppConstants.petugasPrimary),
                                    ),
                                  ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                            const SizedBox(height: 16),
                            Text(
                              _profileData!['nama'],
                              style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: AppConstants.textDark),
                              textAlign: TextAlign.center,
                            ).animate().fadeIn(delay: 100.ms),
                            const SizedBox(height: 4),
                            Text(
                              '@${_profileData!['username']}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppConstants.petugasPrimary, fontWeight: FontWeight.w600),
                            ).animate().fadeIn(delay: 200.ms),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: _profileData!['role'] == 'Petugas' ? AppConstants.petugasPrimary.withOpacity(0.1) : AppConstants.jemaahPrimary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _profileData!['role'],
                                style: GoogleFonts.plusJakartaSans(
                                  color: _profileData!['role'] == 'Petugas' ? AppConstants.petugasPrimary : AppConstants.jemaahPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  ),
                                ),
                              ).animate().fadeIn(delay: 300.ms),
                            ],
                          ),
                        ).animate().slideY(begin: 0.1),

                        const SizedBox(height: 24),

                        // Detail Information Card
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: AppConstants.premiumShadow,
                          ),
                          child: Column(
                            children: [
                              _buildInfoTile(Icons.cake_outlined, 'Usia', '${_profileData!['usia'] ?? '-'} Tahun', 400),
                              Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                              _buildInfoTile(Icons.male_outlined, 'Jenis Kelamin', _profileData!['jenis_kelamin'] ?? 'Belum diatur', 500),
                              Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                              _buildInfoTile(Icons.phone_outlined, 'Nomor HP', _profileData!['no_hp'] ?? 'Belum diatur', 600),
                              Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                              _buildInfoTile(
                                Icons.calendar_month_outlined, 
                                'Tanggal Terdaftar', 
                                _formatDate(_profileData!['tanggal_daftar']), 
                                700
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: 32),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.edit_outlined, color: Colors.white),
                          label: Text('Edit Profil', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.petugasPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProfileScreen(initialData: _profileData!),
                              ),
                            );

                            // Jika kembali dari EditProfile dan berhasil (result == true), refresh data
                            if (result == true) {
                              _fetchMyProfile();
                            }
                          },
                        ),
                      ).animate().fade(delay: 800.ms).slideY(begin: 0.2),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, int delay) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppConstants.textLight, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppConstants.textLight, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 16, color: AppConstants.textDark, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade(delay: delay.ms).slideX(begin: 0.1);
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final dt = DateTime.parse(dateString);
      return DateFormat('dd MMMM yyyy').format(dt);
    } catch (_) {
      return dateString;
    }
  }
}
