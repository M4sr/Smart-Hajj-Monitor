import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vibration/vibration.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/weather_provider.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/dynamic_island.dart';
import '../profile/profile_screen.dart';
import '../profile/edit_profile_screen.dart';

class DashboardJemaahScreen extends StatefulWidget {
  const DashboardJemaahScreen({super.key});

  @override
  State<DashboardJemaahScreen> createState() => _DashboardJemaahScreenState();
}

class _DashboardJemaahScreenState extends State<DashboardJemaahScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (mounted) {
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotificationProvider>().fetchNotifications();
        context.read<WeatherProvider>().fetchWeather();
        _requestNotificationPermission();
        _checkIncompleteProfile();
      }
    });
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  Future<void> _checkIncompleteProfile() async {
    try {
      final response = await ApiService.dio.get('/users/me');
      if (response.statusCode == 200) {
        final profileData = response.data;
        if (profileData['jenis_kelamin'] == null ||
            profileData['usia'] == null ||
            profileData['usia'] == 0 ||
            profileData['no_hp'] == null) {
          _showIncompleteProfileDialog(profileData);
        }
      }
    } catch (e) {
      // Ignore if fail
    }
  }

  void _showIncompleteProfileDialog(Map<String, dynamic> profileData) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppConstants.jemaahAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: AppConstants.jemaahAccent, size: 48),
                ).animate().scale(curve: Curves.easeOutBack),
                const SizedBox(height: 20),
                Text(
                  'Lengkapi Data Diri',
                  style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: AppConstants.textDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Untuk memastikan fitur seperti pemantauan kesehatan dan SOS berjalan optimal, mohon lengkapi Jenis Kelamin, Usia, dan Nomor HP Anda.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppConstants.textLight, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Nanti Saja',
                          style: GoogleFonts.plusJakartaSans(color: AppConstants.textLight, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.jemaahPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(initialData: profileData),
                            ),
                          );
                        },
                        child: Text(
                          'Lengkapi',
                          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tooltipTimer?.cancel();
    _sosTimer?.cancel();
    _vibrationTimer?.cancel();
    super.dispose();
  }

  Timer? _sosTimer;
  Timer? _vibrationTimer;
  bool _isSosPressed = false;
  DateTime? _pressStartTime;

  bool _showSosTooltip = false;
  Timer? _tooltipTimer;

  void _showTooltip() {
    setState(() => _showSosTooltip = true);
    _tooltipTimer?.cancel();
    _tooltipTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showSosTooltip = false);
    });
  }

  void _startSosTimer(BuildContext context) {
    setState(() {
      _isSosPressed = true;
      _pressStartTime = DateTime.now();
      _showSosTooltip = false; // Sembunyikan tooltip jika sedang ditekan
    });
    
    // Getar pertama kali saat mulai menekan tombol (vibrator langsung)
    Vibration.vibrate(duration: 50);
    
    // Mulai timer getaran periodik setiap 600ms (efek getar progresif)
    _vibrationTimer?.cancel();
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      Vibration.vibrate(duration: 100);
    });

    _sosTimer = Timer(const Duration(seconds: 3), () {
      _vibrationTimer?.cancel();
      setState(() => _isSosPressed = false);
      _triggerSOS(context);
    });
  }

  void _cancelSosTimer(BuildContext context) {
    setState(() => _isSosPressed = false);
    _sosTimer?.cancel();
    _vibrationTimer?.cancel(); // Batalkan getaran progresif

    if (_pressStartTime != null && DateTime.now().difference(_pressStartTime!).inMilliseconds < 1000) {
      _showTooltip();
    }
    _pressStartTime = null;
  }

  Future<void> _triggerSOS(BuildContext context) async {
    _vibrationTimer?.cancel();
    // Getar berpola ganda (double buzz) untuk menandakan SOS sukses terkirim
    Vibration.vibrate(pattern: [0, 200, 100, 250]);
    
    DynamicIsland.show(
      context,
      message: '🚨 Mengambil lokasi GPS...',
      type: IslandType.info,
    );

    try {
      final status = await Permission.locationWhenInUse.request();
      if (!status.isGranted) {
        throw Exception('Izin lokasi ditolak. Tidak dapat mengirim SOS presisi.');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final response = await ApiService.dio.post('/sos/', data: {
        'latitude': position.latitude,
        'longitude': position.longitude,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        DynamicIsland.show(
          context,
          message: '🚨 Sinyal Darurat & Lokasi Terkirim ke Petugas!',
          type: IslandType.error,
        );
      } else {
        throw Exception('Gagal mengirim ke server');
      }
    } catch (e) {
      DynamicIsland.show(
        context,
        message: 'Gagal mengirim lokasi SOS. $e',
        type: IslandType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final unreadCount = context.watch<NotificationProvider>().unreadCount;
    final weatherProvider = context.watch<WeatherProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final double metricValueFontSize = screenWidth < 360 ? 11.5 : (screenWidth < 400 ? 12.5 : 14.0);
    final double sosButtonSize = (screenWidth * 0.16).clamp(56.0, 68.0);
    final double sosIconSize = sosButtonSize * 0.5;
    final double sosBottomPos = 28.0 + (76.0 - sosButtonSize) / 2.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // --- BACKGROUND ANIMATION ---
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [
                          const Color(0xFF121212),
                          const Color(0xFF1E1E1E),
                          const Color(0xFF0C241E),
                          const Color(0xFF121212),
                        ]
                      : [
                          const Color(0xFFE8F5E9),
                          const Color(0xFFF1F8E9),
                          const Color(0xFFF3E5F5),
                          Colors.white,
                        ],
                ),
              ),
            ),
          ),
          // Animated decorative blurred blobs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x334CAF50)),
            ).animate(onPlay: (c) => c.repeat()).moveX(begin: 0, end: 50, duration: 5.seconds).then().moveX(begin: 50, end: 0, duration: 5.seconds),
          ),
          Positioned(
            top: 200,
            right: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x222196F3)),
            ).animate(onPlay: (c) => c.repeat()).moveY(begin: 0, end: -50, duration: 7.seconds).then().moveY(begin: -50, end: 0, duration: 7.seconds),
          ),
          // Frosted Glass Layer over the background blobs
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(color: (Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white).withOpacity(0.4)),
            ),
          ),

          // --- MAIN CONTENT ---
          RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                context.read<NotificationProvider>().fetchNotifications(),
                context.read<WeatherProvider>().fetchWeather(),
              ]);
            },
            color: AppConstants.jemaahPrimary,
            backgroundColor: Colors.white,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Spacer to push content below the fixed header
                        const SizedBox(height: 110),

                        // --- HERO GLASS CARD (Cuaca & Info) ---
                        Transform(
                          transform: Matrix4.identity()
                            ..translate(0.0, _scrollOffset * 0.15) // Parallax translation
                            ..scale(1.0 - ((_scrollOffset / 400.0).clamp(0.0, 1.0) * 0.08)), // Subtle shrink
                          alignment: Alignment.center,
                          child: Opacity(
                            opacity: (1.0 - ((_scrollOffset / 400.0).clamp(0.0, 1.0) * 0.4)).clamp(0.6, 1.0), // Subtle fade
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth < 360 ? 16 : 22,
                                    vertical: screenWidth < 360 ? 20 : 26,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: Theme.of(context).brightness == Brightness.dark
                                          ? [
                                              Colors.black.withValues(alpha: 0.8),
                                              Colors.black.withValues(alpha: 0.5),
                                            ]
                                          : [
                                              Colors.white.withValues(alpha: 0.85),
                                              Colors.white.withValues(alpha: 0.4),
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(32),
                                    border: Border.all(color: (Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.white.withValues(alpha: 0.6)), width: 1.5),
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.05), blurRadius: 30, offset: const Offset(0, 10))],
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        right: -20,
                                        top: -20,
                                        child: Transform.rotate(
                                          angle: _scrollOffset * 0.005, // Gentle rotation on scroll
                                          child: Transform.translate(
                                            offset: Offset(_scrollOffset * 0.12, -_scrollOffset * 0.06), // Drift up and right
                                            child: Icon(weatherProvider.weatherIcon, size: 100, color: weatherProvider.iconColor.withValues(alpha: 0.1))
                                              .animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.1,1.1), duration: 2.seconds),
                                          ),
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.location_on, size: 14, color: Colors.blue),
                                                      const SizedBox(width: 4),
                                                      Flexible(
                                                        child: Text(
                                                          'Mekkah, Arab Saudi',
                                                          overflow: TextOverflow.ellipsis,
                                                          maxLines: 1,
                                                          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                                                        ),
                                                      ),
                                                      if (weatherProvider.isLoading) ...[
                                                        const SizedBox(width: 6),
                                                        const SizedBox(
                                                          width: 10,
                                                          height: 10,
                                                          child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.blue),
                                                        ),
                                                      ]
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const Spacer(),
                                              AnimatedNumberText(
                                                value: weatherProvider.temperature,
                                                suffix: '°C',
                                                decimalPlaces: 1,
                                                style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w900, color: AppConstants.textDark),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                          Text(
                                            weatherProvider.weatherCondition,
                                            style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppConstants.textDark),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            weatherProvider.healthAdvice,
                                            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppConstants.textLight, height: 1.5),
                                          ),
                                          const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 16.0),
                                            child: Divider(color: Colors.black12, height: 1, thickness: 1),
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                                            children: [
                                              Expanded(
                                                child: _buildWeatherMetric(
                                                  icon: Icons.thermostat_outlined,
                                                  valueWidget: AnimatedNumberText(
                                                    value: weatherProvider.apparentTemperature,
                                                    suffix: '°C',
                                                    decimalPlaces: 1,
                                                    style: GoogleFonts.plusJakartaSans(fontSize: metricValueFontSize, fontWeight: FontWeight.w800, color: AppConstants.textDark),
                                                  ),
                                                  label: 'Terasa\nSeperti',
                                                  iconColor: Colors.orange.shade700,
                                                ),
                                              ),
                                              Expanded(
                                                child: _buildWeatherMetric(
                                                  icon: Icons.water_drop_outlined,
                                                  valueWidget: AnimatedNumberText(
                                                    value: weatherProvider.humidity.toDouble(),
                                                    suffix: '%',
                                                    decimalPlaces: 0,
                                                    style: GoogleFonts.plusJakartaSans(fontSize: metricValueFontSize, fontWeight: FontWeight.w800, color: AppConstants.textDark),
                                                  ),
                                                  label: 'Kelembapan',
                                                  iconColor: Colors.blue.shade600,
                                                ),
                                              ),
                                              Expanded(
                                                child: _buildWeatherMetric(
                                                  icon: Icons.air_rounded,
                                                  valueWidget: AnimatedNumberText(
                                                    value: weatherProvider.windSpeed,
                                                    suffix: ' km/h',
                                                    decimalPlaces: 1,
                                                    style: GoogleFonts.plusJakartaSans(fontSize: metricValueFontSize, fontWeight: FontWeight.w800, color: AppConstants.textDark),
                                                  ),
                                                  label: 'Kec. Angin',
                                                  iconColor: Colors.teal.shade600,
                                                ),
                                              ),
                                              Expanded(
                                                child: _buildWeatherMetric(
                                                  icon: Icons.warning_amber_rounded,
                                                  valueWidget: Text(
                                                    weatherProvider.dehydrationRisk,
                                                    style: GoogleFonts.plusJakartaSans(fontSize: metricValueFontSize, fontWeight: FontWeight.w800, color: weatherProvider.dehydrationRiskColor),
                                                  ),
                                                  label: 'Risiko\nDehidrasi',
                                                  iconColor: weatherProvider.dehydrationRiskColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ).animate().fade(delay: 300.ms).slideY(begin: 0.2),

                        const SizedBox(height: 40),

                        // --- LAYANAN KESEHATAN (BENTO UI) ---
                        Text(
                          'Layanan Kesehatan',
                          style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppConstants.textDark, letterSpacing: -0.5),
                        ).animate().fade(delay: 400.ms).slideX(begin: -0.1),
                        const SizedBox(height: 16),
                        
                        Column(
                          children: [
                            _buildGlassBentoCard(
                              context: context,
                              title: 'Lapor Kondisi',
                              subtitle: 'Periksa mandiri',
                              icon: Icons.health_and_safety,
                              gradientColors: [const Color(0xFF0F9D58), const Color(0xFF1B5E20)],
                              onTap: () => context.push('/assessment-form'),
                              delay: 500,
                            ),
                            const SizedBox(height: 16),
                            _buildGlassBentoCard(
                              context: context,
                              title: 'Riwayat Periksa',
                              subtitle: 'Hasil rekam medis',
                              icon: Icons.manage_search_rounded,
                              gradientColors: [const Color(0xFF42A5F5), const Color(0xFF0D47A1)],
                              onTap: () => context.push('/riwayat-jemaah'),
                              delay: 600,
                            ),
                            const SizedBox(height: 16),
                            _buildGlassBentoCard(
                              context: context,
                              title: 'Panduan Ibadah',
                              subtitle: 'Doa & Tata cara',
                              icon: Icons.menu_book_rounded,
                              gradientColors: [const Color(0xFFFFA726), const Color(0xFFE65100)],
                              onTap: () => context.push('/panduan-ibadah'),
                              delay: 700,
                            ),
                          ],
                        ),

                        const SizedBox(height: 120), // Bottom padding for FAB FAB
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          ),

          // --- CIRCULAR FLOATING SOS BUTTON WITH TOOLTIP ---
          Positioned(
            bottom: sosBottomPos,
            right: 24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tooltip Bubble
                if (_showSosTooltip)
                  Container(
                    margin: const EdgeInsets.only(right: 12, bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Tahan 3 detik!',
                          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ).animate().fade().slideX(begin: 0.2, end: 0, curve: Curves.easeOutBack),

                GestureDetector(
                  onTapDown: (_) => _startSosTimer(context),
                  onTapUp: (_) => _cancelSosTimer(context),
                  onTapCancel: () => _cancelSosTimer(context),
                  child: AnimatedScale(
                    scale: _isSosPressed ? 0.8 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: sosButtonSize,
                      height: sosButtonSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5252), Color(0xFFC62828)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_isSosPressed)
                            SizedBox(
                              width: sosButtonSize,
                              height: sosButtonSize,
                              child: const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 4,
                              ),
                            ),
                          Icon(Icons.sos_rounded, color: Colors.white, size: sosIconSize),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- PERSISTENT ANIMATED HEADER ---
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: (20.0 * (_scrollOffset / 100.0).clamp(0.0, 1.0)).clamp(0.001, 20.0),
                  sigmaY: (20.0 * (_scrollOffset / 100.0).clamp(0.0, 1.0)).clamp(0.001, 20.0),
                ),
                child: Container(
                  height: (120.0 - (46.0 * (_scrollOffset / 100.0).clamp(0.0, 1.0))) + MediaQuery.of(context).padding.top,
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top,
                    left: 24,
                    right: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withValues(alpha: 0.85 * (_scrollOffset / 100.0).clamp(0.0, 1.0)),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.black12.withValues(alpha: 0.05 * (_scrollOffset / 100.0).clamp(0.0, 1.0)),
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if ((_scrollOffset / 100.0).clamp(0.0, 1.0) < 0.85)
                              Opacity(
                                opacity: (1.0 - (_scrollOffset / 100.0).clamp(0.0, 1.0) * 1.5).clamp(0.0, 1.0),
                                child: SizedBox(
                                  height: 18.0 * (1.0 - (_scrollOffset / 100.0).clamp(0.0, 1.0)).clamp(0.0, 1.0),
                                  child: Text(
                                    'Assalamu\'alaikum,',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppConstants.textLight,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            Text(
                              user?.nama ?? 'Jemaah',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppConstants.textDark,
                                fontSize: 24.0 - (5.0 * (_scrollOffset / 100.0).clamp(0.0, 1.0)),
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Stack(
                            children: [
                              IconButton(
                                icon: Icon(Icons.notifications_outlined, color: AppConstants.textDark, size: 28),
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
                                      border: Border.all(color: Colors.white, width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.redAccent.withValues(alpha: 0.4),
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
                                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                                   .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 1.seconds),
                                ),
                            ],
                          ).animate().fade(delay: 150.ms).slideX(begin: 0.2),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ProfileScreen()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(colors: [AppConstants.jemaahPrimary, Colors.blueAccent]),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppConstants.jemaahPrimary.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 22.0 - (4.0 * (_scrollOffset / 100.0).clamp(0.0, 1.0)),
                                backgroundColor: Colors.white,
                                backgroundImage: user?.fotoProfil != null
                                    ? NetworkImage('${AppConstants.baseUrl}/${user!.fotoProfil!}')
                                    : null,
                                child: user?.fotoProfil == null ? Icon(
                                  Icons.person,
                                  color: AppConstants.jemaahPrimary,
                                  size: 24.0 - (4.0 * (_scrollOffset / 100.0).clamp(0.0, 1.0)),
                                ) : null,
                              ),
                            ).animate().fade(delay: 200.ms).scale(curve: Curves.easeOutBack),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassBentoCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    required int delay,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 120,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
              boxShadow: [
                BoxShadow(color: gradientColors.last.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.75),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
              ],
            ),
          ),
        ),
      ).animate().fade(delay: delay.ms).scale(curve: Curves.easeOutBack, duration: 600.ms),
    );
  }

  Widget _buildWeatherMetric({
    required IconData icon,
    required Widget valueWidget,
    required String label,
    required Color iconColor,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double labelFontSize = screenWidth < 360 ? 8.0 : (screenWidth < 400 ? 9.0 : 10.0);
    final double iconSize = screenWidth < 360 ? 16.0 : 18.0;
    final double padding = screenWidth < 360 ? 6.0 : 8.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: iconSize, color: iconColor),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: valueWidget,
          ),
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: labelFontSize,
              fontWeight: FontWeight.bold,
              color: AppConstants.textLight,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class AnimatedNumberText extends StatefulWidget {
  final double value;
  final String suffix;
  final Duration duration;
  final int decimalPlaces;
  final TextStyle style;

  const AnimatedNumberText({
    super.key,
    required this.value,
    this.suffix = '',
    this.duration = const Duration(milliseconds: 1000),
    this.decimalPlaces = 0,
    required this.style,
  });

  @override
  State<AnimatedNumberText> createState() => _AnimatedNumberTextState();
}

class _AnimatedNumberTextState extends State<AnimatedNumberText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _oldValue = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: 0.0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
    _oldValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant AnimatedNumberText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _oldValue = oldWidget.value;
      _animation = Tween<double>(begin: _oldValue, end: widget.value).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final val = _animation.value;
        final text = val.toStringAsFixed(widget.decimalPlaces);
        return Text(
          '$text${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}
