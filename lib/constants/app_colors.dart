import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 색상 상수
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF0000BB);
  static const Color primaryLight = Color(0xFF00D0FF);
  
  // Background Colors
  static const Color background = Color(0xFFF5F5F7);
  static const Color surface = Colors.white;
  static const Color surfaceLight = Color(0xFFF1F1F1);
  
  // Text Colors
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Colors.grey;
  static const Color textOnPrimary = Colors.white;
  
  // Accent Colors
  static const Color accent = Colors.black;
  static const Color error = Colors.red;
  static const Color delete = Colors.redAccent;
  static const Color info = Colors.blue;
}
