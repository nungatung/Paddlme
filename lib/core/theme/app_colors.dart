import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (Ocean & Sand theme from your kayak site)
  static const Color primary = Color(0xFF1E3A8A);        // Ocean blue
  static const Color primaryLight = Color(0xFF3B82F6);   // Ocean light
  static const Color accent = Color(0xFFF59E0B);         // Sand
  static const Color accentLight = Color(0xFFFBBF24);    // Sand light
  
  // Neutrals
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE5E7EB);
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  
  // Gradients
  static const LinearGradient oceanGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient sandGradient = LinearGradient(
    colors: [accent, accentLight],
    begin:  Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}