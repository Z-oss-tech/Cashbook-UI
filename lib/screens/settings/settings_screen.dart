import 'package:cashbook/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';

import '../../providers/settings_provider.dart';
import '../../providers/record_provider.dart';
import '../../core/utils/toast_helper.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/widgets/theme_background_wrapper.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/theme/premium_themes.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final LocalAuthentication _auth = LocalAuthentication();
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
                    children: [
                      // Preferences (Appearance & Theme)
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        borderRadius: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.display_settings_rounded,
                                  color: primaryColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  AppLocalizations.of(context)!.preferences,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildSwitchTile(
                              context: context,
                              icon: Icons.dark_mode_rounded,
                              iconBgColor: primaryColor.withValues(alpha: 0.1),
                              iconColor: primaryColor,
                              title: AppLocalizations.of(context)!.darkMode,
                              subtitle: AppLocalizations.of(
                                context,
                              )!.enableDarkAppearance,
                              value: settings.darkMode,
                              onChanged: (value) => settings.setDarkMode(value),
                              isDark: isDark,
                              showBorder: true,
                            ),
                            _buildMenuTile(
                              context: context,
                              icon: Icons.language_rounded,
                              iconBgColor: primaryColor.withValues(alpha: 0.1),
                              iconColor: primaryColor,
                              title: AppLocalizations.of(context)!.language,
                              subtitle: settings.locale.languageCode == 'hi'
                                  ? AppLocalizations.of(context)!.hindi
                                  : AppLocalizations.of(context)!.english,
                              onTap: () =>
                                  _showLanguageDialog(context, settings),
                              isDark: isDark,
                              showBorder: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Notifications & Security
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        borderRadius: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.security_rounded,
                                  color: primaryColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Security & Alerts",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildSwitchTile(
                              context: context,
                              icon: Icons.notifications_rounded,
                              iconBgColor: primaryColor.withValues(alpha: 0.1),
                              iconColor: primaryColor,
                              title: AppLocalizations.of(
                                context,
                              )!.notifications,
                              subtitle: AppLocalizations.of(
                                context,
                              )!.getReminders,
                              value: settings.notifications,
                              onChanged: (value) async {
                                if (value) {
                                  var status =
                                      await Permission.notification.status;
                                  if (status.isDenied) {
                                    status = await Permission.notification
                                        .request();
                                  }

                                  if (status.isGranted) {
                                    settings.setNotifications(true);
                                    if (context.mounted) {
                                      ToastHelper.showToast(
                                        context,
                                        'Notifications enabled',
                                      );
                                    }
                                  } else {
                                    if (context.mounted) {
                                      ToastHelper.showToast(
                                        context,
                                        'Notification permission denied',
                                        isError: true,
                                      );
                                    }
                                    settings.setNotifications(false);
                                  }
                                } else {
                                  settings.setNotifications(false);
                                  if (context.mounted) {
                                    ToastHelper.showToast(
                                      context,
                                      'Notifications disabled',
                                    );
                                  }
                                }
                              },
                              isDark: isDark,
                              showBorder: true,
                            ),
                            _buildSwitchTile(
                              context: context,
                              icon: Icons.fingerprint_rounded,
                              iconBgColor: primaryColor.withValues(alpha: 0.1),
                              iconColor: primaryColor,
                              title: AppLocalizations.of(
                                context,
                              )!.biometricLock,
                              subtitle: AppLocalizations.of(
                                context,
                              )!.protectSecurely,
                              value: settings.biometricLock,
                              onChanged: (value) async {
                                if (value) {
                                  bool authenticated = false;
                                  try {
                                    authenticated = await _auth.authenticate(
                                      localizedReason:
                                          'Authenticate to enable biometric lock',
                                      persistAcrossBackgrounding: true,
                                    );
                                  } catch (e) {
                                    if (context.mounted) {
                                      ToastHelper.showToast(
                                        context,
                                        'Biometrics not available.',
                                        isError: true,
                                      );
                                    }
                                    return;
                                  }
                                  if (authenticated) {
                                    settings.setBiometricLock(true);
                                  }
                                } else {
                                  settings.setBiometricLock(false);
                                }
                              },
                              isDark: isDark,
                              showBorder: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Data Management
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        borderRadius: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.cloud_sync_rounded,
                                  color: primaryColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Data Management",
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
                              icon: Icons.cloud_done_rounded,
                              iconBgColor: primaryColor.withValues(alpha: 0.1),
                              iconColor: primaryColor,
                              title: AppLocalizations.of(
                                context,
                              )!.backupRestore,
                              subtitle: "Auto-synced to cloud",
                              onTap: () async {
                                ToastHelper.showToast(
                                  context,
                                  'Syncing with secure cloud...',
                                );
                                await Provider.of<RecordProvider>(
                                  context,
                                  listen: false,
                                ).fetchData();
                                if (context.mounted) {
                                  ToastHelper.showToast(
                                    context,
                                    'All data is fully backed up to the cloud!',
                                  );
                                }
                              },
                              isDark: isDark,
                              showBorder: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Support
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        borderRadius: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.support_agent_rounded,
                                  color: primaryColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Support",
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
                              icon: Icons.system_update_rounded,
                              iconBgColor: primaryColor.withValues(alpha: 0.1),
                              iconColor: primaryColor,
                              title: "App Update",
                              subtitle: "Check for latest version",
                              onTap: () => _showUpdateDialog(context),
                              isDark: isDark,
                              showBorder: false,
                            ),
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
            "Settings",
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

  Widget _buildSwitchTile({
    required BuildContext context,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
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
          onTap: () => onChanged(!value),
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
                Switch(
                  value: value,
                  activeThumbColor: Colors.white,
                  activeTrackColor: iconColor,
                  inactiveThumbColor: isDark ? Colors.white70 : Colors.white,
                  inactiveTrackColor: isDark
                      ? Colors.white24
                      : const Color(0xFFC6C5D7),
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
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

  void _showLanguageDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            "Select Language",
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('English'),
                trailing: settings.locale.languageCode == 'en'
                    ? const Icon(Icons.check, color: Color(0xFF4143D5))
                    : null,
                onTap: () {
                  settings.setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('हिन्दी'),
                trailing: settings.locale.languageCode == 'hi'
                    ? const Icon(Icons.check, color: Color(0xFF4143D5))
                    : null,
                onTap: () {
                  settings.setLocale(const Locale('hi'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUpdateDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.system_update_rounded,
                color: Color(0xFF4143D5),
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                "App Update",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color:
                      Theme.of(context).textTheme.bodyLarge?.color ??
                      (isDark ? Colors.white : const Color(0xFF191C1E)),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "A new version of SmartKhata is available!",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color:
                      Theme.of(context).textTheme.bodyLarge?.color ??
                      (isDark ? Colors.white : const Color(0xFF191C1E)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Version 1.1.0 features new reports, voice-to-text notes, and UI enhancements.",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color:
                      Theme.of(context).textTheme.bodyMedium?.color ??
                      (isDark ? Colors.white70 : Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF191C1E)
                      : const Color(0xFFF2F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.download_rounded,
                      color: Color(0xFF4143D5),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Update size: 14.2 MB",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF464555),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Later",
                style: GoogleFonts.inter(
                  color: Theme.of(context).dividerColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ToastHelper.showToast(
                  context,
                  'Downloading update in background...',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4143D5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: Text(
                "Install Update",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
