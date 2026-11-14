import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../providers/auth_provider.dart';
import '../../providers/assessment_provider.dart';
import '../../providers/notification_provider.dart';
import '../../utils/constants.dart';
import '../../utils/dynamic_island.dart';

class AssessmentFormScreen extends StatefulWidget {
  const AssessmentFormScreen({super.key});

  @override
  State<AssessmentFormScreen> createState() => _AssessmentFormScreenState();
}

class _AssessmentFormScreenState extends State<AssessmentFormScreen> {
  String _gejala = 'Tidak Ada';
  String _kondisi = 'Sehat';
  double _suhuTubuh = 36.5;
  String _batuk = 'Tidak';
  String _sesakNapas = 'Tidak';
  String _riwayatPenyakit = 'Tidak Ada';
  final TextEditingController _lainnyaController = TextEditingController();

  @override
  void dispose() {
    _lainnyaController.dispose();
    super.dispose();
  }

  final List<String> gejalaOptions = ['Tidak Ada', 'Pusing', 'Mual', 'Demam', 'Nyeri Dada'];
  final List<String> kondisiOptions = ['Sehat', 'Kelelahan', 'Sakit Ringan', 'Sakit Parah'];
  final List<String> riwayatOptions = ['Tidak Ada', 'Hipertensi', 'Diabetes', 'Jantung', 'Asma'];

  void _submit() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final data = {
      "id_user": 1, // Akan disesuaikan dengan ID asli
      "gejala": _gejala,
      "kondisi": _kondisi,
      "suhu_tubuh": _suhuTubuh,
      "batuk": _batuk,
      "sesak_napas": _sesakNapas,
      "riwayat_penyakit": _riwayatPenyakit,
      "lainnya": _lainnyaController.text.trim().isEmpty ? 'Tidak Ada' : _lainnyaController.text.trim()
    };

    final success = await context.read<AssessmentProvider>().submitAssessment(data);
    if (success && mounted) {
      context.read<NotificationProvider>().fetchNotifications();
      context.go('/result');
    } else {
      if (mounted) {
        DynamicIsland.show(context, message: 'Gagal mengirim data. Coba lagi.', type: IslandType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AssessmentProvider>().isLoading;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Soft modern background
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: AppConstants.jemaahPrimary,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              title: Text(
                'Lapor Kesehatan',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
              centerTitle: true,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0F9D58), AppConstants.jemaahPrimary],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ).animate(onPlay: (c) => c.repeat()).rotate(duration: 20.seconds),
                  ),
                  Positioned(
                    bottom: 20,
                    left: -20,
                    child: Icon(
                      Icons.monitor_heart_rounded,
                      size: 120,
                      color: Colors.white.withOpacity(0.1),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .moveY(begin: -5, end: 5, duration: 2.seconds),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kondisi Saat Ini',
                      style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppConstants.textDark),
                    ).animate().fade().slideX(begin: -0.1),
                    const SizedBox(height: 16),
                    
                    _buildPremiumDropdown('Gejala Utama', Icons.sick_outlined, _gejala, gejalaOptions, (val) => setState(() => _gejala = val!), 100),
                    _buildPremiumDropdown('Kondisi Umum', Icons.accessibility_new_rounded, _kondisi, kondisiOptions, (val) => setState(() => _kondisi = val!), 200),
                    
