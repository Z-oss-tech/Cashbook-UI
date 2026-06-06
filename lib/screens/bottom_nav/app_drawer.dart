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

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: Colors.transparent, // To show backdrop filter
      elevation: 0,
      child: Stack(
        children: [
          // Drawer Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.black.withOpacity(0.98) : Colors.white.withOpacity(0.98),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
            ),
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
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.12),
                          blurRadius: 40,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [AppColors.primary, AppColors.secondary],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Center(
                                child: Consumer<SettingsProvider>(
                                  builder: (context, settings, child) {
                                    return Text(
                                      settings.userAvatar,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -4,
                              right: -4,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.black : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.3),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Consumer<SettingsProvider>(
                            builder: (context, settings, child) {
                              return Text(
                                settings.userName,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
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
                        title: AppLocalizations.of(context)?.settings ?? "Settings",
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
                        title: AppLocalizations.of(context)?.helpSupport ?? "Help & Support",
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: Row(
                                  children: [
                                    const Icon(Icons.school_rounded, color: AppColors.primary),
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
                                        icon: Icons.menu_book_rounded,
                                        title: "1. Create Cashbooks",
                                        description: "Use the Home screen to create dedicated ledgers for your personal or business needs.",
                                      ),
                                      _buildTutorialStep(
                                        icon: Icons.add_circle_outline_rounded,
                                        title: "2. Add Records",
                                        description: "Tap the + button inside any cashbook to log Income or Expenses with custom notes.",
                                      ),
                                      _buildTutorialStep(
                                        icon: Icons.cloud_sync_rounded,
                                        title: "3. Auto-Sync",
                                        description: "Your data is automatically synced to the cloud whenever you have internet access.",
                                      ),
                                      _buildTutorialStep(
                                        icon: Icons.bar_chart_rounded,
                                        title: "4. View Reports",
                                        description: "Access detailed PDF and graphical reports from the Dashboard.",
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text("Dismiss", style: GoogleFonts.poppins(color: Colors.grey)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context); // Close dialog
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const HelpSupportScreen(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: Text("View More", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Consumer<SettingsProvider>(
                          builder: (context, settings, _) {
                            return Row(
                              children: [
                                Icon(
                                  Icons.dark_mode_outlined,
                                  size: 20,
                                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Dark Mode",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                                  ),
                                ),
                                const Spacer(),
                                Switch(
                                  value: settings.darkMode,
                                  onChanged: (val) {
                                    settings.setDarkMode(val);
                                  },
                                  activeColor: AppColors.primary,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ],
                            );
                          }
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Logout Button
                      GestureDetector(
                        onTap: () async {
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          await authProvider.logout();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
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
                color: AppColors.primary.withOpacity(0.12),
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
              const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 20),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.grey.shade700;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: AppColors.primary.withOpacity(0.1),
        highlightColor: AppColors.primary.withOpacity(0.1),
        splashColor: AppColors.primary.withOpacity(0.2),
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
              Icon(Icons.chevron_right_rounded, color: textColor.withOpacity(0.2), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTutorialStep({required IconData icon, required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(description, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
