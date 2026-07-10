// ignore_for_file: unused_field, unused_element, unused_local_variable
import 'package:cashbook/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';

import '../../providers/settings_provider.dart';
import '../../providers/record_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/toast_helper.dart';
import '../../core/services/notification_service.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import '../auth/login_screen.dart';
import '../../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF191C1E) : const Color(0xFFF8F9FF);
    final textColor = isDark ? Colors.white : const Color(0xFF0B1C30);
    final outlineColor = isDark ? Colors.white54 : const Color(0xFF767586);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopAppBar(context, textColor),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    _buildProfileCard(context, settings),
                    const SizedBox(height: 32),

                    _buildSectionHeader("GENERAL", outlineColor),
                    const SizedBox(height: 8),
                    _buildGlassCard(
                      context,
                      child: Column(
                        children: [
                          _buildMenuTile(
                            context: context,
                            icon: Icons.info_rounded,
                            iconBgColor: isDark
                                ? Colors.white12
                                : const Color(0xFFDCE9FF),
                            iconColor: const Color(0xFF4143D5),
                            title: "About App",
                            subtitle: "Version 1.0.0",
                            onTap: () {
                              ToastHelper.showToast(
                                context,
                                'SmartKhata v1.0.0',
                              );
                            },
                            showBorder: true,
                          ),
                          _buildMenuTile(
                            context: context,
                            icon: Icons.system_update_rounded,
                            iconBgColor: isDark
                                ? Colors.white12
                                : const Color(0xFFDCE9FF),
                            iconColor: const Color(0xFF4143D5),
                            title: "App Updates",
                            subtitle: "Check for new versions",
                            onTap: () async {
                              ToastHelper.showToast(
                                context,
                                'Checking for updates...',
                              );
                              try {
                                final res = await ApiService()
                                    .getLatestAppUpdate();
                                if (!mounted) return;

                                if (res['updateAvailable'] == true &&
                                    res['update'] != null) {
                                  final update = res['update'];
                                  final newVersion =
                                      update['version'] ?? '0.0.0';

                                  if (_isVersionGreater(
                                    currentAppVersion,
                                    newVersion,
                                  )) {
                                    _showUpdateDialog(
                                      context,
                                      version: newVersion,
                                      description:
                                          update['description'] ??
                                          'No description available',
                                      size: update['size'] ?? 'Unknown size',
                                      downloadUrl:
                                          update['downloadUrl'] ??
                                          'https://github.com/Z-oss-tech/Cashbook-UI/releases',
                                    );
                                    NotificationService()
                                        .showUpdateNotification(
                                          version: newVersion,
                                        );
                                  } else {
                                    ToastHelper.showToast(
                                      context,
                                      'You are up to date!',
                                    );
                                  }
                                } else {
                                  ToastHelper.showToast(
                                    context,
                                    'You are up to date!',
                                  );
                                }
                              } catch (e) {
                                if (mounted)
                                  ToastHelper.showToast(
                                    context,
                                    'Failed to check updates',
                                    isError: true,
                                  );
                              }
                            },
                            showBorder: false,
                          ),
                        ],
                      ),
                    ),
                    _buildSectionHeader("SECURITY", outlineColor),
                    const SizedBox(height: 8),
                    _buildGlassCard(
                      context,
                      child: Column(
                        children: [
                          _buildMenuTile(
                            context: context,
                            icon: Icons.lock_outline_rounded,
                            iconBgColor: isDark
                                ? Colors.white12
                                : const Color(0xFFFFE4E4),
                            iconColor: const Color(0xFFE53935),
                            title: "Change Password",
                            subtitle: "Update your login password",
                            onTap: () => _showChangePasswordDialog(context),
                            showBorder: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildLogoutButton(context, settings),
                    const SizedBox(height: 48),

                    _buildFooter(outlineColor),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const String currentAppVersion = '1.0.0';

  bool _isVersionGreater(String currentVersion, String newVersion) {
    try {
      List<int> currentParts = currentVersion
          .split('+')
          .first
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();
      List<int> newParts = newVersion
          .split('+')
          .first
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();

      for (int i = 0; i < 3; i++) {
        int currentPart = i < currentParts.length ? currentParts[i] : 0;
        int newPart = i < newParts.length ? newParts[i] : 0;
        if (newPart > currentPart) return true;
        if (newPart < currentPart) return false;
      }
    } catch (_) {
      // Fallback
    }
    return false;
  }

  void _showUpdateDialog(
    BuildContext context, {
    required String version,
    required String description,
    required String size,
    required String downloadUrl,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isDownloading = false;
    double progress = 0.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF2D3133) : Colors.white,
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
                      color: isDark ? Colors.white : const Color(0xFF191C1E),
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
                      color: isDark ? Colors.white : const Color(0xFF191C1E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
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
                          "Version $version • $size",
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
                  if (isDownloading) ...[
                    const SizedBox(height: 20),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade300,
                      color: const Color(0xFF4143D5),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        "${(progress * 100).toStringAsFixed(1)}%",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF191C1E),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                if (!isDownloading)
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(
                      "Later",
                      style: GoogleFonts.inter(
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ElevatedButton(
                  onPressed: isDownloading
                      ? null
                      : () async {
                          setState(() {
                            isDownloading = true;
                            progress = 0.0;
                          });

                          try {
                            final directory = await getTemporaryDirectory();
                            final filePath =
                                '${directory.path}/smartkhata_update_$version.apk';

                            final dio = Dio();
                            await dio.download(
                              downloadUrl,
                              filePath,
                              onReceiveProgress: (received, total) {
                                if (total != -1) {
                                  setState(() {
                                    progress = received / total;
                                  });
                                }
                              },
                            );

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                              OpenFilex.open(filePath);
                            }
                          } catch (e) {
                            setState(() {
                              isDownloading = false;
                              progress = 0.0;
                            });
                            if (dialogContext.mounted) {
                              ToastHelper.showToast(
                                dialogContext,
                                'Failed to download update',
                                isError: true,
                              );
                              // Fallback to browser
                              final Uri url = Uri.parse(downloadUrl);
                              launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4143D5),
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    isDownloading ? "Downloading..." : "Install Update",
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
      },
    );
  }

  Widget _buildTopAppBar(BuildContext context, Color textColor) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.centerLeft,
      child: Text(
        "My Profile",
        style: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, SettingsProvider settings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF4143D5), Color(0xFF5B3CDD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4143D5).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -40,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFF7459F7).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        settings.userAvatar,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.userName,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Smart Finance User",
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _showEditNameDialog(context, settings),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
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
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context, {required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(24), child: child),
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
    required bool showBorder,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0B1C30);
    final subtitleColor = isDark ? Colors.white54 : const Color(0xFF767586);

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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFF4143D5),
                  inactiveThumbColor: Colors.white,
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
    Color? subtitleColor,
    required VoidCallback onTap,
    required bool showBorder,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0B1C30);
    final defaultSubtitleColor = isDark
        ? Colors.white54
        : const Color(0xFF767586);

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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: subtitleColor ?? defaultSubtitleColor,
                          fontWeight: subtitleColor != null
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.white30 : const Color(0xFFC6C5D7),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSquareCard({
    required BuildContext context,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2D3133) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0B1C30);
    final subtitleColor = isDark ? Colors.white54 : const Color(0xFF767586);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 10, color: subtitleColor),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, SettingsProvider settings) {
    return GestureDetector(
      onTap: () async {
        await settings.clearAllSettings();
        if (context.mounted) {
          Provider.of<RecordProvider>(context, listen: false).clear();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFFBA1A1A), Color(0xFFFF5252)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFBA1A1A).withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              "Logout",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(Color outlineColor) {
    return Column(
      children: [
        Text(
          "SmartKhata",
          style: GoogleFonts.inter(
            color: outlineColor,
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Version 1.0.0",
          style: GoogleFonts.inter(color: outlineColor, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          "SmartKhata © 2026",
          style: GoogleFonts.inter(color: outlineColor, fontSize: 14),
        ),
      ],
    );
  }

  void _showEditNameDialog(BuildContext context, SettingsProvider settings) {
    final TextEditingController controller = TextEditingController(
      text: settings.userName,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            "Edit Name",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            style: GoogleFonts.inter(),
            decoration: InputDecoration(
              hintText: "Enter your name",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF4143D5),
                  width: 2,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white54 : Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4143D5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  settings.setUserName(controller.text.trim());
                }
                Navigator.pop(context);
              },
              child: Text(
                AppLocalizations.of(context)!.save,
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context, SettingsProvider settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context)!.language,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Theme.of(context).cardColor,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  AppLocalizations.of(context)!.english,
                  style: GoogleFonts.inter(),
                ),
                trailing: settings.locale.languageCode == 'en'
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF4143D5),
                      )
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  settings.setLocale(const Locale('en'));
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text(
                  AppLocalizations.of(context)!.hindi,
                  style: GoogleFonts.inter(),
                ),
                trailing: settings.locale.languageCode == 'hi'
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF4143D5),
                      )
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  settings.setLocale(const Locale('hi'));
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isObscureCurrent = true;
    bool isObscureNew = true;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF2D3133) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                "Change Password",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF191C1E),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPasswordController,
                    obscureText: isObscureCurrent,
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white : const Color(0xFF191C1E),
                    ),
                    decoration: InputDecoration(
                      hintText: "Current Password",
                      hintStyle: GoogleFonts.inter(
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF4143D5),
                          width: 2,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isObscureCurrent
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: isDark ? Colors.white54 : Colors.grey,
                        ),
                        onPressed: () => setState(
                          () => isObscureCurrent = !isObscureCurrent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPasswordController,
                    obscureText: isObscureNew,
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white : const Color(0xFF191C1E),
                    ),
                    decoration: InputDecoration(
                      hintText: "New Password",
                      hintStyle: GoogleFonts.inter(
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF4143D5),
                          width: 2,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isObscureNew
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: isDark ? Colors.white54 : Colors.grey,
                        ),
                        onPressed: () =>
                            setState(() => isObscureNew = !isObscureNew),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white54 : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return ElevatedButton(
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
                      onPressed: authProvider.isLoading
                          ? null
                          : () async {
                              final currentPassword = currentPasswordController
                                  .text
                                  .trim();
                              final newPassword = newPasswordController.text
                                  .trim();

                              if (currentPassword.isEmpty ||
                                  newPassword.isEmpty) {
                                ToastHelper.showToast(
                                  context,
                                  'Both passwords are required',
                                  isError: true,
                                );
                                return;
                              }

                              final success = await authProvider.changePassword(
                                currentPassword,
                                newPassword,
                              );

                              if (context.mounted) {
                                if (success) {
                                  Navigator.pop(dialogContext);
                                  ToastHelper.showToast(
                                    context,
                                    'Password changed successfully',
                                  );
                                } else {
                                  ToastHelper.showToast(
                                    context,
                                    authProvider.error ??
                                        'Failed to change password',
                                    isError: true,
                                  );
                                }
                              }
                            },
                      child: authProvider.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              "Update",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
