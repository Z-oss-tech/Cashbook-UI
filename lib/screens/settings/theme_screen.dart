import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';

class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : const Color(0xFF0B1C30));

    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopAppBar(context, textColor),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                children: [
                  Text(
                    "Choose Your Vibe",
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Select a theme to instantly change the entire look of your app.",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color:
                          Theme.of(context).textTheme.bodyMedium?.color ??
                          (isDark ? Colors.white70 : const Color(0xFF767586)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildThemeCard(
                    context: context,
                    title: "Default Mode",
                    description:
                        "Follows your system Dark/Light mode preference.",
                    themeName: "Default",
                    isSelected: settings.appTheme == "Default",
                    primaryColor: const Color(0xFF5B67F1),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5B67F1), Color(0xFF8B5CF6)],
                    ),
                    settings: settings,
                  ),
                  const SizedBox(height: 16),

                  _buildThemeCard(
                    context: context,
                    title: "Midnight Ocean",
                    description:
                        "Deep oceanic blues with vibrant cyan accents.",
                    themeName: "Midnight Ocean",
                    isSelected: settings.appTheme == "Midnight Ocean",
                    primaryColor: const Color(0xFF00D2FF),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0A192F), Color(0xFF112240)],
                    ),
                    settings: settings,
                  ),
                  const SizedBox(height: 16),

                  _buildThemeCard(
                    context: context,
                    title: "Sunset Glow",
                    description:
                        "Dark purples mixed with vibrant orange sunsets.",
                    themeName: "Sunset Glow",
                    isSelected: settings.appTheme == "Sunset Glow",
                    primaryColor: const Color(0xFFFF512F),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1F0D24), Color(0xFF321538)],
                    ),
                    settings: settings,
                  ),
                  const SizedBox(height: 16),

                  _buildThemeCard(
                    context: context,
                    title: "Forest Emerald",
                    description: "Lush deep greens with soft mint highlights.",
                    themeName: "Forest Emerald",
                    isSelected: settings.appTheme == "Forest Emerald",
                    primaryColor: const Color(0xFF10B981),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF064E3B), Color(0xFF065F46)],
                    ),
                    settings: settings,
                  ),
                  const SizedBox(height: 16),

                  _buildThemeCard(
                    context: context,
                    title: "Cherry Blossom",
                    description: "A gorgeous light theme with soft pinks.",
                    themeName: "Cherry Blossom",
                    isSelected: settings.appTheme == "Cherry Blossom",
                    primaryColor: const Color(0xFFF43F5E),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF0F3), Colors.white],
                    ),
                    settings: settings,
                    isLightText: false,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context, Color textColor) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: textColor,
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            "Themes",
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(width: 48), // Balance for centering
        ],
      ),
    );
  }

  Widget _buildThemeCard({
    required BuildContext context,
    required String title,
    required String description,
    required String themeName,
    required bool isSelected,
    required Color primaryColor,
    required Gradient gradient,
    required SettingsProvider settings,
    bool isLightText = true,
  }) {
    return GestureDetector(
      onTap: () {
        settings.setAppTheme(themeName);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.transparent,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isLightText
                          ? Colors.white
                          : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isLightText
                          ? Colors.white70
                          : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? primaryColor : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? primaryColor
                      : (isLightText ? Colors.white54 : Colors.black26),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
