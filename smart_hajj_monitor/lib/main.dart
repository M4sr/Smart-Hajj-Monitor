import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/auth_provider.dart';
import 'providers/assessment_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/weather_provider.dart';
import 'providers/theme_provider.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'utils/constants.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_jemaah_screen.dart';
import 'screens/main_petugas_screen.dart';
import 'screens/assessment/form_screen.dart';
import 'screens/assessment/result_screen.dart';
import 'screens/home/riwayat_jemaah_screen.dart';
import 'screens/profile/notification_screen.dart';
import 'screens/home/panduan_ibadah_screen.dart';
import 'screens/home/info_kloter_screen.dart';
import 'screens/home/detail_panduan_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiService.initialize();
  await LocalNotificationService.initialize();
  runApp(const SmartHajjApp());
}

final GoRouter _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/main-jemaah',
      builder: (context, state) => const MainJemaahScreen(),
    ),
    GoRoute(
      path: '/main-petugas',
      builder: (context, state) => const MainPetugasScreen(),
    ),
    GoRoute(
      path: '/assessment-form',
      builder: (context, state) => const AssessmentFormScreen(),
    ),
    GoRoute(
      path: '/result',
      builder: (context, state) => const ResultScreen(),
    ),
    GoRoute(
      path: '/riwayat-jemaah',
      builder: (context, state) => const RiwayatJemaahScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationScreen(),
    ),
    GoRoute(
      path: '/panduan-ibadah',
      builder: (context, state) => const PanduanIbadahScreen(),
    ),
    GoRoute(
      path: '/info-kloter',
      builder: (context, state) => const InfoKloterScreen(),
    ),
    GoRoute(
      path: '/panduan-detail',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return DetailPanduanScreen(
          currentIndex: data['index'] as int,
          items: data['items'] as List<Map<String, dynamic>>,
        );
      },
    ),
  ],
);

class SmartHajjApp extends StatelessWidget {
  const SmartHajjApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AssessmentProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
      ],
      child: const SmartHajjAppContent(),
    );
  }
}

class SmartHajjAppContent extends StatelessWidget {
  const SmartHajjAppContent({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp.router(
      title: 'Smart Hajj Monitor',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: AppConstants.jemaahPrimary,
        scaffoldBackgroundColor: const Color(0xFFF4F7FA),
        cardColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.jemaahPrimary,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppConstants.jemaahPrimary,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.jemaahPrimary,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
