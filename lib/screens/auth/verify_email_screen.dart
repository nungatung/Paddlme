import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../main_navigation.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  final String name;

  const VerifyEmailScreen({
    super.key,
    required this. email,
    required this.name,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _authService = AuthService();
  bool _isResending = false;
  bool _isChecking = false;
  int _resendCountdown = 0;
  Timer? _resendTimer;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    // Email verification was already sent during signup
    // Start checking for verification every 3 seconds
    _startCheckingVerification();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _checkTimer?.cancel();
    super.dispose();
  }

  // ✅ Automatically check if email is verified
  void _startCheckingVerification() {
    _checkTimer = Timer. periodic(const Duration(seconds: 3), (_) async {
      await _checkEmailVerified();
    });
  }

  // ✅ Check if email is verified
  Future<void> _checkEmailVerified() async {
    try {
      await _authService.reloadUser();
      
      if (_authService.isEmailVerified && mounted) {
        _checkTimer?.cancel();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully!  🎉'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Navigate to main app
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
          (route) => false,
        );
      }
    } catch (e) {
      // Silently fail - user might not be logged in anymore
      if (mounted) {
        debugPrint('Error checking verification: $e');
      }
    }
  }

  // ✅ Manual check when user clicks "I've Verified"
  Future<void> _manualCheckVerification() async {
    setState(() => _isChecking = true);

    try {
      await _authService.reloadUser();
      
      if (_authService.isEmailVerified) {
        if (mounted) {
          _checkTimer?.cancel();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified successfully! 🎉'),
              backgroundColor: Colors.green,
            ),
          );
          
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainNavigation()),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email not verified yet. Please check your inbox and click the link. '),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:  Text('Error:  $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  // ✅ Resend verification email
  Future<void> _resendVerificationEmail() async {
    if (_isResending) return;

    setState(() => _isResending = true);

    try {
      await _authService.sendEmailVerification();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:  Text('Verification email sent to ${widget.email}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Start 60 second countdown
        setState(() => _resendCountdown = 60);
        
        _resendTimer?. cancel();
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
            backgroundColor: Colors. red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon:  const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () async {
            // Sign out when going back
            await _authService.signOut();
            if (mounted) {
              Navigator. pop(context);
            }
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
                // Email Icon
                Container(
                  width: isTablet ? 140 : 120,
                  height: isTablet ? 140 : 120,
                  decoration: BoxDecoration(
                    color: AppColors.primary. withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mark_email_unread_outlined,
                    size: isTablet ? 70 : 60,
                    color: AppColors.primary,
                  ),
                ),

                SizedBox(height: isTablet ? 48 : 32),

                // Title
                Text(
                  'Verify Your Email',
                  style: TextStyle(
                    fontSize: isTablet ? 32 : 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Description
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'We sent a verification link to\n'),
                      TextSpan(
                        text: widget.email,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height:  32),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Next Steps: ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildStep('1', 'Check your inbox for the verification email'),
                      const SizedBox(height: 8),
                      _buildStep('2', 'Click the verification link in the email'),
                      const SizedBox(height: 8),
                      _buildStep('3', 'Return here - we\'ll auto-detect verification'),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Verified Button
                SizedBox(
                  width: isTablet ? 400 : double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isChecking ? null : _manualCheckVerification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isChecking
                        ? const SizedBox(
                            height:  24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            "I've Verified My Email",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Resend Email
                TextButton(
                  onPressed: (_isResending || _resendCountdown > 0) 
                      ? null 
                      : _resendVerificationEmail,
                  child: Text(
                    _resendCountdown > 0
                        ? 'Resend email in ${_resendCountdown}s'
                        : 'Resend verification email',
                    style: TextStyle(
                      color: (_isResending || _resendCountdown > 0) 
                          ? Colors.grey 
                          : AppColors. primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height:  24),

                // Wrong Email? 
                TextButton(
                  onPressed: () async {
                    await _authService.signOut();
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    'Wrong email?  Go back',
                    style:  TextStyle(
                      color:  Colors.grey,
                      fontSize: 14,
                    ),
                  ),
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
          width: 20,
          height:  20,
          decoration: const BoxDecoration(
            color:  AppColors.primary,
            shape: BoxShape. circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize:  14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}