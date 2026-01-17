import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../core/theme/app_colors.dart';
import 'onboarding/onboarding_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _waveController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Fade/scale animation for logo
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve:  Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.elasticOut),
    );

    // Wave animation (continuous)
    _waveController = AnimationController(
      duration:  const Duration(seconds: 3),
      vsync: this,
    )..repeat(); // Loops forever

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _navigateToOnboarding() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset. zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin:  begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // ✅ THREE SIZE TIERS
    final isTablet = screenWidth > 600;
    final isLargeTablet = screenWidth > 1000;

    return Scaffold(
      body: Stack(
        children: [
          // Blue Top Section
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom:  MediaQuery.of(context).size.height * (isTablet ?  0.35 : 0.4),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary,
                    AppColors.primaryLight,
                  ],
                ),
              ),
            ),
          ),

          // White Bottom Section
          Positioned(
            top: MediaQuery.of(context).size.height * (isTablet ? 0.65 :  0.6),
            left: 0,
            right:  0,
            bottom: 0,
            child: Container(
              color: Colors.white,
            ),
          ),

          // ✅ Animated Wave - UPDATED FOR LARGE TABLETS
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(
                    MediaQuery. of(context).size.width,
                    isLargeTablet ? 600    // ✅ iPad Pro 12"+
                        : isTablet ? 400   // Regular tablets
                        : 250,             // Phones
                  ),
                  painter: WavePainter(
                    animationValue: _waveController.value,
                    isTablet: isTablet,
                    isLargeTablet: isLargeTablet,  // ✅ Pass new flag
                  ),
                );
              },
            ),
          ),

          // Content (Logo, Text, Button)
          SafeArea(
            child: Column(
              children: [
                // Top section with logo and text
                Expanded(
                  child: Center(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child:  ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          mainAxisAlignment:  MainAxisAlignment.center,
                          children: [
                            // Logo/Icon with gradient
                            Container(
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
                                    color: Colors. black.withOpacity(0.15),
                                    blurRadius:  20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'lib/assets/images/paddologo.png',  // Now with transparent background
                                fit: BoxFit.contain,  // Fits nicely with padding
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // App Name
                            Text(
                              'Paddlme',
                              style: GoogleFonts.museoModerno( 
                                fontSize: isTablet ? 52 : 42,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Tagline
                            Text(
                              'Share the Waves',
                              style: TextStyle(
                                fontSize: isTablet ? 20 : 16,
                                color: Colors.white70,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom section with button
                FadeTransition(
                  opacity:  _fadeAnimation,
                  child:  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ?  60 : 32,
                      vertical: isTablet ? 60 : 40,
                    ),
                    child: Column(
                      children: [
                        // Tagline in white section
                        Text(
                          'Rent kayaks, SUP boards & more from Aotearoa locals',
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            color: Colors. grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        SizedBox(height: isTablet ? 32 : 24),
                        
                        // Get Started Button
                        ElevatedButton(
                          onPressed: _navigateToOnboarding,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: AppColors. primary.withOpacity(0.4),
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 60 : 40,  // ✅ Horizontal padding
                              vertical: 16,                     // ✅ Vertical padding
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,  // ✅ Important!  Shrinks to fit content
                            children: [
                              Text(
                                'Get Started',
                                style: TextStyle(
                                  fontSize: isTablet ? 20 : 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 24,
                              ),
                            ],
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

// Custom Wave Painter - ✅ UPDATED FOR ALL SCREEN SIZES
class WavePainter extends CustomPainter {
  final double animationValue;
  final bool isTablet;
  final bool isLargeTablet;

  WavePainter({
    required this.animationValue,
    this.isTablet = false,
    this.isLargeTablet = false,  // ✅ NEW
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment. bottomCenter,
        colors: [
          AppColors.primaryLight,
          AppColors.primaryLight.withOpacity(0.7),
          Colors.white. withOpacity(0.5),
          Colors.white,
        ],
        stops: const [0.0, 0.25, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);

    // ✅ RESPONSIVE WAVE PARAMETERS
    final double waveHeight = isLargeTablet 
        ? 60.0      // iPad Pro 12"+
        : isTablet 
            ? 40.0  // Regular tablets
            : 25.0; // Phones
    
    final double waveFrequency = isLargeTablet 
        ? 1.2       // Slower, smoother waves for big screens
        : isTablet 
            ? 1.5 
            : 2.0;

    // Draw wave
    for (double i = 0; i <= size.width; i++) {
      final double y = size.height * 0.3 +
          math.sin((i / size.width * waveFrequency * math.pi) + 
                   (animationValue * 2 * math.pi)) * waveHeight;
      path.lineTo(i, y);
    }

    // Complete the path
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.isTablet != isTablet ||
           oldDelegate. isLargeTablet != isLargeTablet;  // ✅ NEW
  }
}


  