import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/assessment_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/assessment_history.dart';
import '../../utils/constants.dart';
import '../../utils/dynamic_island.dart';
import 'medical_record_screen.dart';
import '../profile/profile_screen.dart';

class DashboardPetugasScreen extends StatefulWidget {
  const DashboardPetugasScreen({super.key});

  @override
  State<DashboardPetugasScreen> createState() => _DashboardPetugasScreenState();
}

class _DashboardPetugasScreenState extends State<DashboardPetugasScreen> {
  String _selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssessmentProvider>().fetchAllAssessments();
      context.read<NotificationProvider>().fetchNotifications();
      _requestNotificationPermission();
    });
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  Future<void> _onRefresh() async {
    await context.read<AssessmentProvider>().fetchAllAssessments();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final assessmentProvider = context.watch<AssessmentProvider>();
    final unreadCount = context.watch<NotificationProvider>().unreadCount;
    final histories = assessmentProvider.histories;
    final isLoading = assessmentProvider.isLoading;

    final totalJemaah = histories.length;
    final risikoTinggi = histories.where((e) => e.tingkatRisiko == 'Tinggi').length;
    final risikoSedang = histories.where((e) => e.tingkatRisiko == 'Sedang').length;
    final risikoRendah = histories.where((e) => e.tingkatRisiko == 'Rendah').length;

    final filteredHistories = _selectedFilter == 'Semua'
        ? histories
        : histories.where((e) => e.tingkatRisiko == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // --- FIXED HEADER & SUMMARY ---
          Stack(
            clipBehavior: Clip.none,
            children: [
              // --- HEADER MEDIS ---
              Container(
                height: 280,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1E3A5F), // Petugas Primary
                      Color(0xFF0F2036), // Deep Dark Navy
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 20,
                    left: 24.0,
                    right: 24.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                                  ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeOut(duration: 1.seconds),
                                  const SizedBox(width: 8),
                                  Text(
                                    'SYSTEM ONLINE',
                                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            Text(
                              user?.nama ?? 'Dr. Petugas',
                              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Pusat Komando Medis Haji',
                              style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Stack(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                                onPressed: () {
                                  context.push('/notifications');
                                },
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF1E3A5F), width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.redAccent.withOpacity(0.4),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$unreadCount',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ProfileScreen()),
                              );
                            },
                            child: user?.fotoProfil != null
                                ? ClipOval(
                                    child: Image.network(
                                      '${AppConstants.baseUrl}/${user!.fotoProfil}',
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return CircleAvatar(
                                          radius: 28,
                                          backgroundColor: Colors.white.withOpacity(0.1),
                                          child: const Icon(Icons.person, color: Colors.white, size: 32),
                                        );
                                      },
                                    ),
                                  )
                                : CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.white.withOpacity(0.1),
                                    child: const Icon(Icons.person, color: Colors.white, size: 32),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Ornamen EKG / Detak Jantung
              Positioned(
                top: 40,
                right: -50,
                child: IgnorePointer(
                  child: Icon(
                    Icons.monitor_heart_outlined,
                    size: 200,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              
              // --- PANEL RINGKASAN MEDIS (OVERLAPPING) ---
              Positioned(
                top: 230,
                left: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 30, offset: const Offset(0, 15)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.analytics_outlined, color: AppConstants.petugasPrimary, size: 20),
                          const SizedBox(width: 8),
                          Text('Ringkasan Kondisi Jemaah', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppConstants.textDark)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMiniStat('Tinggi', risikoTinggi, AppConstants.statusTinggi, Icons.emergency),
                          _buildMiniStat('Sedang', risikoSedang, AppConstants.statusSedang, Icons.warning_amber_rounded),
                          _buildMiniStat('Rendah', risikoRendah, AppConstants.statusRendah, Icons.check_circle_outline),
                          _buildMiniStat('Total', totalJemaah, Colors.blueAccent, Icons.group),
                        ],
                      ),
                    ],
                  ),
                ).animate().fade(delay: 400.ms).slideY(begin: 0.2),
              ),
            ],
          ),
          
          // Spacer untuk overlapping card
          const SizedBox(height: 120),

          // --- FILTER TABS (FIXED) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: ['Semua', 'Tinggi', 'Sedang', 'Rendah'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  Color dotColor = Colors.blueAccent;
                  if (filter == 'Tinggi') dotColor = AppConstants.statusTinggi;
                  if (filter == 'Sedang') dotColor = AppConstants.statusSedang;
                  if (filter == 'Rendah') dotColor = AppConstants.statusRendah;

                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = filter),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppConstants.petugasPrimary : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade300),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppConstants.petugasPrimary.withOpacity(0.15),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  )
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            if (filter != 'Semua') ...[
                              Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              filter,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected ? Colors.white : AppConstants.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ).animate().fade(delay: 500.ms).slideX(begin: 0.2),
            ),
          ),
          
          // --- SCROLLABLE CARD LIST ---
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppConstants.petugasPrimary,
              child: isLoading && histories.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : filteredHistories.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tidak ada rekam medis.',
                                    style: GoogleFonts.plusJakartaSans(color: AppConstants.textLight, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 120.0),
                          itemCount: filteredHistories.length,
                          itemBuilder: (context, index) {
                            return _buildAdvancedMedicalCard(filteredHistories[index], index);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, int value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(value.toString(), style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppConstants.textDark)),
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppConstants.textLight, fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _showContactOptions(BuildContext context, AssessmentHistory item) {
    if (item.noHp.isEmpty || item.noHp == '-') {
      DynamicIsland.show(context, message: 'Nomor telepon jemaah tidak tersedia.', type: IslandType.error);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Hubungi Jemaah',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: isDark ? Colors.white : AppConstants.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pilih metode komunikasi dengan ${item.namaJemaah}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppConstants.textLight,
                ),
              ),
              const SizedBox(height: 24),
              
              // WhatsApp Button
              _buildContactMethodCard(
                context: context,
                icon: Icons.chat_outlined,
                title: 'WhatsApp Chat',
                subtitle: 'Kirim pesan chat langsung ke WhatsApp jemaah',
                color: Colors.green,
                onTap: () async {
                  Navigator.pop(context);
                  String phone = item.noHp;
                  if (phone.startsWith('0')) {
                    phone = '62${phone.substring(1)}';
                  }
                  final message = 'Assalamualaikum ${item.namaJemaah}, saya petugas medis haji ingin menanyakan perkembangan kondisi kesehatan Anda terkait hasil pemeriksaan terbaru.';
                  final url = 'https://wa.me/$phone?text=${Uri.encodeComponent(message)}';
                  final uri = Uri.parse(url);
                  try {
                    final canLaunch = await canLaunchUrl(uri);
                    if (!context.mounted) return;
                    if (canLaunch) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      DynamicIsland.show(context, message: 'Tidak dapat membuka WhatsApp.', type: IslandType.error);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      DynamicIsland.show(context, message: 'Error: $e', type: IslandType.error);
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // Phone Call Button
              _buildContactMethodCard(
                context: context,
                icon: Icons.phone_outlined,
                title: 'Panggilan Telepon',
                subtitle: 'Lakukan panggilan seluler langsung ke nomor jemaah',
                color: Colors.blueAccent,
                onTap: () async {
                  Navigator.pop(context);
                  final uri = Uri.parse('tel:${item.noHp}');
                  try {
                    final canLaunch = await canLaunchUrl(uri);
                    if (!context.mounted) return;
                    if (canLaunch) {
                      await launchUrl(uri);
                    } else {
                      DynamicIsland.show(context, message: 'Tidak dapat melakukan panggilan telepon.', type: IslandType.error);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      DynamicIsland.show(context, message: 'Error: $e', type: IslandType.error);
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactMethodCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : AppConstants.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppConstants.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppConstants.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedMedicalCard(AssessmentHistory item, int index) {
    Color riskColor;
    bool isDanger = false;

    switch (item.tingkatRisiko) {
      case 'Tinggi':
        riskColor = AppConstants.statusTinggi;
        isDanger = true;
        break;
      case 'Sedang':
        riskColor = AppConstants.statusSedang;
        break;
      default:
        riskColor = AppConstants.statusRendah;
    }

    String formattedDate = '-';
    try {
      final dt = DateTime.parse(item.tanggal);
      formattedDate = DateFormat('dd MMM, HH:mm').format(dt);
    } catch (_) {}

    Widget cardContent = Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDanger ? riskColor.withOpacity(0.2) : Colors.black.withOpacity(0.04),
            blurRadius: isDanger ? 24 : 12,
            offset: const Offset(0, 8),
          )
        ],
        // Garis tepi kiri vertikal tebal
        border: Border(left: BorderSide(color: riskColor, width: 6)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Kartu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: riskColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.tingkatRisiko.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(color: riskColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
                          ),
                        ),
                        if (isDanger)
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Icon(Icons.warning_rounded, color: AppConstants.statusTinggi, size: 16),
                          ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeOut(duration: 800.ms),
                      ],
                    ),
                    Text(formattedDate, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppConstants.textLight, fontWeight: FontWeight.w600)),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Info Pasien
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F4F8),
                      child: Text(
                        item.namaJemaah.isNotEmpty ? item.namaJemaah[0].toUpperCase() : '?',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 20, color: AppConstants.petugasPrimary),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.namaJemaah, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18, color: AppConstants.textDark)),
                          const SizedBox(height: 2),
                          Text('${item.usia} Tahun • ${item.jenisKelamin}', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppConstants.textLight)),
                        ],
                      ),
                    ),
                    // Temperatur Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: (item.suhuTubuh >= 38.0) ? AppConstants.statusTinggi.withOpacity(0.1) : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F4F8)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text('${item.suhuTubuh}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: (item.suhuTubuh >= 38.0) ? AppConstants.statusTinggi : AppConstants.textDark)),
                          Text('°C', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppConstants.textLight)),
                        ],
                      ),
                    )
                  ],
                ),
                
                if (item.gejala.isNotEmpty && item.gejala != 'Tidak Ada') ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.medical_information_outlined, size: 18, color: riskColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Keluhan: ${item.gejala}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppConstants.textDark, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]
              ],
            ),
          ),
          
          // Action Buttons Bottom
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : const Color(0xFFF0F4F8), width: 1.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _showContactOptions(context, item),
                    icon: Icon(Icons.call_outlined, size: 18, color: AppConstants.textLight),
                    label: Text('Hubungi', style: GoogleFonts.plusJakartaSans(color: AppConstants.textDark, fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20)))),
                  ),
                ),
                Container(width: 1.5, height: 24, color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : const Color(0xFFF0F4F8)),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MedicalRecordScreen(record: item)),
                      );
                    },
                    icon: Icon(Icons.article_outlined, size: 18, color: AppConstants.textLight),
                    label: Text('Rekam Medis', style: GoogleFonts.plusJakartaSans(color: AppConstants.textDark, fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(bottomRight: Radius.circular(20)))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Jika Danger, berikan efek Shimmer halus (pulse) pada pinggiran kartu
    if (isDanger) {
      cardContent = cardContent.animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2.seconds, color: riskColor.withOpacity(0.1));
    }

    // Gunakan flutter_animate dengan kalkulasi delay cerdas agar animasi scroll muncul seketika
    int delayBase = index > 4 ? 0 : (index * 100);
    return cardContent
        .animate()
        .fade(delay: delayBase.ms, duration: 400.ms)
        .slideY(begin: 0.1, duration: 400.ms, delay: delayBase.ms);
  }
}
