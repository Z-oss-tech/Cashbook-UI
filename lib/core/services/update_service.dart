import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:google_fonts/google_fonts.dart';

class UpdateService {
  static const String _repoOwner = 'Z-oss-tech';
  static const String _repoName = 'Cashbook-UI';
  static const String _githubApiUrl =
      'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';

  /// Check GitHub for a newer release and show an in-app download dialog.
  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionStr =
          packageInfo.version.replaceAll(RegExp(r'[^0-9.]'), '');

      final response = await http.get(Uri.parse(_githubApiUrl));
      if (response.statusCode != 200) return;

      final data = json.decode(response.body);
      final latestVersionTag = data['tag_name'] as String?;
      if (latestVersionTag == null) return;

      final latestVersionStr =
          latestVersionTag.replaceAll(RegExp(r'[^0-9.]'), '');

      if (!_isUpdateAvailable(currentVersionStr, latestVersionStr)) return;

      // Find the APK asset download URL from the release assets
      String? apkDownloadUrl;
      final assets = data['assets'] as List<dynamic>?;
      if (assets != null) {
        for (final asset in assets) {
          final name = (asset['name'] as String?) ?? '';
          if (name.toLowerCase().endsWith('.apk')) {
            apkDownloadUrl = asset['browser_download_url'] as String?;
            break;
          }
        }
      }

      // Fallback: if no APK asset found, use the release page URL
      apkDownloadUrl ??= data['html_url'] as String?;
      if (apkDownloadUrl == null) return;

      if (context.mounted) {
        _showUpdateDialog(
          context,
          latestVersionStr,
          apkDownloadUrl,
          data['body'] as String? ?? '',
        );
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
      int c =
          i < currentParts.length ? int.tryParse(currentParts[i]) ?? 0 : 0;
      int l = i < latestParts.length ? int.tryParse(latestParts[i]) ?? 0 : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }

  // ─── The main update dialog ───────────────────────────────────────
  static void _showUpdateDialog(
    BuildContext context,
    String newVersion,
    String downloadUrl,
    String releaseNotes,
  ) {
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
              const Icon(Icons.system_update_rounded,
                  color: Colors.blueAccent, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Update Available v$newVersion",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "A new version of SmartKhata is available. Update now to get the latest features and improvements!",
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              if (releaseNotes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: SingleChildScrollView(
                    child: Text(
                      releaseNotes,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                "Later",
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.download_rounded,
                  color: Colors.white, size: 20),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _startDownloadAndInstall(context, downloadUrl, newVersion);
              },
              label: Text(
                "Install Update",
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Download with progress + install ─────────────────────────────
  static void _startDownloadAndInstall(
    BuildContext context,
    String url,
    String version,
  ) {
    // Show a modal bottom sheet with live download progress
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return _DownloadProgressWidget(
          downloadUrl: url,
          version: version,
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Stateful widget that handles the actual download + install
// ═══════════════════════════════════════════════════════════════════
class _DownloadProgressWidget extends StatefulWidget {
  final String downloadUrl;
  final String version;

  const _DownloadProgressWidget({
    required this.downloadUrl,
    required this.version,
  });

  @override
  State<_DownloadProgressWidget> createState() =>
      _DownloadProgressWidgetState();
}

class _DownloadProgressWidgetState extends State<_DownloadProgressWidget> {
  double _progress = 0;
  String _status = 'Preparing download...';
  bool _isError = false;
  bool _isComplete = false;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _downloadAndInstall();
  }

  Future<void> _downloadAndInstall() async {
    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/smartkhata_v${widget.version}.apk';

      _cancelToken = CancelToken();
      final dio = Dio();

      setState(() => _status = 'Downloading update...');

      await dio.download(
        widget.downloadUrl,
        filePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
              _status =
                  'Downloading... ${(_progress * 100).toStringAsFixed(0)}%';
            });
          }
        },
      );

      if (!mounted) return;
      setState(() {
        _isComplete = true;
        _status = 'Download complete! Installing...';
      });

      // Small delay so user sees the "complete" state
      await Future.delayed(const Duration(milliseconds: 500));

      // Open the downloaded APK to trigger Android's package installer
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        if (mounted) {
          setState(() {
            _isError = true;
            _status =
                'Could not open installer. Please install manually from Downloads.';
          });
        }
      } else {
        if (mounted) Navigator.of(context).pop();
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
      if (mounted) {
        setState(() {
          _isError = true;
          _status = 'Download failed. Please check your internet connection.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _status = 'An error occurred: ${e.toString().substring(0, 80)}';
        });
      }
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Icon
          Icon(
            _isError
                ? Icons.error_outline_rounded
                : _isComplete
                    ? Icons.check_circle_outline_rounded
                    : Icons.download_rounded,
            size: 48,
            color: _isError
                ? Colors.redAccent
                : _isComplete
                    ? Colors.green
                    : Colors.blueAccent,
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            _isError
                ? 'Update Failed'
                : _isComplete
                    ? 'Ready to Install!'
                    : 'Updating SmartKhata',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // Status text
          Text(
            _status,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),

          // Progress bar (only during download)
          if (!_isError && !_isComplete)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                minHeight: 8,
                backgroundColor:
                    isDark ? Colors.white12 : Colors.blueAccent.withValues(alpha: 0.15),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
            ),

          const SizedBox(height: 16),

          // Action buttons
          if (_isError)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel',
                      style: GoogleFonts.poppins(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _isError = false;
                      _progress = 0;
                      _status = 'Retrying...';
                    });
                    _downloadAndInstall();
                  },
                  child: Text('Retry',
                      style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ],
            )
          else if (!_isComplete)
            TextButton(
              onPressed: () {
                _cancelToken?.cancel();
                Navigator.of(context).pop();
              },
              child: Text('Cancel',
                  style: GoogleFonts.poppins(color: Colors.grey)),
            ),
        ],
      ),
    );
  }
}
