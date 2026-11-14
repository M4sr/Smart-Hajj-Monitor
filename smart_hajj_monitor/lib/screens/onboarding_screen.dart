import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      "lottie": "https://lottie.host/0a7a3b3e-cb19-4dc8-a8ab-a02b48e30b35/P02m1mZ6mD.json",
      "icon": Icons.mosque_rounded,
      "title": "Pemantauan Ibadah",
      "description": "Dapatkan panduan ibadah haji yang lengkap dan pantau progres ibadah Anda setiap saat dengan mudah."
    },
    {
      "lottie": "https://lottie.host/9327d926-ec41-4712-ba2f-fbe29a28cc1f/2qWc8W99B6.json",
      "icon": Icons.health_and_safety_rounded,
      "title": "Pantau Kesehatan",
      "description": "Sistem deteksi dini kami membantu memantau kondisi kesehatan Anda untuk mencegah risiko selama di Tanah Suci."
    },
    {
      "lottie": "https://lottie.host/81a978f8-b3ab-44ea-b903-8be05c56d787/XG2w7gE85A.json",
      "icon": Icons.emergency_share_rounded,
      "title": "Keamanan & Darurat",
      "description": "Dilengkapi dengan tombol SOS pintar yang akan langsung mengirimkan lokasi Anda ke petugas terdekat jika membutuhkan bantuan."
    },
  ];

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : AppConstants.textDark;
    final textLightColor = isDark ? Colors.white70 : AppConstants.textLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            alignment: Alignment.center,
                            child: Lottie.network(
                              _onboardingData[index]['lottie']!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback jika Lottie gagal dimuat dari internet
                                return Icon(
                                  _onboardingData[index]['icon'],
                                  size: 150,
                                  color: AppConstants.jemaahPrimary,
                                ).animate(onPlay: (controller) => controller.repeat())
                                 .shimmer(duration: 2.seconds, color: AppConstants.jemaahAccent);
                              },
                            ),
                          ).animate().fade(duration: 600.ms).scale(delay: 200.ms),
                        ),
                        const SizedBox(height: 40),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              Text(
                                _onboardingData[index]['title']!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                                textAlign: TextAlign.center,
                              ).animate().fade(delay: 400.ms).slideY(begin: 0.2),
                              const SizedBox(height: 16),
                              Text(
                                _onboardingData[index]['description']!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  color: textLightColor,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ).animate().fade(delay: 600.ms).slideY(begin: 0.2),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _onboardingData.length,
                      (index) => _buildDot(index: index),
                    ),
                  ),
                  _currentPage == _onboardingData.length - 1
                      ? ElevatedButton(
                          onPressed: _completeOnboarding,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.jemaahPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                          child: Text(
                            'Mulai',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ).animate().fade().scale()
                      : TextButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.ease,
                            );
                          },
                          child: Text(
                            'Lanjut',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppConstants.jemaahPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot({required int index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? AppConstants.jemaahPrimary : AppConstants.jemaahPrimary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
