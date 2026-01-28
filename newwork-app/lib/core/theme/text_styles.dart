import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Display Styles
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
  );
  static const TextStyle displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle displaySmall = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w400,
  );

  // Headline Styles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  // Title Styles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  // Body Styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  // Label Styles
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );

  // Code Styles
  static const TextStyle code = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle codeBold = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  // Custom Styles
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
  );

  // Light Theme Text Styles
  static TextTheme get lightTextTheme {
    return TextTheme(
      displayLarge: displayLarge.copyWith(color: AppColors.textLight),
      displayMedium: displayMedium.copyWith(color: AppColors.textLight),
      displaySmall: displaySmall.copyWith(color: AppColors.textLight),
      headlineLarge: headlineLarge.copyWith(color: AppColors.textLight),
      headlineMedium: headlineMedium.copyWith(color: AppColors.textLight),
      headlineSmall: headlineSmall.copyWith(color: AppColors.textLight),
      titleLarge: titleLarge.copyWith(color: AppColors.textLight),
      titleMedium: titleMedium.copyWith(color: AppColors.textLight),
      titleSmall: titleSmall.copyWith(color: AppColors.textLight),
      bodyLarge: bodyLarge.copyWith(color: AppColors.textLight),
      bodyMedium: bodyMedium.copyWith(color: AppColors.textLight),
      bodySmall: bodySmall.copyWith(color: AppColors.textLight),
      labelLarge: labelLarge.copyWith(color: AppColors.textLight),
      labelMedium: labelMedium.copyWith(color: AppColors.textLight),
      labelSmall: labelSmall.copyWith(color: AppColors.textLight),
    );
  }

  // Dark Theme Text Styles
  static TextTheme get darkTextTheme {
    return TextTheme(
      displayLarge: displayLarge.copyWith(color: AppColors.textDark),
      displayMedium: displayMedium.copyWith(color: AppColors.textDark),
      displaySmall: displaySmall.copyWith(color: AppColors.textDark),
      headlineLarge: headlineLarge.copyWith(color: AppColors.textDark),
      headlineMedium: headlineMedium.copyWith(color: AppColors.textDark),
      headlineSmall: headlineSmall.copyWith(color: AppColors.textDark),
      titleLarge: titleLarge.copyWith(color: AppColors.textDark),
      titleMedium: titleMedium.copyWith(color: AppColors.textDark),
      titleSmall: titleSmall.copyWith(color: AppColors.textDark),
      bodyLarge: bodyLarge.copyWith(color: AppColors.textDark),
      bodyMedium: bodyMedium.copyWith(color: AppColors.textDark),
      bodySmall: bodySmall.copyWith(color: AppColors.textDark),
      labelLarge: labelLarge.copyWith(color: AppColors.textDark),
      labelMedium: labelMedium.copyWith(color: AppColors.textDark),
      labelSmall: labelSmall.copyWith(color: AppColors.textDark),
    );
  }

  // Helper method to get text color based on brightness
  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.textDark
        : AppColors.textLight;
  }

  static Color getTextSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
  }
}
