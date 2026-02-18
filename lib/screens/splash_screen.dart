import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../core/theme/app_colors.dart';
import 'onboarding/onboarding_screen.dart';
import 'auth/login_screen.dart';  
import 'package:shared_preferences/shared_preferences.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _waveController;
  late AnimationController _breatheController;
  late AnimationController _shimmerController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _breatheAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    
    // Main fade/scale animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController, 
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController, 
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // Subtle breathing animation for logo
    _breatheController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _breatheAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(
        parent: _breatheController,
        curve: Curves.easeInOutSine,
      ),
    );

    // Shimmer for button
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _shimmerController,
        curve: Curves.easeInOutSine,
      ),
    );

    // Wave animation
    _waveController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    // Sequence the animations
    _fadeController.forward().then((_) {
      _breatheController.repeat(reverse: true);
      _shimmerController.repeat();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _waveController.dispose();
    _breatheController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _navigateToOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _navigateToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    final isTablet = screenWidth > 600;
    final isLargeTablet = screenWidth > 1000;

    return Scaffold(
      body: Stack(
        children: [
          // Blue Top Section with subtle animated gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: screenHeight * (isTablet ? 0.35 : 0.4),
            child: AnimatedBuilder(
              animation: _breatheController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.lerp(AppColors.primary, AppColors.primary.withBlue(220), 
                          (_breatheAnimation.value - 1) * 0.3) ?? AppColors.primary,
                        Color.lerp(AppColors.primaryLight, AppColors.primaryLight.withBlue(240), 
                          (_breatheAnimation.value - 1) * 0.3) ?? AppColors.primaryLight,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // White Bottom Section
          Positioned(
            top: screenHeight * (isTablet ? 0.65 : 0.6),
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.white,
            ),
          ),

          // Dual Wave Layers for depth
          Positioned(
            top: screenHeight * 0.35,
            left: 0,
            right: 0,
            child: Stack(
              children: [
                // Background wave (slower, softer)
                AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(
                        screenWidth,
                        isLargeTablet ? 600 : isTablet ? 400 : 250,
                      ),
                      painter: WavePainter(
                        animationValue: _waveController.value * 0.7,
                        isTablet: isTablet,
                        isLargeTablet: isLargeTablet,
                        opacity: 0.5,
                        waveHeight: isLargeTablet ? 45 : isTablet ? 30 : 18,
                      ),
                    );
                  },
                ),
                // Foreground wave
                AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(
                        screenWidth,
                        isLargeTablet ? 600 : isTablet ? 400 : 250,
                      ),
                      painter: WavePainter(
                        animationValue: _waveController.value,
                        isTablet: isTablet,
                        isLargeTablet: isLargeTablet,
                        opacity: 1.0,
                        waveHeight: isLargeTablet ? 60 : isTablet ? 40 : 25,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo with breathing animation
                            AnimatedBuilder(
                              animation: _breatheAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _breatheAnimation.value,
                                  child: Container(
                                    width: isTablet ? 160 : 140,
                                    height: isTablet ? 160 : 140,
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppColors.primary,
                                          AppColors.primaryLight,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(0.3),
                                          blurRadius: 30,
                                          offset: const Offset(0, 15),
                                          spreadRadius: -5,
                                        ),
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.3),
                                          blurRadius: 20,
                                          offset: const Offset(-5, -5),
                                        ),
                                      ],
                                    ),
                                    child: Image.asset(
                                      'lib/assets/images/paddologo.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                );
                              },
                            ),
                            
                            const SizedBox(height: 28),
                            
                            // App Name with letter spacing animation
                            AnimatedBuilder(
                              animation: _fadeController,
                              builder: (context, child) {
                                final spacing = Tween<double>(begin: 0.5, end: 1.2)
                                    .animate(CurvedAnimation(
                                      parent: _fadeController,
                                      curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
                                    ));
                                return Text(
                                  'Paddlme',
                                  style: TextStyle(
                                    fontFamily: 'GlacialIndifference',
                                    fontSize: isTablet ? 52 : 42,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: spacing.value,
                                  ),
                                );
                              },
                            ),
                            
                            const SizedBox(height: 10),
                            
                            // Tagline with delayed fade
                            FadeTransition(
                              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                                CurvedAnimation(
                                  parent: _fadeController,
                                  curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                                ),
                              ),
                              child: Text(
                                'Share the Waves',
                                style: TextStyle(
                                  fontFamily: 'GlacialIndifference',
                                  fontSize: isTablet ? 20 : 16,
                                  color: Colors.white.withOpacity(0.85),
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom section with staggered fade
                FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _fadeController,
                      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 60 : 32,
                      vertical: isTablet ? 60 : 40,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Rent kayaks, SUP boards & more from Aotearoa locals',
                          style: TextStyle(
                            fontFamily: 'GlacialIndifference',
                            fontSize: isTablet ? 18 : 16,
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        SizedBox(height: isTablet ? 36 : 28),
                        
                        // Shimmer button
                        GestureDetector(
                          onTap: _navigateToOnboarding,
                          child: AnimatedBuilder(
                            animation: _shimmerAnimation,
                            builder: (context, child) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primary.withBlue(200),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                      spreadRadius: -4,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    // Shimmer overlay
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: AnimatedBuilder(
                                          animation: _shimmerAnimation,
                                          builder: (context, child) {
                                            return FractionallySizedBox(
                                              alignment: Alignment.centerLeft,
                                              widthFactor: 0.3,
                                              child: Transform.translate(
                                                offset: Offset(
                                                  _shimmerAnimation.value * 300,
                                                  0,
                                                ),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Colors.white.withOpacity(0),
                                                        Colors.white.withOpacity(0.3),
                                                        Colors.white.withOpacity(0),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    // Button content
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isTablet ? 60 : 40,
                                        vertical: 16,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Get Started',
                                            style: TextStyle(
                                              fontFamily: 'GlacialIndifference',
                                              fontSize: isTablet ? 20 : 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 24,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        
                        SizedBox(height: isTablet ? 20 : 16),
                        
                        // Refined text button with hover effect
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: _navigateToLogin,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Already have an account? Log In',
                                style: TextStyle(
                                  fontFamily: 'GlacialIndifference',
                                  fontSize: isTablet ? 14 : 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary.withOpacity(0.8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced Wave Painter with opacity control
class WavePainter extends CustomPainter {
  final double animationValue;
  final bool isTablet;
  final bool isLargeTablet;
  final double opacity;
  final double waveHeight;

  WavePainter({
    required this.animationValue,
    this.isTablet = false,
    this.isLargeTablet = false,
    this.opacity = 1.0,
    this.waveHeight = 25.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primaryLight.withOpacity(opacity),
          AppColors.primaryLight.withOpacity(opacity * 0.7),
          Colors.white.withOpacity(opacity * 0.5),
          Colors.white,
        ],
        stops: const [0.0, 0.25, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);

    final double waveFrequency = isLargeTablet ? 1.2 : isTablet ? 1.5 : 2.0;

    for (double i = 0; i <= size.width; i++) {
      final double y = size.height * 0.3 +
          math.sin((i / size.width * waveFrequency * math.pi) + 
                   (animationValue * 2 * math.pi)) * waveHeight;
      path.lineTo(i, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.opacity != opacity ||
           oldDelegate.waveHeight != waveHeight;
  }
}