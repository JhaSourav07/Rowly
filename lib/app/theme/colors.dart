import 'package:flutter/material.dart';

class AppColors {
  static bool isDark = true;

  static Color get background => isDark ? const Color(0xFF0F1115) : const Color(0xFFF5F6F8);
  static Color get surface => isDark ? const Color(0xFF161920) : const Color(0xFFFFFFFF);
  static Color get surfaceElevated => isDark ? const Color(0xFF1F232D) : const Color(0xFFEAECEF);
  
  static Color get borderSubtle => isDark ? const Color(0xFF2E3440) : const Color(0xFFDCDFE4);
  static Color get borderMuted => isDark ? const Color(0xFF242933) : const Color(0xFFE6E8EC);
  
  static Color get accent => const Color(0xFF5E81AC);
  static Color get successGreen => const Color(0xFF31B057);
  
  static Color get textPrimary => isDark ? const Color(0xFFECEFF4) : const Color(0xFF2E3440);
  static Color get textSecondary => isDark ? const Color(0xFFD8DEE9) : const Color(0xFF4C566A);
  static Color get textMuted => isDark ? const Color(0xFF4C566A) : const Color(0xFF9CA3AF);
  
  static Color get error => const Color(0xFFBF616A);
}
