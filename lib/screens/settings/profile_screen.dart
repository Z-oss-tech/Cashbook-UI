import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/export_helper.dart';
import '../../providers/record_provider.dart';
import '../../core/utils/toast_helper.dart';
import '../../core/services/update_service.dart';
import '../../core/widgets/theme_background_wrapper.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/theme/premium_themes.dart';
import '../auth/login_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _initAppVersion();
  }

  Future<void> _initAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = packageInfo.version;
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final premiumTheme = PremiumThemes.getTheme(settings.appTheme);
    final isDefault = settings.appTheme == 'Default';
    final primaryColor = isDefault
        ? const Color(0xFF4143D5)
        : premiumTheme.primaryColor;
    final secondaryColor = isDefault
        ? const Color(0xFF7459F7)
        : premiumTheme.gradient.colors.last;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: ThemeBackgroundWrapper(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildTopAppBar(context, isDark),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Header Section
                      _buildProfileCard(
                        context,
                        settings,
                        primaryColor,
                        secondaryColor,
                        isDark,
                      ),
                      const SizedBox(height: 24),

                      // Appearance & Theme
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        borderRadius: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.palette_rounded,
                                  color: primaryColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Appearance",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "ACTIVE THEME",
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF5B4041),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildThemeSelector(
                              context,
                              settings,
                              primaryColor,
                              isDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // General Settings (Business, Security, Updates)
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        borderRadius: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  color: primaryColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "General",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildMenuTile(
                              context: context,
                              icon: Icons.business_center_rounded,
                              iconBgColor: primaryColor.withValues(alpha: 0.1),
                              iconColor: primaryColor,
                              title: "Business Profile",
                              subtitle: "Coming soon",
                              onTap: () {
                                ToastHelper.showToast(context, 'Business Profiles are coming in the next update!');
                              },
                              isDark: isDark,
                              showBorder: true,
                            ),
                            _buildMenuTile(
                              context: context,
                              icon: Icons.share_rounded,
                              iconBgColor: primaryColor.withValues(alpha: 0.1),
                              iconColor: primaryColor,
                              title: "Share Export",
                              subtitle: "Export & Share cashbooks",
                              onTap: () {
                                ExportHelper.showExportOptions(context);
                              },
                              isDark: isDark,
                              showBorder: true,
                            ),
                            _buildMenuTile(
                              context: context,
                              icon: Icons.lock_outline_rounded,
                              iconBgColor: Colors.red.withValues(alpha: 0.1),
                              iconColor: Colors.red,
                              title: "Change Password",
                              subtitle: "Update your login password",
                              onTap: () => _showChangePasswordDialog(context),
                              isDark: isDark,
                              showBorder: true,
                            ),
                            _buildMenuTile(
                              context: context,
                              icon: Icons.system_update_rounded,
                              iconBgColor: primaryColor.withValues(alpha: 0.1),
                              iconColor: primaryColor,
                              title: "Check for Updates",
                              subtitle: "Current version: $_appVersion",
                              onTap: () {
                                UpdateService.checkForUpdates(
                                  context,
                                  showUpToDate: true,
                                );
                              },
                              isDark: isDark,
                              showBorder: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Logout Section
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        borderRadius: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.exit_to_app_rounded,
                                  color: Colors.red,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Session",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildLogoutButton(context, settings, primaryColor),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),
                      _buildFooter(isDark),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context, bool isDark) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : const Color(0xFF0F0069),
            ),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
          Text(
            "Profile",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F0069),
            ),
          ),
          const SizedBox(width: 48), // Balance for centering
        ],
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    SettingsProvider settings,
    Color primaryColor,
    Color secondaryColor,
    bool isDark,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(32),
      borderRadius: 32,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Opacity(
              opacity: 0.1,
              child: Icon(Icons.forest_rounded, size: 120, color: primaryColor),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 128,
                    height: 128,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [primaryColor, secondaryColor],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: isDark ? const Color(0xFF191C1E) : Colors.white,
                      ),
                      child: Center(
                        child: Text(
                          settings.userAvatar,
                          style: GoogleFonts.plusJakartaSans(
                            color: primaryColor,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showEditNameDialog(context, settings),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                settings.userName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                settings.userEmail.isNotEmpty ? settings.userEmail : "user@example.com",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : const Color(0xFF5B4041),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (Provider.of<RecordProvider>(context, listen: false).records.length >= 50)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Premium Plan",
                        style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: primaryColor),
                      ),
                    ),
                  if (settings.userEmail.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: secondaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Verified Member",
                        style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: secondaryColor),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(
    BuildContext context,
    SettingsProvider settings,
    Color primaryColor,
    bool isDark,
  ) {
    final themes = [
      'Default',
      'Midnight Ocean',
      'Sunset Glow',
      'Forest Emerald',
      'Cherry Blossom',
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: themes.length,
        itemBuilder: (context, index) {
          final themeName = themes[index];
          final isSelected = settings.appTheme == themeName;

          Color displayColor;
          if (themeName == 'Default') {
            displayColor = const Color(0xFF4143D5);
          } else {
            final tInfo = PremiumThemes.getTheme(themeName);
            displayColor = tInfo.primaryColor;
          }

          return GestureDetector(
            onTap: () {
              settings.setAppTheme(themeName);
              ToastHelper.showToast(context, 'Theme updated to $themeName');
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? displayColor.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? displayColor
                      : (isDark ? Colors.white12 : Colors.grey.shade300),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: displayColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: displayColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.done_rounded,
                            color: displayColor,
                            size: 20,
                          )
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    themeName.split(' ').first,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F0069),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    required bool showBorder,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: showBorder
            ? Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white12
                      : Colors.black.withValues(alpha: 0.05),
                ),
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F0069),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white54
                              : const Color(0xFF5B4041),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.white30 : Colors.black26,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(
    BuildContext context,
    SettingsProvider settings,
    Color primaryColor,
  ) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Sign Out or Delete Account',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              content: Text(
                'Are you sure you want to sign out? Deleting your account will permanently wipe all your cashbooks and transactions from the server.',
                style: GoogleFonts.inter(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await settings.clearAllSettings();
                    if (context.mounted) {
                      Provider.of<RecordProvider>(context, listen: false).clear();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  child: const Text('Logout Only', style: TextStyle(color: Colors.blue)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final success = await authProvider.deleteAccount();
                    if (success) {
                      await settings.clearAllSettings();
                      if (context.mounted) {
                        Provider.of<RecordProvider>(context, listen: false).clear();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                        ToastHelper.showToast(context, 'Account deleted permanently');
                      }
                    } else if (context.mounted) {
                      ToastHelper.showToast(context, authProvider.error ?? 'Failed to delete account', isError: true);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Permanent Delete', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.delete_forever_rounded,
              color: Colors.red,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              "Delete Account & Logout",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Center(
      child: Text(
        "SmartKhata v$_appVersion\nMade with 🌸 by Z-oss-tech",
        textAlign: TextAlign.center,
        style: GoogleFonts.manrope(
          fontSize: 12,
          color: isDark ? Colors.white30 : Colors.black38,
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, SettingsProvider settings) {
    final TextEditingController controller = TextEditingController(
      text: settings.userName,
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Edit Name',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter your name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final success = await authProvider.updateProfile(controller.text, settings.userEmail);
                if (success) {
                  settings.setUserName(controller.text);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ToastHelper.showToast(context, 'Profile updated successfully!');
                  }
                } else {
                  if (context.mounted) {
                    ToastHelper.showToast(context, authProvider.error ?? 'Update failed', isError: true);
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final TextEditingController oldPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Change Password',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Old Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Confirm New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final oldPw = oldPasswordController.text;
                final newPw = newPasswordController.text;
                final confirmPw = confirmPasswordController.text;
                
                if (oldPw.isEmpty || newPw.isEmpty || confirmPw.isEmpty) {
                  ToastHelper.showToast(context, 'Please fill all fields', isError: true);
                  return;
                }
                if (newPw != confirmPw) {
                  ToastHelper.showToast(context, 'New passwords do not match', isError: true);
                  return;
                }
                
                final success = await authProvider.changePassword(oldPw, newPw);
                if (success && context.mounted) {
                  ToastHelper.showToast(context, 'Password changed successfully');
                  Navigator.pop(context);
                } else if (context.mounted) {
                  ToastHelper.showToast(context, authProvider.error ?? 'Failed to change password', isError: true);
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}
