import 'package:cashbook/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../../providers/record_provider.dart';
import '../../core/utils/toast_helper.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        title: Text(
          AppLocalizations.of(context)!.settings,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            // Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),

              decoration: BoxDecoration(
                borderRadius:
                BorderRadius.circular(30),

                gradient: const LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),

                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary
                        .withOpacity(0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),

              child: Row(
                children: [

                  // Avatar
                  Container(
                    height: 70,
                    width: 70,

                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius:
                      BorderRadius.circular(22),
                    ),

                    child: Center(
                      child: Text(
                        settings.userAvatar,

                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 18),

                  // Name & Email
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [

                        Text(
                          settings.userName,

                          style:
                          GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "Smart Finance User",

                          style:
                          GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => _showEditNameDialog(context, settings),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Preferences
            _buildSectionTitle(AppLocalizations.of(context)!.preferences),

            const SizedBox(height: 16),

            _buildSwitchTile(
              icon: Icons.dark_mode_rounded,
              title: AppLocalizations.of(context)!.darkMode,
              subtitle:
              AppLocalizations.of(context)!.enableDarkAppearance,
              value: settings.darkMode,
              onChanged: (value) {
                settings.setDarkMode(value);
              },
            ),

            _buildSwitchTile(
              icon: Icons.notifications_active,
              title: AppLocalizations.of(context)!.notifications,
              subtitle:
              AppLocalizations.of(context)!.getReminders,
              value: settings.notifications,
              onChanged: (value) {
                settings.setNotifications(value);
              },
            ),

            _buildSwitchTile(
              icon: Icons.fingerprint_rounded,
              title: AppLocalizations.of(context)!.biometricLock,
              subtitle:
              AppLocalizations.of(context)!.protectSecurely,
              value: settings.biometricLock,
              onChanged: (value) async {
                if (value) {
                  bool authenticated = false;
                  try {
                    authenticated = await _auth.authenticate(
                      localizedReason: 'Authenticate to enable biometric lock',
                      persistAcrossBackgrounding: true,
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ToastHelper.showToast(context, 'Biometrics not available.', isError: true);
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
            ),

            const SizedBox(height: 30),

            // General
            _buildSectionTitle(AppLocalizations.of(context)!.general),

            const SizedBox(height: 16),

            _buildMenuTile(
              icon: Icons.language_rounded,
              title: AppLocalizations.of(context)!.language,
              subtitle: settings.locale.languageCode == 'hi' 
                  ? AppLocalizations.of(context)!.hindi 
                  : AppLocalizations.of(context)!.english,
              onTap: () {
                _showLanguageDialog(context, settings);
              },
            ),

            _buildMenuTile(
              icon: Icons.cloud_sync_rounded,
              title: AppLocalizations.of(context)!.backupRestore,
              subtitle: "Auto-synced to cloud",
              onTap: () async {
                ToastHelper.showToast(context, 'Syncing with secure cloud...');
                await Provider.of<RecordProvider>(context, listen: false).fetchData();
                if (context.mounted) {
                  ToastHelper.showToast(context, 'All data is fully backed up to the cloud!');
                }
              },
            ),



            _buildMenuTile(
              icon: Icons.info_outline_rounded,
              title: "About App",
              subtitle: "Version 1.0.0",
              onTap: () {
                ToastHelper.showToast(context, 'SmartKhata v1.0.0');
              },
            ),

            const SizedBox(height: 40),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 58,

              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  elevation: 0,

                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(18),
                  ),
                ),

                onPressed: () async {
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

                icon: const Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                ),

                label: Text(
                  "Logout",

                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight:
                    FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Footer
            Text(
              "SmartKhata © 2026",

              style: GoogleFonts.poppins(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,

      child: Text(
        title,

        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [

          Container(
            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: AppColors.primary
                  .withOpacity(0.12),

              borderRadius:
              BorderRadius.circular(16),
            ),

            child: Icon(
              icon,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                Text(
                  title,

                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,

                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Switch(
            value: value,
            activeThumbColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: Row(
        children: [

          Container(
            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: AppColors.primary
                  .withOpacity(0.12),

              borderRadius:
              BorderRadius.circular(16),
            ),

            child: Icon(
              icon,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                Text(
                  title,

                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,

                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 18,
            color: Colors.grey,
          ),
        ],
      ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, SettingsProvider settings) {
    final TextEditingController controller = TextEditingController(text: settings.userName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Name"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Enter your name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  settings.setUserName(controller.text.trim());
                }
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.language),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Theme.of(context).cardColor,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(AppLocalizations.of(context)!.english),
                trailing: settings.locale.languageCode == 'en' 
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  settings.setLocale(const Locale('en'));
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.hindi),
                trailing: settings.locale.languageCode == 'hi' 
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
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
}