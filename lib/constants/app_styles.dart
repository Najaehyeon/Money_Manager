import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 앱 전체에서 사용하는 스타일 상수
class AppStyles {
  AppStyles._();

  // Border Radius
  static const double borderRadiusSmall = 12.0;
  static const double borderRadiusMedium = 16.0;
  static const double borderRadiusLarge = 20.0;
  static const double borderRadiusXLarge = 24.0;
  static const double borderRadiusCircular = 50.0;
  static const double borderRadiusCylinder = 100.0;

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXL = 24.0;
  static const double spacingXXL = 36.0;

  // Button Heights
  static const double buttonHeight = 48.0;

  // Input Field Styles
  static InputDecoration inputDecoration({
    String? hintText,
    Color? fillColor,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: fillColor ?? AppColors.surfaceLight,
      hintText: hintText,
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(borderRadiusMedium),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingL,
        vertical: 14,
      ),
    );
  }

  static InputDecoration whiteInputDecoration({String? hintText}) {
    return InputDecoration(
      contentPadding: const EdgeInsets.all(10),
      filled: true,
      fillColor: AppColors.surface,
      border: InputBorder.none,
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.surface),
        borderRadius: BorderRadius.circular(borderRadiusMedium),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.surface),
        borderRadius: BorderRadius.circular(borderRadiusMedium),
      ),
    );
  }

  // Button Styles
  static ButtonStyle primaryButtonStyle({
    double? height,
    Color? backgroundColor,
  }) {
    return ElevatedButton.styleFrom(
      elevation: 0,
      shadowColor: Colors.transparent,
      backgroundColor: backgroundColor ?? AppColors.accent,
      foregroundColor: AppColors.textOnPrimary,
      minimumSize: Size.fromHeight(height ?? buttonHeight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusMedium),
      ),
      overlayColor: Colors.white12,
    );
  }

  static ButtonStyle secondaryButtonStyle({double? height}) {
    return ElevatedButton.styleFrom(
      elevation: 0,
      shadowColor: Colors.transparent,
      backgroundColor: AppColors.surfaceLight,
      foregroundColor: AppColors.textPrimary,
      minimumSize: Size.fromHeight(height ?? buttonHeight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusSmall),
      ),
      overlayColor: Colors.black12,
    );
  }

  static ButtonStyle whiteButtonStyle({double? width}) {
    return ElevatedButton.styleFrom(
      elevation: 0,
      alignment: Alignment.centerLeft,
      backgroundColor: AppColors.surface,
      overlayColor: Colors.black12,
      shadowColor: Colors.transparent,
      fixedSize: width != null ? Size(width, buttonHeight) : null,
      padding: const EdgeInsets.symmetric(horizontal: spacingM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusMedium),
      ),
    );
  }

  // Dialog Styles
  static BoxDecoration dialogDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(borderRadiusXLarge),
    );
  }

  static ShapeBorder dialogShape() {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadiusXLarge),
    );
  }
}
