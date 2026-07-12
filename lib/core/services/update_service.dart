import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

class UpdateService {
  static const String _repoOwner = 'Z-oss-tech';
  static const String _repoName = 'Cashbook-UI';
  static const String _githubApiUrl =
      'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';

  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionStr = packageInfo.version;

      final response = await http.get(Uri.parse(_githubApiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersionTag = data['tag_name'] as String?;
        final releaseUrl = data['html_url'] as String?;

        if (latestVersionTag != null && releaseUrl != null) {
          final latestVersionStr = latestVersionTag.replaceAll(RegExp(r'[^0-9.]'), '');
          final currentVersionClean = currentVersionStr.replaceAll(RegExp(r'[^0-9.]'), '');

          if (_isUpdateAvailable(currentVersionClean, latestVersionStr)) {
            if (context.mounted) {
              _showUpdateDialog(context, latestVersionStr, releaseUrl);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  static bool _isUpdateAvailable(String current, String latest) {
    List<String> currentParts = current.split('.');
    List<String> latestParts = latest.split('.');

    int length = currentParts.length > latestParts.length
        ? currentParts.length
        : latestParts.length;

    for (int i = 0; i < length; i++) {
      int c = i < currentParts.length ? int.tryParse(currentParts[i]) ?? 0 : 0;
      int l = i < latestParts.length ? int.tryParse(latestParts[i]) ?? 0 : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }

  static void _showUpdateDialog(
      BuildContext context, String newVersion, String url) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.system_update_rounded, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Text(
                "Update Available",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            "Version $newVersion is now available. You are using an older version. Would you like to update to the latest version for new features and improvements?",
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                "Later",
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: Text(
                "Update Now",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
