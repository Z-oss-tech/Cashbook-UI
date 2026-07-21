import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../theme/premium_themes.dart';

class ThemeBackgroundWrapper extends StatelessWidget {
  final Widget child;

  const ThemeBackgroundWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final themeName = settings.appTheme;
        final premiumTheme = PremiumThemes.getTheme(themeName);

        return Stack(
          children: [
            // Base background
            Container(color: Theme.of(context).scaffoldBackgroundColor),

            // Custom Theme Background Accents
            if (themeName == 'Cherry Blossom') ...[
              Positioned.fill(
                child: Opacity(
                  opacity: 0.2,
                  child: Image.network(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuCdfXLR2tCS9YpT8JQ0AdQEbU1Mis3pObtMYAs_qHXplGsSUIkBTeR7cA0zHiH8ICt3Qb00582xEbg1-FSc41m3B9XGiy85RUCzDEwvBWcoKvd2t45EvEFJOMOtxm_Kn-REdNzTwNjXsIdlHGCvAs4s4Cpfn9jk7UaVhpOxlagV4ynoVX1pv5dnElZfMwJh2HygLQF_vVWO63WJ6HA-3Me5iJWj9HAsRVGRaKepMZli11DXXjzIBJ5t',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: -50,
                right: -50,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF43F5E).withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                left: -50,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFB2B9).withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ),
            ] else if (themeName == 'Forest Emerald') ...[
              Positioned.fill(
                child: Image.asset(
                  'assets/images/forest_emerald_bg.png',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: -100,
                right: -50,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: premiumTheme.primaryColor.withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ),
            ] else if (themeName == 'Midnight Ocean') ...[
              Positioned.fill(
                child: Image.asset(
                  'assets/images/midnight_ocean_bg.png',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: -100,
                right: -50,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: premiumTheme.primaryColor.withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ),
            ] else if (themeName == 'Sunset Glow') ...[
              Positioned.fill(
                child: Image.asset(
                  'assets/images/sunset_glow_bg.png',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: -100,
                right: -50,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: premiumTheme.primaryColor.withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ),
            ] else if (themeName != 'Default') ...[
              // Generic glowing orbs based on primary color
              Positioned(
                top: -100,
                right: -50,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: premiumTheme.primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ),
            ],

            // The actual content
            child,
          ],
        );
      },
    );
  }
}
