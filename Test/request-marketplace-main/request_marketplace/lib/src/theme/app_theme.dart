import 'package:flutter/material.dart';

class AppTheme {
  // Android 16 Material You colors - Dynamic Color Scheme
  static const Color primaryColor = Color(0xFF6750A4); // Material Purple
  static const Color primaryVariant = Color(0xFF4F378B);
  static const Color accentColor = Color(0xFF7D5260); // Tertiary accent
  
  // Background Colors - Android 16 surface tones
  static const Color backgroundColor = Color(0xFFFFFBFE);
  static const Color backgroundPrimary = Color(0xFFFFFBFE); // Add this for our new screens
  static const Color surfaceColor = Color(0xFFFFFBFE);
  static const Color cardColor = Color(0xFFFFFBFE);
  
  // Text Colors - Android 16 on-surface tones
  static const Color textPrimary = Color(0xFF1C1B1F);
  static const Color textSecondary = Color(0xFF49454F);
  static const Color textTertiary = Color(0xFF79747E);
  
  // Border Colors - Android 16 outline
  static const Color borderColor = Color(0xFF79747E);
  static const Color borderLight = Color(0xFFE7E0EC);
  
  // Status Colors - Android 16 semantic colors
  static const Color successColor = Color(0xFF146C2E);
  static const Color errorColor = Color(0xFFBA1A1A);
  static const Color warningColor = Color(0xFF6F5B40);
  static const Color infoColor = Color(0xFF1D192B);
  
  // Border Radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  
  // Spacing
  static const double spacingXSmall = 8.0;
  static const double spacingSmall = 12.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  
  // Typography
  static const TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.2,
  );
  
  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );
  
  static const TextStyle headingSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    height: 1.4,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.4,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textTertiary,
    height: 1.4,
  );
  
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  
  // Input Decoration
  static InputDecoration inputDecoration({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: textTertiary),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
  
  // Container Decoration
  static BoxDecoration containerDecoration({
    Color? color,
    bool hasBorder = false,
    double borderRadius = borderRadiusMedium,
  }) {
    return BoxDecoration(
      color: color ?? surfaceColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: hasBorder ? Border.all(color: borderColor, width: 1) : null,
    );
  }
  
  // Card Decoration (Flat)
  static BoxDecoration cardDecoration({
    Color? color,
    double borderRadius = borderRadiusLarge,
  }) {
    return BoxDecoration(
      color: color ?? surfaceColor,
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }
  
  // Button Styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: backgroundColor, // White text for purple background
    elevation: 0,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadiusMedium),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    textStyle: buttonText,
  );
  
  static ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(
    backgroundColor: Colors.transparent,
    foregroundColor: primaryColor,
    elevation: 0,
    shadowColor: Colors.transparent,
    side: const BorderSide(color: primaryColor, width: 1),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadiusMedium),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    textStyle: buttonText,
  );
  
  static ButtonStyle textButtonStyle = TextButton.styleFrom(
    backgroundColor: Colors.transparent,
    foregroundColor: primaryColor,
    elevation: 0,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadiusSmall),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    textStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  );
  
  // AppBar Theme
  static AppBarTheme get appBarTheme => const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: textPrimary,
    elevation: 0,
    shadowColor: Colors.transparent,
    centerTitle: false,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: textPrimary,
    ),
  );
  
  // SnackBar Styles
  static SnackBar successSnackBar(String message) {
    return SnackBar(
      content: Text(message),
      backgroundColor: successColor,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadiusSmall)),
      elevation: 0,
    );
  }
  
  static SnackBar errorSnackBar(String message) {
    return SnackBar(
      content: Text(message),
      backgroundColor: errorColor,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadiusSmall)),
      elevation: 0,
    );
  }
  
  // Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primarySwatch: Colors.indigo,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: appBarTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: secondaryButtonStyle),
      textButtonTheme: TextButtonThemeData(style: textButtonStyle),
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: primaryVariant,
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onBackground: textPrimary,
        onError: Colors.white,
      ),
      textTheme: const TextTheme(
        headlineLarge: headingLarge,
        headlineMedium: headingMedium,
        headlineSmall: headingSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
      ),
    );
  }
}
