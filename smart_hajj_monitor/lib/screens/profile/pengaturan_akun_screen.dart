import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';
import '../../utils/dynamic_island.dart';
import 'ubah_kata_sandi_screen.dart';
import 'autentikasi_biometrik_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class PengaturanAkunScreen extends StatefulWidget {
  const PengaturanAkunScreen({super.key});

  @override
  State<PengaturanAkunScreen> createState() => _PengaturanAkunScreenState();
}

class _PengaturanAkunScreenState extends State<PengaturanAkunScreen> {
  bool _notifPush = true;
  bool _notifWhatsApp = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifPush = prefs.getBool('notif_push') ?? true;
      _notifWhatsApp = prefs.getBool('notif_whatsapp') ?? false;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Pengaturan Akun',
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
            Text(
              'Preferensi Notifikasi',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textDark),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 16),
            _buildSettingCard([
              _buildSwitchTile('Notifikasi Push', 'Terima pemberitahuan langsung di HP', _notifPush, (val) async {
                if (val) {
                  final status = await Permission.notification.request();
                  if (!status.isGranted) {
                    if (!context.mounted) return;
                    DynamicIsland.show(
                      context,
                      message: 'Aktifkan izin notifikasi di pengaturan HP Anda.⚠️',
                      type: IslandType.error,
                    );
                    return;
                  }
                }
                setState(() => _notifPush = val);
                await _savePreference('notif_push', val);
                if (!context.mounted) return;
                DynamicIsland.show(
                  context,
                  message: val ? '🔔 Notifikasi Push aktif!' : '🔕 Notifikasi Push dinonaktifkan!',
                  type: IslandType.success,
                );
              }),
              Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
              _buildSwitchTile('Notifikasi WhatsApp', 'Terima laporan kesehatan via WhatsApp', _notifWhatsApp, (val) async {
                setState(() => _notifWhatsApp = val);
                await _savePreference('notif_whatsapp', val);
                if (!context.mounted) return;
                DynamicIsland.show(
                  context,
                  message: val ? '💬 Notifikasi WhatsApp aktif!' : '🔕 Notifikasi WhatsApp dinonaktifkan!',
                  type: IslandType.success,
                );
              }),
            ]).animate().fade(delay: 200.ms).slideY(begin: 0.1),

            const SizedBox(height: 32),

            Text(
              'Tampilan',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textDark),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 16),
            _buildSettingCard([
              _buildSwitchTile('Mode Gelap (Dark Mode)', 'Ubah tampilan menjadi gelap', isDark, (val) {
                themeProvider.toggleTheme(val);
                DynamicIsland.show(
                  context,
                  message: val ? '🌙 Mode Gelap diaktifkan!' : '☀️ Mode Terang diaktifkan!',
                  type: IslandType.success,
                );
              }),
            ]).animate().fade(delay: 400.ms).slideY(begin: 0.1),

            const SizedBox(height: 32),

            Text(
              'Keamanan',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textDark),
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 16),
            _buildSettingCard([
              _buildActionTile(Icons.lock_outline, 'Ubah Kata Sandi', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UbahKataSandiScreen()),
                );
              }),
              Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
              _buildActionTile(Icons.fingerprint, 'Autentikasi Biometrik', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AutentikasiBiometrikScreen()),
                );
              }),
            ]).animate().fade(delay: 600.ms).slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppConstants.premiumShadow,
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppConstants.textDark)),
                const SizedBox(height: 4),
                Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppConstants.textLight)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppConstants.petugasPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppConstants.textDark, size: 20),
      ),
      title: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppConstants.textDark)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }
}
