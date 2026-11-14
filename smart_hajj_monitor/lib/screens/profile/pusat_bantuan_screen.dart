import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/constants.dart';
import '../../utils/dynamic_island.dart';

class PusatBantuanScreen extends StatelessWidget {
  const PusatBantuanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Pusat Bantuan',
          style: GoogleFonts.plusJakartaSans(color: AppConstants.textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        iconTheme: IconThemeData(color: AppConstants.textDark),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.withOpacity(0.1), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image/Illustration
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppConstants.petugasPrimary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.support_agent_rounded, size: 60, color: AppConstants.petugasPrimary),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Ada yang bisa kami bantu?',
                style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: AppConstants.textDark),
              ).animate().fadeIn(delay: 200.ms),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Pilih topik kendala atau hubungi CS kami',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppConstants.textLight),
              ).animate().fadeIn(delay: 300.ms),
            ),
            
            const SizedBox(height: 40),
            
            Text(
              'FAQ (Tanya Jawab)',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textDark),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 16),
            
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppConstants.premiumShadow,
              ),
              child: Column(
                children: [
                  _buildFaqTile('Bagaimana cara mengisi Assessment?', 'Buka menu Beranda, lalu pilih tombol "Mulai Asesmen Kesehatan". Ikuti langkah-langkahnya hingga selesai.'),
                  Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                  _buildFaqTile('Apa arti warna risiko di dashboard?', 'Hijau berarti Aman/Rendah, Kuning berarti Perlu Perhatian/Sedang, dan Merah berarti Risiko Tinggi yang membutuhkan penanganan medis.'),
                  Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                  _buildFaqTile('Bagaimana mengubah data diri?', 'Saat ini fitur ubah data diri masih dalam tahap pengembangan. Hubungi admin jika ada kesalahan nama.'),
                ],
              ),
            ).animate().fade(delay: 500.ms).slideY(begin: 0.1),

            const SizedBox(height: 40),

            Text(
              'Hubungi Kami',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textDark),
            ).animate().fadeIn(delay: 600.ms),
            const SizedBox(height: 16),
            
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppConstants.premiumShadow,
              ),
              child: Column(
                children: [
                  _buildContactTile(Icons.chat_outlined, 'Chat WhatsApp', '+62 812-3456-7890', context),
                  Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                  _buildContactTile(Icons.email_outlined, 'Email Support', 'bantuan@smarthajj.com', context),
                ],
              ),
            ).animate().fade(delay: 700.ms).slideY(begin: 0.1),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqTile(String question, String answer) {
    return ExpansionTile(
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text(question, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppConstants.textDark)),
      iconColor: AppConstants.petugasPrimary,
      collapsedIconColor: Colors.grey,
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Text(
          answer,
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppConstants.textLight, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildContactTile(IconData icon, String title, String subtitle, BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppConstants.petugasPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppConstants.petugasPrimary, size: 24),
      ),
      title: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppConstants.textDark)),
      subtitle: Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppConstants.textLight)),
      trailing: const Icon(Icons.arrow_outward, size: 18, color: Colors.grey),
      onTap: () {
        DynamicIsland.show(context, message: 'Membuka aplikasi eksternal...', type: IslandType.info);
      },
    );
  }
}
