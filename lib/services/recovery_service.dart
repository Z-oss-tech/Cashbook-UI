import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../providers/record_provider.dart';

class RecoveryService {
  static const String _deletedRecordsKey = 'deleted_records_recovery';

  // Save a deleted record to the recovery list
  static Future<void> saveDeletedRecord(RecordModel record) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_deletedRecordsKey) ?? [];

    // Add deletedTimestamp so we can expire it
    final map = record.toMap();
    map['deletedAt'] = DateTime.now().toIso8601String();
    map['recoveryType'] = 'record';

    list.insert(0, jsonEncode(map));
    await prefs.setStringList(_deletedRecordsKey, list);
  }

  // Save a deleted cashbook and its associated records
  static Future<void> saveDeletedCashbook(
    CashbookModel cashbook,
    List<RecordModel> records,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_deletedRecordsKey) ?? [];

    final map = {
      'recoveryType': 'cashbook',
      'deletedAt': DateTime.now().toIso8601String(),
      'id': cashbook.id,
      'name': cashbook.name,
      'createdAt': cashbook.createdAt.toIso8601String(),
      'description': cashbook.description,
      'records': records.map((r) => r.toMap()).toList(),
    };

    list.insert(0, jsonEncode(map));
    await prefs.setStringList(_deletedRecordsKey, list);
  }

  // Get all deleted items within the 30 days window
  static Future<List<Map<String, dynamic>>> getRecoverableItems() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_deletedRecordsKey) ?? [];

    List<Map<String, dynamic>> validItems = [];
    List<String> validStrings = [];

    final now = DateTime.now();
    for (String itemStr in list) {
      try {
        final map = jsonDecode(itemStr);
        final deletedAt = DateTime.parse(map['deletedAt']);
        // Check if older than 30 days
        if (now.difference(deletedAt).inDays <= 30) {
          validItems.add(map);
          validStrings.add(itemStr);
        }
      } catch (e) {
        // Corrupted item, skip
      }
    }

    // Auto-cleanup expired items
    if (list.length != validStrings.length) {
      await prefs.setStringList(_deletedRecordsKey, validStrings);
    }

    return validItems;
  }

  // Restore a specific item
  static Future<bool> restoreItem(
    Map<String, dynamic> itemMap,
    RecordProvider provider,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> list = prefs.getStringList(_deletedRecordsKey) ?? [];

      // Remove from shared prefs
      list.removeWhere((element) {
        try {
          return jsonDecode(element)['id'] == itemMap['id'];
        } catch (_) {
          return false;
        }
      });
      await prefs.setStringList(_deletedRecordsKey, list);

      final type = itemMap['recoveryType'] ?? 'record';

      if (type == 'cashbook') {
        // Restore Cashbook
        await provider.addCashbook(itemMap['name']);

        // Let's assume the provider inserts it at index 0 immediately
        if (provider.cashbooks.isNotEmpty) {
          final newCashbookId = provider.cashbooks.first.id;

          // Restore associated records
          if (itemMap['records'] != null) {
            List<dynamic> recs = itemMap['records'];
            for (var rec in recs) {
              final Map<String, dynamic> rMap = Map<String, dynamic>.from(rec);
              rMap['cashbookId'] = newCashbookId;
              rMap.remove('id'); // Force new ID

              final record = RecordModel.fromMap(rMap);
              await provider.addRecord(record);
            }
          }
        }
      } else {
        // Restore Record
        final cleanMap = Map<String, dynamic>.from(itemMap);
        cleanMap.remove('deletedAt');
        cleanMap.remove('recoveryType');

        final record = RecordModel.fromMap(cleanMap);
        await provider.addRecord(record);
      }

      return true;
    } catch (e) {
      print('Restore item error: $e');
      return false;
    }
  }
}
