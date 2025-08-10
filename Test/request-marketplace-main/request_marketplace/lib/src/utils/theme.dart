import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Modern blue color scheme matching the interface
  static final Color primaryColor = const Color(0xFF4A90E2); // Main blue color
  static final Color primaryDark = const Color(0xFF357ABD); // Darker blue for pressed states
  static final Color primaryLight = const Color(0xFF6BA3E8); // Lighter blue for highlights
  static final Color accentColor = const Color(0xFF5CA7F2); // Accent blue
  static final Color backgroundColor = const Color(0xFFF8F9FA); // Very light gray background
  static final Color cardColor = Colors.white;
  static final Color textColor = const Color(0xFF1C1E21); // Dark gray text
  static final Color secondaryTextColor = const Color(0xFF65676B); // Medium gray text
  static final Color dividerColor = const Color(0xFFE4E6EA); // Light gray divider
  static final Color successColor = const Color(0xFF28A745); // Green for success states
  static final Color warningColor = const Color(0xFFFFC107); // Yellow for warnings
  static final Color errorColor = const Color(0xFFDC3545); // Red for errors

  static ThemeData get theme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: cardColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textColor,
        error: errorColor,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColor),
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: TextStyle(color: secondaryTextColor),
        hintStyle: TextStyle(color: secondaryTextColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 50),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryLight.withOpacity(0.1),
        labelStyle: TextStyle(color: primaryColor),
        side: BorderSide(color: primaryLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.grey[400];
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryLight.withOpacity(0.5);
          }
          return Colors.grey[300];
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.grey[400];
        }),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: textColor),
        bodyMedium: TextStyle(color: textColor),
        bodySmall: TextStyle(color: secondaryTextColor),
      ),
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 0.5,
        space: 1,
      ),
    );
  }
}
