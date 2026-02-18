import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  late AnimationController _iconAnimationController;
  late AnimationController _textAnimationController;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.calendar_month_rounded,
      title: 'Easy Booking & Scheduling',
      description:
          'Book water sports equipment with just a few taps. Choose your preferred time slot and get instant confirmation.',
      gradientColors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
    ),
    OnboardingPage(
      icon: Icons.payments_rounded,
      title: 'Secure Payments & Reviews',
      description:
          'Pay securely through multiple payment methods. Read reviews and ratings to make informed decisions.',
      gradientColors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
    ),
    OnboardingPage(
      icon: Icons.beach_access_rounded,
      title: 'Explore Local Beaches',
      description:
          'Discover the best beaches that Aotearoa, New Zealand has to offer.',
      gradientColors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _iconAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _iconScaleAnimation = CurvedAnimation(
      parent: _iconAnimationController,
      curve: Curves.elasticOut,
    );
    
    _textFadeAnimation = CurvedAnimation(
      parent: _textAnimationController,
      curve: Curves.easeOutCubic,
    );
    
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _iconAnimationController.forward();
    _textAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _iconAnimationController.dispose();
    _textAnimationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _currentPage = index;
    });
    
    _iconAnimationController.reset();
    _textAnimationController.reset();
    _iconAnimationController.forward();
    _textAnimationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Subtle animated background shapes
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: WaveBackgroundPainter(
                      progress: _currentPage / (_pages.length - 1),
                      color: _pages[_currentPage].gradientColors[0],
                    ),
                  );
                },
              ),
            ),
            
            Column(
              children: [
                // Skip Button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, right: 8),
                    child: TextButton(
                      onPressed: () => _goToLogin(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary.withOpacity(0.7),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Skip',
                            style: TextStyle(
                              color: AppColors.primary.withOpacity(0.7),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: AppColors.primary.withOpacity(0.7),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: _onPageChanged,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _buildPage(_pages[index], isTablet);
                    },
                  ),
                ),

                // Page Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => _buildIndicator(index == _currentPage, index),
                  ),
                ),

                const SizedBox(height: 40),

                // Navigation Buttons - Centered on first page, side-by-side on others
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _currentPage == 0
                      ? _buildCenteredButton()
                      : _buildSideBySideButtons(),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Centered button for first page
  Widget _buildCenteredButton() {
    return Padding(
      key: const ValueKey('centered'),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          _pageController.nextPage(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 240,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withBlue(200),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Side-by-side buttons for pages 2+
  Widget _buildSideBySideButtons() {
    return Padding(
      key: const ValueKey('sideBySide'),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _pageController.previousPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
              );
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: Colors.grey[600],
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Next/Get Started Button
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                if (_currentPage < _pages.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                  );
                } else {
                  _goToLogin();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withBlue(200),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _currentPage < _pages.length - 1 
                              ? Icons.arrow_forward_rounded 
                              : Icons.check_rounded,
                          key: ValueKey(_currentPage),
                          color: Colors.white,
                          size: 20,
                        ),
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

  Widget _buildPage(OnboardingPage page, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 60 : 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Icon Container
          ScaleTransition(
            scale: _iconScaleAnimation,
            child: Container(
              width: isTablet ? 180 : 140,
              height: isTablet ? 180 : 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: page.gradientColors,
                ),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: page.gradientColors[1].withOpacity(0.4),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                    spreadRadius: -10,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    blurRadius: 20,
                    offset: const Offset(-10, -10),
                  ),
                ],
              ),
              child: Icon(
                page.icon,
                size: isTablet ? 80 : 60,
                color: AppColors.primary,
              ),
            ),
          ),

          SizedBox(height: isTablet ? 64 : 56),

          // Animated Text Content
          FadeTransition(
            opacity: _textFadeAnimation,
            child: SlideTransition(
              position: _textSlideAnimation,
              child: Column(
                children: [
                  // Title
                  Text(
                    page.title,
                    style: TextStyle(
                      fontSize: isTablet ? 34 : 28,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A2E),
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  // Description
                  Text(
                    page.description,
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      color: const Color(0xFF6B7280),
                      height: 1.6,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(bool isActive, int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 8,
      width: isActive ? 32 : 8,
      decoration: BoxDecoration(
        gradient: isActive ? LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.7),
          ],
        ) : null,
        color: isActive ? null : Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
        boxShadow: isActive ? [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ] : null,
      ),
    );
  }

  void _goToLogin() async {
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
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradientColors;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradientColors,
  });
}

// Custom painter for subtle wave background
class WaveBackgroundPainter extends CustomPainter {
  final double progress;
  final Color color;

  WaveBackgroundPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.03)
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = size.height * 0.3;
    final waveWidth = size.width;
    
    path.moveTo(0, size.height);
    
    for (double x = 0; x <= waveWidth; x += 10) {
      final y = size.height - waveHeight + 
                20 * (progress + 1) * 
                (0.5 + 0.5 * (x / waveWidth - 0.5).abs()) * 
                (x / waveWidth < 0.5 ? 1 : -1);
      path.lineTo(x, y);
    }
    
    path.lineTo(waveWidth, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}