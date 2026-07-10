// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction_model.dart';
import '../providers/record_provider.dart';

class BackupService {
  static const String _backupHistoryKey = 'backup_history_list';

  // Create a backup file and share it
  static Future<bool> exportBackup(
    RecordProvider recordProvider, {
    bool isPreMigration = false,
  }) async {
    try {
      final data = {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'cashbooks': recordProvider.cashbooks
            .map(
              (c) => {
                'id': c.id,
                'name': c.name,
                'createdAt': c.createdAt.toIso8601String(),
                'description': c.description,
              },
            )
            .toList(),
        'records': recordProvider.records.map((r) => r.toMap()).toList(),
      };

      final jsonStr = jsonEncode(data);
      final bytesLength = utf8.encode(jsonStr).length;
      final sizeString = _formatSize(bytesLength);

      final directory = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final File file = File(
        '${directory.path}/SmartKhata_Backup_$timestamp.json',
      );
      await file.writeAsString(jsonStr);

      // Fallback for older versions if SharePlus is not present, but based on info:
      // 'Share' is deprecated and shouldn't be used. Use SharePlus instead
      // 'shareXFiles' is deprecated... Use SharePlus.instance.share() instead
      // Let's use the new recommended method if possible.
      // Wait, actually Share.shareXFiles works fine and is just a warning, but let's change it.
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'SmartKhata Backup File');

      await _recordBackupHistory(
        isPreMigration ? 'PRE_MIGRATION Backup' : 'MANUAL Backup',
        recordProvider.records.length,
        sizeString,
      );

      return true;
    } catch (e) {
      print('Export error: $e');
      return false;
    }
  }

  // Pick and read a backup file
  static Future<Map<String, dynamic>?> pickAndReadBackup() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String contents = await file.readAsString();
        final data = jsonDecode(contents);
        return data as Map<String, dynamic>;
      }
    } catch (e) {
      print('Read backup error: $e');
    }
    return null;
  }

  // Restore data from parsed JSON
  static Future<bool> restoreBackup(
    Map<String, dynamic> data,
    RecordProvider recordProvider,
  ) async {
    try {
      if (data['cashbooks'] == null || data['records'] == null) return false;

      List<dynamic> cashbooksData = data['cashbooks'];
      List<dynamic> recordsData = data['records'];

      // Clear current data completely before restore to avoid duplications
      // Since RecordProvider handles offline and online, we will push the new ones.
      // 1. We create cashbooks and build a map of old ID -> new ID
      Map<String, String> idMap = {};

      // Store current length to avoid overlapping UI state
      for (var cbData in cashbooksData) {
        final Map<String, dynamic> cMap = Map<String, dynamic>.from(cbData);
        final String oldId = cMap['id'];

        // Let's insert them through provider
        await recordProvider.addCashbook(cMap['name']);

        // The provider adds it at index 0. Get the newly assigned ID.
        if (recordProvider.cashbooks.isNotEmpty) {
          idMap[oldId] = recordProvider.cashbooks.first.id;
        }
      }

      // 2. We inject the new cashbook IDs into the records before inserting
      for (var recData in recordsData) {
        final Map<String, dynamic> rMap = Map<String, dynamic>.from(recData);
        final oldCashbookId = rMap['cashbookId'];

        if (idMap.containsKey(oldCashbookId)) {
          rMap['cashbookId'] = idMap[oldCashbookId];

          final record = RecordModel.fromMap(rMap);
          await recordProvider.addRecord(record);
        }
      }

      return true;
    } catch (e) {
      print('Restore error: $e');
      return false;
    }
  }

  static Future<void> _recordBackupHistory(
    String type,
    int recordsCount,
    String sizeStr,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_backupHistoryKey) ?? [];

    final entry = {
      'type': type,
      'records': recordsCount,
      'size': sizeStr,
      'timestamp': DateTime.now().toIso8601String(),
    };

    history.insert(0, jsonEncode(entry));
    if (history.length > 20) history = history.sublist(0, 20);

    await prefs.setStringList(_backupHistoryKey, history);
  }

  static Future<List<Map<String, dynamic>>> getBackupHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_backupHistoryKey) ?? [];
    return history
        .map((e) => Map<String, dynamic>.from(jsonDecode(e)))
        .toList();
  }

  static Future<DateTime?> getLastBackupTime() async {
    final history = await getBackupHistory();
    if (history.isEmpty) return null;
    return DateTime.parse(history.first['timestamp']);
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
