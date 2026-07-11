import 'package:flutter/material.dart';

class ThemeInfo {
  final ThemeData themeData;
  final Color primaryColor;
  final LinearGradient gradient;

  ThemeInfo({
    required this.themeData,
    required this.primaryColor,
    required this.gradient,
  });
}

class PremiumThemes {
  static ThemeInfo getTheme(String themeName) {
    switch (themeName) {
      case 'Midnight Ocean':
        return ThemeInfo(
          themeData: midnightOcean,
          primaryColor: const Color(0xFF00D2FF),
          gradient: const LinearGradient(colors: [Color(0xFF0A192F), Color(0xFF112240)]),
        );
      case 'Sunset Glow':
        return ThemeInfo(
          themeData: sunsetGlow,
          primaryColor: const Color(0xFFFF512F),
          gradient: const LinearGradient(colors: [Color(0xFF1F0D24), Color(0xFF321538)]),
        );
      case 'Forest Emerald':
        return ThemeInfo(
          themeData: forestEmerald,
          primaryColor: const Color(0xFF10B981),
          gradient: const LinearGradient(colors: [Color(0xFF064E3B), Color(0xFF065F46)]),
        );
      case 'Cherry Blossom':
        return ThemeInfo(
          themeData: cherryBlossom,
          primaryColor: const Color(0xFFF43F5E),
          gradient: const LinearGradient(colors: [Color(0xFFFFF0F3), Colors.white]),
        );
      default:
        // Default theme info
        return ThemeInfo(
          themeData: ThemeData.light(), // Fallback
          primaryColor: const Color(0xFF4143D5),
          gradient: const LinearGradient(colors: [Color(0xFF4143D5), Color(0xFF7459F7)]),
        );
    }
  }

  // 1. Midnight Ocean
  static ThemeData get midnightOcean {
    const primary = Color(0xFF00D2FF);
    const background = Color(0xFF0A192F);
    const card = Color(0xFF112240);
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      cardColor: card,
      canvasColor: card,
      dividerColor: const Color(0xFF233554),
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: Color(0xFF3A86FF),
        surface: card,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  // 2. Sunset Glow
  static ThemeData get sunsetGlow {
    const primary = Color(0xFFFF512F);
    const background = Color(0xFF1F0D24);
    const card = Color(0xFF321538);
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      cardColor: card,
      canvasColor: card,
      dividerColor: const Color(0xFF4A1F52),
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: Color(0xFFF09819),
        surface: card,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  // 3. Forest Emerald
  static ThemeData get forestEmerald {
    const primary = Color(0xFF10B981);
    const background = Color(0xFF064E3B);
    const card = Color(0xFF065F46);
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      cardColor: card,
      canvasColor: card,
      dividerColor: const Color(0xFF047857),
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: Color(0xFF34D399),
        surface: card,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  // 4. Cherry Blossom
  static ThemeData get cherryBlossom {
    const primary = Color(0xFFF43F5E);
    const background = Color(0xFFFFF0F3);
    const card = Colors.white;
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      cardColor: card,
      canvasColor: card,
      dividerColor: const Color(0xFFFFE4E6),
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: Color(0xFFFB7185),
        surface: card,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Color(0xFF881337), // Dark red for appbar text
      ),
    );
  }
}
