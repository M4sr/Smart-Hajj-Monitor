import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../../services/notification_service.dart';

class SosMapScreen extends StatefulWidget {
  final ValueChanged<bool>? onListVisibilityChanged;
  const SosMapScreen({super.key, this.onListVisibilityChanged});

  @override
  State<SosMapScreen> createState() => _SosMapScreenState();
}

class _SosMapScreenState extends State<SosMapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  List<dynamic> _activeSos = [];
  Timer? _refreshTimer;
  int _countdown = 10;
  bool _isLoading = true;
  bool _showList = false;
  int? _focusedSosId;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _fetchSosData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _countdown--);
      if (_countdown <= 0) {
        _fetchSosData();
        setState(() => _countdown = 10);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchSosData() async {
    try {
      final res = await ApiService.dio.get('/sos/active');
      if (res.statusCode == 200 && mounted) {
        final List<dynamic> newData = List<dynamic>.from(res.data);
        
        // Cek jika ada SOS baru (panjang array bertambah)
        if (!_isLoading && newData.length > _activeSos.length) {
          final newSos = newData.firstWhere(
            (n) => !_activeSos.any((o) => o['id'] == n['id']),
            orElse: () => newData[0],
          );
          final user = newSos['user'];
          
          LocalNotificationService.showNotification(
            id: newSos['id'] ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: '🚨 Darurat SOS Aktif!',
            body: 'Jemaah ${user?['nama'] ?? ''} menekan tombol SOS. Buka Peta SOS segera!',
          );
        }

        setState(() {
          _activeSos = newData;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setShowList(bool value) {
    setState(() => _showList = value);
    widget.onListVisibilityChanged?.call(value);
  }

  void _focusMarker(dynamic sos) {
    _mapController.move(
        LatLng(sos['latitude'] as double, sos['longitude'] as double), 16.5);
    setState(() {
      _focusedSosId = sos['id'];
    });
    _setShowList(false);
    HapticFeedback.mediumImpact();
    _showDetails(sos);
  }

  Future<void> _resolve(dynamic sos, BuildContext sheetCtx) async {
    try {
      await ApiService.dio.put('/sos/${sos['id']}/resolve');
      if (mounted) Navigator.of(sheetCtx).pop();
      _fetchSosData();
      setState(() => _focusedSosId = null);
      HapticFeedback.heavyImpact();
      _snack('✅ Kasus telah ditandai selesai', Colors.green);
    } catch (_) {
      _snack('❌ Gagal memperbarui status', Colors.red);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.plusJakartaSans(
              color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
    ));
  }

  String _fmtTime(String? ts) {
    if (ts == null) return '-';
    try {
      return DateFormat('HH:mm • dd MMM').format(DateTime.parse(ts).toLocal());
    } catch (_) {
      return '-';
    }
  }

  // ─────────────────────────────────────────
  //  BOTTOM SHEET
  // ─────────────────────────────────────────
  void _showDetails(dynamic sos) {
    final user = sos['user'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C2333) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 24,
                    offset: const Offset(0, -4))
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2)),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row
                        Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                AnimatedBuilder(
                                  animation: _pulseAnim,
                                  builder: (_, __) => Container(
                                    width: 56 * _pulseAnim.value,
                                    height: 56 * _pulseAnim.value,
                                    decoration: BoxDecoration(
                                      color: Colors.red
                                          .withOpacity(0.12 * _pulseAnim.value),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFF5252),
                                        Color(0xFFB71C1C)
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.red.withOpacity(0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4))
                                    ],
                                  ),
                                  child: const Icon(Icons.sos_rounded,
                                      color: Colors.white, size: 28),
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text('🚨 DARURAT AKTIF',
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.red)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?['nama'] ?? 'Jemaah Tidak Diketahui',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1A1D1E)),
                                  ),
                                  Text(
                                    '${user?['usia'] ?? '-'} Thn • ${user?['jenis_kelamin'] ?? '-'}',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Info cards
                        Row(
                          children: [
                            _infoCard(
                                Icons.access_time_rounded,
                                'Waktu',
                                _fmtTime(sos['timestamp']),
                                Colors.orange,
                                isDark),
                            const SizedBox(width: 8),
                            _infoCard(
                                Icons.phone_rounded,
                                'No. HP',
                                user?['no_hp'] ?? '-',
                                Colors.blue,
                                isDark),
                            const SizedBox(width: 8),
                            _infoCard(
                                Icons.location_on_rounded,
                                'Lokasi',
                                '${(sos['latitude'] as double).toStringAsFixed(4)},\n${(sos['longitude'] as double).toStringAsFixed(4)}',
                                Colors.green,
                                isDark),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: _actionBtn(
                                icon: Icons.chat_rounded,
                                label: 'WhatsApp',
                                color: const Color(0xFF25D366),
                                onTap: () {
                                  if (user?['no_hp'] != null) {
                                    String phone = user['no_hp'];
                                    if (phone.startsWith('0')) {
                                      phone = '+62${phone.substring(1)}';
                                    }
                                    launchUrl(Uri.parse('https://wa.me/$phone'),
                                        mode: LaunchMode.externalApplication);
                                  } else {
                                    _snack('📵 Nomor tidak tersedia',
                                        Colors.orange);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _actionBtn(
                                icon: Icons.directions_rounded,
                                label: 'Navigasi',
                                color: const Color(0xFF1E88E5),
                                onTap: () {
                                  launchUrl(
                                    Uri.parse(
                                        'https://www.google.com/maps/dir/?api=1&destination=${sos['latitude']},${sos['longitude']}'),
                                    mode: LaunchMode.externalApplication,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _actionBtn(
                                icon: Icons.call_rounded,
                                label: 'Telepon',
                                color: const Color(0xFF7B1FA2),
                                onTap: () {
                                  if (user?['no_hp'] != null) {
                                    launchUrl(
                                        Uri.parse('tel:${user['no_hp']}'));
                                  }
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Resolve
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _resolve(sos, sheetCtx),
                            icon: const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 18),
                            label: Text('Tandai Sudah Ditangani',
                                style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green.shade600,
                              side:
                                  BorderSide(color: Colors.green.shade400),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),

                        SizedBox(
                            height:
                                MediaQuery.of(context).padding.bottom + 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
  }

  // ─────────────────────────────────────────
  //  HELPER WIDGETS
  // ─────────────────────────────────────────
  Widget _infoCard(
      IconData icon, String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.12 : 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 5),
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color:
                        isDark ? Colors.white : const Color(0xFF1A1D1E)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [color.withOpacity(0.85), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _fab({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    String? label,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: label != null
            ? const EdgeInsets.symmetric(horizontal: 12)
            : const EdgeInsets.all(0),
        width: label != null ? null : 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ]
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final n = _activeSos.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F2036),
      body: Stack(
        children: [
          // MAP
          _buildMap(),

          // HEADER
          _buildHeader(isDark, n),

          // FAB CONTROLS
          Positioned(
            right: 14,
            bottom: 110,
            child: Column(
              children: [
                _fab(
                  icon: Icons.refresh_rounded,
                  color: const Color(0xFF1E3A5F),
                  onTap: () {
                    _fetchSosData();
                    setState(() => _countdown = 10);
                    HapticFeedback.lightImpact();
                  },
                ),
                const SizedBox(height: 10),
                _fab(
                  icon: Icons.add_rounded,
                  color: const Color(0xFF1E3A5F),
                  onTap: () {
                    final z = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, z + 1);
                  },
                ),
                const SizedBox(height: 10),
                _fab(
                  icon: Icons.remove_rounded,
                  color: const Color(0xFF1E3A5F),
                  onTap: () {
                    final z = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, z - 1);
                  },
                ),
                const SizedBox(height: 10),
                _fab(
                  icon: _showList ? Icons.map_rounded : Icons.list_alt_rounded,
                  label: _showList ? 'Peta' : 'Daftar',
                  color: _showList
                      ? const Color(0xFF1565C0)
                      : const Color(0xFF1E3A5F),
                  onTap: () => _setShowList(!_showList),
                ),
              ],
            ),
          ),

          // Transparent overlay — tap outside list to close
          if (_showList)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => _setShowList(false),
                child: const SizedBox.expand(),
              ),
            ),

          // SOS LIST PANEL (absorbs its own taps)
          if (_showList) _buildSosList(isDark),

          // EMPTY STATE
          if (!_isLoading && n == 0 && !_showList) _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _activeSos.isNotEmpty
            ? LatLng(_activeSos[0]['latitude'] as double,
                _activeSos[0]['longitude'] as double)
            : const LatLng(21.4225, 39.8262),
        initialZoom: 14.0,
        maxZoom: 19,
        minZoom: 4,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.masrul.smarthajj',
        ),
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => MarkerLayer(
            markers: _activeSos.map((sos) {
              final focused = _focusedSosId == sos['id'];
              return Marker(
                point: LatLng(
                    sos['latitude'] as double, sos['longitude'] as double),
                width: 80,
                height: 80,
                child: GestureDetector(
                  onTap: () => _focusMarker(sos),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 70 * _pulseAnim.value,
                        height: 70 * _pulseAnim.value,
                        decoration: BoxDecoration(
                          color:
                              Colors.red.withOpacity(0.13 * _pulseAnim.value),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 46 * (_pulseAnim.value * 0.7 + 0.3),
                        height: 46 * (_pulseAnim.value * 0.7 + 0.3),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: focused ? 38 : 30,
                        height: focused ? 38 : 30,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF5252), Color(0xFFB71C1C)],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white,
                              width: focused ? 2.5 : 1.5),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.red.withOpacity(0.6),
                                blurRadius: 14,
                                spreadRadius: 2)
                          ],
                        ),
                        child: const Icon(Icons.sos_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isDark, int n) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            bottom: 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xDD0F2036), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pusat Komando SOS',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(
                            color: Color(0xFF00E676), shape: BoxShape.circle),
                      ).animate(onPlay: (c) => c.repeat(reverse: true))
                          .fadeOut(duration: 900.ms),
                      Text('Refresh dalam $_countdown detik',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11, color: Colors.white60)),
                    ],
                  ),
                ],
              ),
            ),
            if (n > 0)
              GestureDetector(
                onTap: () => _focusMarker(_activeSos[0]),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFFF5252), Color(0xFFB71C1C)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.red.withOpacity(0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sos_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text('$n Darurat',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(width: 6),
                      const Icon(Icons.my_location_rounded,
                          color: Colors.white70, size: 13),
                    ],
                  ),
                ),
              ).animate().scale(curve: Curves.easeOutBack)
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_rounded,
                        color: Color(0xFF00E676), size: 16),
                    const SizedBox(width: 6),
                    Text('Aman',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00E676))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSosList(bool isDark) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.52),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C2333) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, -4))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Row(
                children: [
                  Text('Daftar SOS Aktif',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1A1D1E))),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${_activeSos.length} Aktif',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.red)),
                  ),
                ],
              ),
            ),
            Flexible(
              child: _activeSos.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              size: 48, color: Color(0xFF00E676)),
                          const SizedBox(height: 12),
                          Text('Tidak ada kejadian darurat saat ini',
                              style: GoogleFonts.plusJakartaSans(
                                  color: Colors.grey.shade500)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                      shrinkWrap: true,
                      itemCount: _activeSos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final sos = _activeSos[i];
                        final user = sos['user'];
                        return GestureDetector(
                          onTap: () => _focusMarker(sos),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: Colors.red.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      Color(0xFFFF5252),
                                      Color(0xFFB71C1C)
                                    ]),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.sos_rounded,
                                      color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user?['nama'] ??
                                            'Jemaah Tidak Diketahui',
                                        style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF1A1D1E)),
                                      ),
                                      Text(
                                        '🕐 ${_fmtTime(sos['timestamp'])}',
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded,
                                    color: Colors.red),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: (i * 60).ms).slideX(begin: 0.08);
                      },
                    ),
            ),
          ],
        ),
      ).animate().slideY(begin: 1, end: 0, curve: Curves.easeOutCubic),
    );
  }

  Widget _buildEmptyState() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.72),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.shield_rounded,
                  color: Color(0xFF00E676), size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Semua Aman',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    Text('Tidak ada laporan darurat saat ini',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, color: Colors.white60)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn().slideY(begin: 0.3),
    );
  }
}