                    const SizedBox(height: 24),
                    Text(
                      'Tanda Vital',
                      style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppConstants.textDark),
                    ).animate().fade(delay: 300.ms).slideX(begin: -0.1),
                    const SizedBox(height: 16),
                    
                    // KATEGORI SUHU TUBUH PREMIUM (MENGGANTIKAN SLIDER)
                    Text(
                      'Pilih Kondisi Suhu Tubuh',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppConstants.textLight),
                    ).animate().fade(delay: 350.ms),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildSuhuCard(
                          title: 'Normal',
                          subtitle: 'Sehat',
                          value: 36.5,
                          icon: Icons.check_circle_outline_rounded,
                          color: AppConstants.statusRendah,
                          delay: 400,
                        ),
                        const SizedBox(width: 12),
                        _buildSuhuCard(
                          title: 'Meriang',
                          subtitle: 'Demam Ringan',
                          value: 38.0,
                          icon: Icons.thermostat_rounded,
                          color: AppConstants.statusSedang,
                          delay: 450,
                        ),
                        const SizedBox(width: 12),
                        _buildSuhuCard(
                          title: 'Panas',
                          subtitle: 'Demam Tinggi',
                          value: 39.5,
                          icon: Icons.local_fire_department_rounded,
                          color: AppConstants.statusTinggi,
                          delay: 500,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'Pertanyaan Tambahan',
                      style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppConstants.textDark),
                    ).animate().fade(delay: 500.ms).slideX(begin: -0.1),
                    const SizedBox(height: 16),

                    _buildPremiumDropdown('Apakah Anda Batuk?', Icons.coronavirus_outlined, _batuk, ['Ya', 'Tidak'], (val) => setState(() => _batuk = val!), 600),
                    _buildPremiumDropdown('Merasa Sesak Napas?', Icons.air_rounded, _sesakNapas, ['Ya', 'Tidak'], (val) => setState(() => _sesakNapas = val!), 700),
                    _buildPremiumDropdown('Riwayat Penyakit Bawaan', Icons.medical_information_outlined, _riwayatPenyakit, riwayatOptions, (val) => setState(() => _riwayatPenyakit = val!), 800),
                    
                    Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.grey.withOpacity(0.1)),
                        boxShadow: AppConstants.premiumShadow,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppConstants.jemaahPrimary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit_note_rounded, size: 24, color: AppConstants.jemaahPrimary),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _lainnyaController,
                              maxLines: 4,
                              minLines: 2,
                              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppConstants.textDark),
                              decoration: InputDecoration(
                                labelText: 'Catatan Keluhan Lainnya (Opsional)',
                                alignLabelWithHint: true,
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                labelStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppConstants.textLight),
                                hintText: 'Ketik di sini...',
                                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 16, color: Colors.grey.withOpacity(0.5)),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.only(top: 8, bottom: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fade(delay: 900.ms).slideX(begin: 0.1),
                    
                    const SizedBox(height: 40),
                    
                    // TOMBOL KIRIM PREMIUM
                    GestureDetector(
                      onTap: isLoading ? null : _submit,
                      child: Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isLoading 
                              ? [Colors.grey, Colors.grey.shade600] 
                              : [AppConstants.jemaahAccent, const Color(0xFFF57F17)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isLoading ? [] : [
                            BoxShadow(color: AppConstants.jemaahAccent.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: Center(
                          child: isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.auto_awesome_rounded, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                      'MINTA ANALISIS AI',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                                    ),
                                  ],
                                ),
                        ),
                      ).animate(target: isLoading ? 0 : 1).scale(begin: const Offset(0.95,0.95), end: const Offset(1,1)),
                    ).animate().fade(delay: 900.ms).slideY(begin: 0.2),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumDropdown(String label, IconData icon, String value, List<String> items, void Function(String?) onChanged, int delay) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900, color: AppConstants.textDark),
                  ),
                  const SizedBox(height: 24),
                  ...items.map((item) {
                    final isSelected = item == value;
                    return InkWell(
                      onTap: () {
                        onChanged(item);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.08) : Colors.transparent,
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                              color: isSelected ? AppConstants.jemaahPrimary : Colors.grey.shade400,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                item,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Theme.of(context).primaryColor : AppConstants.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.grey.withOpacity(0.1)),
          boxShadow: AppConstants.premiumShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.jemaahPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: AppConstants.jemaahPrimary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppConstants.textLight),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        value,
                        style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppConstants.textDark),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: AppConstants.jemaahPrimary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fade(delay: delay.ms).slideX(begin: 0.1),
    );
  }

  Widget _buildSuhuCard({
    required String title,
    required String subtitle,
    required double value,
    required IconData icon,
    required Color color,
    required int delay,
  }) {
    final isSelected = _suhuTubuh == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _suhuTubuh = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected 
                ? color.withOpacity(isDark ? 0.2 : 0.1) 
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : (isDark ? Colors.white12 : Colors.grey.withOpacity(0.2)),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))] : [],
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : AppConstants.textLight, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, 
                  fontWeight: FontWeight.w800, 
                  color: isSelected ? color : AppConstants.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, 
                  fontWeight: FontWeight.w600, 
                  color: AppConstants.textLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ).animate().fade(delay: delay.ms).slideY(begin: 0.1),
    );
  }
}
