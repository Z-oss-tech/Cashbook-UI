import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();

  factory LocalStorageService() {
    return _instance;
  }

  LocalStorageService._internal();

  Future<File> _getFile(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$fileName');
  }

  // --- Cashbooks ---

  Future<List<Map<String, dynamic>>> getCashbooks() async {
    try {
      final file = await _getFile('cashbooks.json');
      if (!await file.exists()) {
        return [];
      }
      final contents = await file.readAsString();
      if (contents.isEmpty) return [];
      final List<dynamic> jsonList = jsonDecode(contents);
      return jsonList.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print('Error reading cashbooks from local storage: $e');
      return [];
    }
  }

  Future<void> saveCashbooks(List<Map<String, dynamic>> cashbooks) async {
    try {
      final file = await _getFile('cashbooks.json');
      await file.writeAsString(jsonEncode(cashbooks));
    } catch (e) {
      print('Error saving cashbooks to local storage: $e');
    }
  }

  // --- Records ---

  Future<List<Map<String, dynamic>>> getRecords() async {
    try {
      final file = await _getFile('records.json');
      if (!await file.exists()) {
        return [];
      }
      final contents = await file.readAsString();
      if (contents.isEmpty) return [];
      final List<dynamic> jsonList = jsonDecode(contents);
      return jsonList.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print('Error reading records from local storage: $e');
      return [];
    }
  }

  Future<void> saveRecords(List<Map<String, dynamic>> records) async {
    try {
      final file = await _getFile('records.json');
      await file.writeAsString(jsonEncode(records));
    } catch (e) {
      print('Error saving records to local storage: $e');
    }
  }

  // --- Pending Sync Queue ---

  Future<List<Map<String, dynamic>>> getPendingSyncQueue() async {
    try {
      final file = await _getFile('pending_sync.json');
      if (!await file.exists()) {
        return [];
      }
      final contents = await file.readAsString();
      if (contents.isEmpty) return [];
      final List<dynamic> jsonList = jsonDecode(contents);
      return jsonList.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print('Error reading pending sync queue: $e');
      return [];
    }
  }

  Future<void> savePendingSyncQueue(List<Map<String, dynamic>> queue) async {
    try {
      final file = await _getFile('pending_sync.json');
      await file.writeAsString(jsonEncode(queue));
    } catch (e) {
      print('Error saving pending sync queue: $e');
    }
  }

  Future<void> addPendingSyncAction({
    required String action,
    required Map<String, dynamic> payload,
    String? targetId,
  }) async {
    final queue = await getPendingSyncQueue();

    // Create a unique action ID based on timestamp
    final String actionId =
        '${action}_${DateTime.now().microsecondsSinceEpoch}';

    queue.add({
      'id': actionId,
      'action': action,
      'payload': payload,
      'targetId': targetId,
      'timestamp': DateTime.now().toIso8601String(),
    });

    await savePendingSyncQueue(queue);
    print('Sync action added to queue: $action (ID: $actionId)');
  }

  Future<void> removePendingSyncAction(String actionId) async {
    final queue = await getPendingSyncQueue();
    queue.removeWhere((item) => item['id'] == actionId);
    await savePendingSyncQueue(queue);
    print('Sync action removed from queue: $actionId');
  }

  // --- Clear All Cache ---

  Future<void> clearAll() async {
    try {
      final files = ['cashbooks.json', 'records.json', 'pending_sync.json'];
      for (var fileName in files) {
        final file = await _getFile(fileName);
        if (await file.exists()) {
          await file.delete();
        }
      }
      print('Local storage cache cleared completely.');
    } catch (e) {
      print('Error clearing local storage cache: $e');
    }
  }
}
