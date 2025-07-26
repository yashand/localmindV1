import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PalantirTheme {
  // Color Definitions
  static const Color backgroundDeep = Color(0xFF0A0A0B);
  static const Color backgroundCard = Color(0xFF1A1A1C);
  static const Color backgroundSurface = Color(0xFF2A2A2D);
  static const Color borderColor = Color(0xFF3A3A3F);
  
  static const Color accentTeal = Color(0xFF00D4AA);
  static const Color accentBlue = Color(0xFF4A9EFF);
  static const Color accentOrange = Color(0xFFFF6B35);
  static const Color successGreen = Color(0xFF32D74B);
  
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0A8);
  static const Color textMuted = Color(0xFF6A6A6F);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: _createMaterialColor(accentTeal),
      scaffoldBackgroundColor: backgroundDeep,
      
      // Card Theme
      cardTheme: CardTheme(
        color: backgroundCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundDeep,
        foregroundColor: textPrimary,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
      
      // Text Theme
      textTheme: TextTheme(
        displayLarge: TextStyle(color: textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w300),
        displayMedium: TextStyle(color: textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w300),
        displaySmall: TextStyle(color: textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w400),
        headlineLarge: TextStyle(color: textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w500),
        titleMedium: TextStyle(color: textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: textSecondary, fontFamily: 'Inter', fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(color: textSecondary, fontFamily: 'Inter', fontWeight: FontWeight.w400),
        bodySmall: TextStyle(color: textMuted, fontFamily: 'Inter', fontWeight: FontWeight.w400),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accentTeal, width: 2),
        ),
        hintStyle: TextStyle(color: textMuted),
      ),
      
      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentTeal,
          foregroundColor: backgroundDeep,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Inter'),
        ),
      ),
    );
  }

  static MaterialColor _createMaterialColor(Color color) {
    List strengths = [.05];
    Map swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch as Map<int, Color>);
  }
}