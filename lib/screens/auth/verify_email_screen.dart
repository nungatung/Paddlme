import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../main_navigation.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  final String name;

  const VerifyEmailScreen({
    super.key,
    required this.email,
    required this.name,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> with TickerProviderStateMixin {
  final _authService = AuthService();
  bool _isResending = false;
  bool _isChecking = false;
  int _resendCountdown = 0;
  Timer? _resendTimer;
  Timer? _checkTimer;
  DateTime? _lastChecked;
  
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _checkController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutSine,
      ),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    
    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkController,
        curve: Curves.easeInOut,
      ),
    );
    
    _fadeController.forward();
    _startCheckingVerification();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _checkTimer?.cancel();
    _pulseController.dispose();
    _fadeController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  void _startCheckingVerification() {
    _checkTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      setState(() => _lastChecked = DateTime.now());
      await _checkEmailVerified();
    });
  }

  Future<void> _checkEmailVerified() async {
    try {
      await _authService.reloadUser();
      
      if (_authService.isEmailVerified && mounted) {
        _checkTimer?.cancel();
        _pulseController.stop();
        
        HapticFeedback.heavyImpact();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Email verified successfully!'),
              ],
            ),
            backgroundColor: Colors.green[500],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        
        await Future.delayed(const Duration(milliseconds: 800));
        
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const MainNavigation(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) debugPrint('Error checking verification: $e');
    }
  }

  Future<void> _manualCheckVerification() async {
    HapticFeedback.mediumImpact();
    setState(() => _isChecking = true);

    try {
      await _authService.reloadUser();
      
      if (_authService.isEmailVerified) {
        if (mounted) {
          _checkTimer?.cancel();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Email verified successfully!'),
                ],
              ),
              backgroundColor: Colors.green[500],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
          
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainNavigation()),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Not verified yet. Please check your inbox and click the link.'),
                  ),
                ],
              ),
              backgroundColor: Colors.orange[500],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_isResending) return;
    
    HapticFeedback.mediumImpact();

    setState(() => _isResending = true);

    try {
      await _authService.sendEmailVerification();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('Sent to ${widget.email}')),
              ],
            ),
            backgroundColor: Colors.green[500],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );

        setState(() => _resendCountdown = 60);
        
        _resendTimer?.cancel();
        _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              if (_resendCountdown > 0) {
                _resendCountdown--;
              } else {
                _isResending = false;
                timer.cancel();
              }
            });
          } else {
            timer.cancel();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isResending = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Widget _buildStaggeredChild(Widget child, int index, {double delay = 0}) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        final intervalStart = ((index * 0.1) + delay).clamp(0.0, 0.7);
        final intervalEnd = (intervalStart + 0.25).clamp(0.0, 1.0);
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _fadeController,
            curve: Interval(intervalStart, intervalEnd, curve: Curves.easeOutCubic),
          ),
        );
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 20),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.black87, size: 20),
          ),
          onPressed: () async {
            await _authService.signOut();
            if (mounted) Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isTablet ? 60 : 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Email Icon with pulse
                _buildStaggeredChild(
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulsing ring
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: isTablet ? 160 : 140,
                              height: isTablet ? 160 : 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.2),
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Main container
                      Container(
                        width: isTablet ? 140 : 120,
                        height: isTablet ? 140 : 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary.withOpacity(0.15),
                              AppColors.primary.withOpacity(0.05),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                              spreadRadius: -5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.mark_email_unread_outlined,
                          size: isTablet ? 60 : 50,
                          color: AppColors.primary,
                        ),
                      ),
                      // Notification dot
                      Positioned(
                        top: isTablet ? 30 : 25,
                        right: isTablet ? 30 : 25,
                        child: AnimatedBuilder(
                          animation: _checkAnimation,
                          builder: (context, child) {
                            return Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.red[400],
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red[400]!.withOpacity(0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  0,
                ),

                SizedBox(height: isTablet ? 48 : 40),

                // Title
                _buildStaggeredChild(
                  const Text(
                    'Check your inbox',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E),
                      letterSpacing: -0.5,
                    ),
                  ),
                  1,
                ),

                const SizedBox(height: 12),

                // Description
                _buildStaggeredChild(
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: isTablet ? 17 : 15,
                        color: const Color(0xFF6B7280),
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(text: 'We sent a verification link to\n'),
                        TextSpan(
                          text: widget.email,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            fontSize: isTablet ? 17 : 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  2,
                ),

                const SizedBox(height: 32),

                // Instructions Card with glassmorphism
                _buildStaggeredChild(
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue[50]!,
                          Colors.blue[25]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.blue[100]!.withOpacity(0.5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue[100]!.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'What to do next',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.blue[900],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildStep('1', 'Open your email app or website'),
                        const SizedBox(height: 12),
                        _buildStep('2', 'Find the email from Paddlme'),
                        const SizedBox(height: 12),
                        _buildStep('3', 'Click the "Verify Email" button'),
                        const SizedBox(height: 12),
                        _buildStep('4', 'Return here - we\'ll auto-detect it'),
                      ],
                    ),
                  ),
                  3,
                ),

                const SizedBox(height: 32),

                // Auto-check indicator
                _buildStaggeredChild(
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 8,
                        height: 8,
                        child: AnimatedBuilder(
                          animation: _checkAnimation,
                          builder: (context, child) {
                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(
                                  0.5 + (_checkAnimation.value * 0.5),
                                ),
                                shape: BoxShape.circle,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Auto-checking every 3 seconds',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_lastChecked != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• ${_lastChecked!.minute.toString().padLeft(2, '0')}:${_lastChecked!.second.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ],
                  ),
                  3,
                  delay: 0.2,
                ),

                const SizedBox(height: 24),

                // Verified Button
                _buildStaggeredChild(
                  SizedBox(
                    width: isTablet ? 400 : double.infinity,
                    height: 56,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _isChecking
                              ? [
                                  AppColors.primary.withOpacity(0.7),
                                  AppColors.primary.withOpacity(0.5),
                                ]
                              : [
                                  AppColors.primary,
                                  AppColors.primary.withBlue(200),
                                ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(_isChecking ? 0.2 : 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                            spreadRadius: -4,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isChecking ? null : _manualCheckVerification,
                          borderRadius: BorderRadius.circular(16),
                          splashColor: Colors.white.withOpacity(0.1),
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _isChecking
                                  ? const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Checking...',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "I've Verified My Email",
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(
                                          Icons.check_circle_outline,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  4,
                ),

                const SizedBox(height: 16),

                // Resend Email
                _buildStaggeredChild(
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: TextButton(
                      onPressed: (_isResending || _resendCountdown > 0) 
                          ? null 
                          : _resendVerificationEmail,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_resendCountdown > 0)
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: _resendCountdown / 60,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                              ),
                            )
                          else
                            Icon(
                              Icons.refresh_rounded,
                              size: 18,
                              color: (_isResending || _resendCountdown > 0) 
                                  ? Colors.grey 
                                  : AppColors.primary,
                            ),
                          const SizedBox(width: 8),
                          Text(
                            _resendCountdown > 0
                                ? 'Resend in ${_resendCountdown}s'
                                : 'Resend email',
                            style: TextStyle(
                              color: (_isResending || _resendCountdown > 0) 
                                  ? Colors.grey 
                                  : AppColors.primary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  5,
                ),

                const SizedBox(height: 16),

                // Wrong Email
                _buildStaggeredChild(
                  TextButton(
                    onPressed: () async {
                      await _authService.signOut();
                      if (mounted) Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[500],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_rounded, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 6),
                        const Text(
                          'Wrong email? Go back',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  6,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}