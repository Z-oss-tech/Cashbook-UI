// ignore_for_file: unused_element
import 'package:cashbook/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../people/people_list_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/help_support_screen.dart';
import '../settings/backup_restore_screen.dart';
import '../auth/login_screen.dart';
import '../../core/widgets/theme_background_wrapper.dart';
import '../../core/theme/premium_themes.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final premiumTheme = PremiumThemes.getTheme(settings.appTheme);
    final isDefault = settings.appTheme == 'Default';
    final isDark = isDefault
        ? Theme.of(context).brightness == Brightness.dark
        : premiumTheme.themeData.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        child: Stack(
          children: [
            if (isDefault) ...[
              // Original Drawer Background
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.black.withValues(alpha: 0.98)
                        : Colors.white.withValues(alpha: 0.98),
                  ),
                ),
              ),

              // Theme gradient glow
              Positioned(
                bottom: 0,
                right: 0,
                left: 0,
                height: MediaQuery.of(context).size.height * 0.5,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.bottomRight,
                      radius: 1.5,
                      colors: [
                        AppColors.primary.withValues(
                          alpha: isDark ? 0.15 : 0.05,
                        ),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.7],
                    ),
                  ),
                ),
              ),

              // Watermark background illustration
              Positioned(
                bottom: MediaQuery.of(context).size.height * 0.1,
                right: -20,
                width: MediaQuery.of(context).size.width * 0.6,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Opacity(
                  opacity: isDark ? 0.1 : 0.15,
                  child: ShaderMask(
                    shaderCallback: (rect) {
                      return const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.transparent, Colors.black],
                        stops: [0.0, 0.5],
                      ).createShader(rect);
                    },
                    blendMode: BlendMode.dstIn,
                    child: Image.network(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuCvPkNvoPKKWqX9DSQ428WeUX6ccQsgQFec3XjfbB0ChmQOvzYrPSv-1f4SYkxNH1jghXV8jv6o59zh9-q5pefn556N3pBk_IZosbFEhFsiiTtZVYOsJiXgZ6NgSRS959l1k-MoaCrn_R7Vx6ydTNEdvYfv8LNkveGYeSr_WLSFbSTTewwG15s3PexmThf5hoHTXwBYteROsm0I4wTziXD1aN1qlUmmYLZ2tXyyA5sxztKnBrxruISIabn9on8DUAFCifm4NvfVZT5f',
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ],

            if (!isDefault)
              Positioned.fill(
                child: ThemeBackgroundWrapper(child: const SizedBox.shrink()),
              ),

            SafeArea(
              child: Column(
                children: [
                  // Top Section: Profile Card
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Theme.of(context).cardColor.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.white.withValues(alpha: 0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            blurRadius: 40,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(
                                    0xFF8B5CF6,
                                  ), // Tailwind violet-500
                                ),
                                child: Center(
                                  child: Consumer<SettingsProvider>(
                                    builder: (context, settings, child) {
                                      return Text(
                                        settings.userAvatar,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Consumer<SettingsProvider>(
                            builder: (context, settings, child) {
                              return Text(
                                settings.userName,
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Middle Section: Navigation List
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        // Cashbooks
                        _buildDrawerItem(
                          context,
                          icon: Icons.account_balance_wallet_rounded,
                          title: "Cashbooks",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PeopleListScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        // Backup & Restore
                        _buildDrawerItem(
                          context,
                          icon: Icons.cloud_sync_rounded,
                          title: "Backup & Restore",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BackupRestoreScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        // Settings
                        _buildDrawerItem(
                          context,
                          icon: Icons.settings_rounded,
                          title:
                              AppLocalizations.of(context)?.settings ??
                              "Settings",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        // Help & Support
                        _buildDrawerItem(
                          context,
                          icon: Icons.contact_support_rounded,
                          title:
                              AppLocalizations.of(context)?.helpSupport ??
                              "Help & Support",
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                final isDialogDark =
                                    Theme.of(context).brightness ==
                                    Brightness.dark;
                                return AlertDialog(
                                  backgroundColor: isDialogDark
                                      ? const Color(0xFF2D2D35)
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  title: Row(
                                    children: [
                                      Icon(
                                        Icons.school_rounded,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        "Quick Tutorial",
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildTutorialStep(
                                          context: context,
                                          icon: Icons.menu_book_rounded,
                                          title: "1. Create Cashbooks",
                                          description:
                                              "Use the Home screen to create dedicated ledgers for your personal or business needs.",
                                          isDark: isDialogDark,
                                        ),
                                        _buildTutorialStep(
                                          context: context,
                                          icon:
                                              Icons.add_circle_outline_rounded,
                                          title: "2. Add Records",
                                          description:
                                              "Tap the + button inside any cashbook to log Income or Expenses with custom notes.",
                                          isDark: isDialogDark,
                                        ),
                                        _buildTutorialStep(
                                          context: context,
                                          icon: Icons.cloud_sync_rounded,
                                          title: "3. Auto-Sync",
                                          description:
                                              "Your data is automatically synced to the cloud whenever you have internet access.",
                                          isDark: isDialogDark,
                                        ),
                                        _buildTutorialStep(
                                          context: context,
                                          icon: Icons.bar_chart_rounded,
                                          title: "4. View Reports",
                                          description:
                                              "Access detailed PDF and graphical reports from the Dashboard.",
                                          isDark: isDialogDark,
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        "Dismiss",
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context); // Close dialog
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const HelpSupportScreen(),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        "View More",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Bottom Section: Actions & Settings
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Dark Mode Toggle
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Consumer<SettingsProvider>(
                            builder: (context, settings, _) {
                              return Row(
                                children: [
                                  Icon(
                                    Icons.dark_mode_outlined,
                                    size: 20,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Dark Mode",
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.grey.shade800,
                                    ),
                                  ),
                                  const Spacer(),
                                  Switch(
                                    value: settings.darkMode,
                                    onChanged: (val) {
                                      settings.setDarkMode(val);
                                    },
                                    activeThumbColor: AppColors.primary,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Logout Button
                        GestureDetector(
                          onTap: () async {
                            final authProvider = Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            );
                            await authProvider.logout();
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                                (route) => false,
                              );
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.exit_to_app_rounded,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Logout",
                                  style: GoogleFonts.inter(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.12),
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white70,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final settings = Provider.of<SettingsProvider>(context);
    final premiumTheme = PremiumThemes.getTheme(settings.appTheme);
    final isDefault = settings.appTheme == 'Default';
    final isDark = isDefault
        ? Theme.of(context).brightness == Brightness.dark
        : premiumTheme.themeData.brightness == Brightness.dark;

    final textColor = isDark ? Colors.white70 : Colors.grey.shade800;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: AppColors.primary.withValues(alpha: 0.1),
        highlightColor: AppColors.primary.withValues(alpha: 0.1),
        splashColor: AppColors.primary.withValues(alpha: 0.2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: textColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: textColor.withValues(alpha: 0.2),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTutorialStep({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
    required BuildContext context,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
