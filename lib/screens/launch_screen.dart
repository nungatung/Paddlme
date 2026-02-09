import 'package:flutter/material.dart';
import 'package:wave_share/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wave_share/services/notification_service.dart';
import '../core/theme/app_colors.dart';
import 'splash_screen.dart';
import 'main_navigation.dart';

/// Simple instant logo screen (like Trade Me)
class LaunchScreen extends StatefulWidget {
  final NotificationService? notificationService;
  const LaunchScreen({super.key, this.notificationService,});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Show logo for 1.5 seconds
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // Check auth status
    final authService = AuthService();
    final isLoggedIn = authService.currentUser != null;

    // Check onboarding status
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (!mounted) return;

    Widget destination;

    if (isLoggedIn) {
      // ✅ Logged in → Go straight home
      destination = MainNavigation(notificationService: widget.notificationService);
    } else if (hasSeenOnboarding) {
      // ✅ Seen onboarding but logged out → Skip splash, go to login
      // We'll handle this in splash screen
      destination = const SplashScreen();
    } else {
      // ✅ First time user → Show full splash with "Get Started" button
      destination = const SplashScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Dark background like Trade Me
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with subtle animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.8 + (value * 0.2),
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primaryLight,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Image.asset(
                  'lib/assets/images/paddologo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}