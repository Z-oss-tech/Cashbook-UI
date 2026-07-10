import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../services/recovery_service.dart';
import '../core/services/notification_service.dart';

class RecordProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final LocalStorageService _localStorageService = LocalStorageService();

  List<RecordModel> _records = [];
  List<CashbookModel> _cashbooks = [];

  bool _isLoading = false;
  String? _error;
  bool _isOfflineMode = false;
  bool _isSyncing = false;
  int _pendingCount = 0;

  List<RecordModel> get records => _records;
  List<CashbookModel> get cashbooks => _cashbooks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOfflineMode => _isOfflineMode;
  bool get isSyncing => _isSyncing;
  int get pendingCount => _pendingCount;

  // Initialize by reading immediately from local storage cache
  Future<void> initLocalCache() async {
    final cachedBooks = await _localStorageService.getCashbooks();
    _cashbooks = cachedBooks.map((e) => CashbookModel.fromMap(e)).toList();

    final cachedRecords = await _localStorageService.getRecords();
    _records = cachedRecords.map((e) => RecordModel.fromMap(e)).toList();

    final queue = await _localStorageService.getPendingSyncQueue();
    _pendingCount = queue.length;

    notifyListeners();
  }

  Future<void> fetchData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Ensure we load cached data instantly first
    await initLocalCache();

    // Check if the user is in Guest/Offline mode
    final prefs = await SharedPreferences.getInstance();
    final isGuest = prefs.getString('auth_token') == 'offline_token';
    if (isGuest) {
      _isOfflineMode = true;
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final cashbooksData = await _apiService.getCashbooks();
      final List<Map<String, dynamic>> serializedBooks = cashbooksData
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _cashbooks = serializedBooks
          .map((e) => CashbookModel.fromMap(e))
          .toList();
      await _localStorageService.saveCashbooks(serializedBooks);

      final recordsData = await _apiService.getRecords();
      final List<Map<String, dynamic>> serializedRecords = recordsData.map((e) {
        var map = Map<String, dynamic>.from(e as Map);
        // Find cashbook name using cashbookId
        var cb = _cashbooks.firstWhere(
          (c) => c.id == map['cashbookId'],
          orElse: () => CashbookModel(
            id: '',
            name: 'TestBook',
            createdAt: DateTime.now(),
          ),
        );
        map['cashbookName'] = cb.name;
        return map;
      }).toList();
      _records = serializedRecords.map((e) => RecordModel.fromMap(e)).toList();
      await _localStorageService.saveRecords(serializedRecords);

      _isOfflineMode = false;

      // Auto-trigger sync queue in the background when connected
      if (_pendingCount > 0) {
        syncOfflineQueue();
      }
    } catch (e) {
      print('Fetch error: $e');
      if (e.toString().contains('network_error')) {
        _isOfflineMode = true;
      } else {
        _error = e.toString().replaceAll('Exception: ', '');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Cashbooks ---

  Future<void> addCashbook(String name) async {
    final String tempId = 'local_cb_${DateTime.now().millisecondsSinceEpoch}';
    final newBook = CashbookModel(
      id: tempId,
      name: name,
      createdAt: DateTime.now(),
    );

    // Optimistic UI update: Insert local item and save cache
    _cashbooks.insert(0, newBook);
    await _saveLocalBooks();
    notifyListeners();

    if (_isOfflineMode) {
      await _localStorageService.addPendingSyncAction(
        action: 'create_cashbook',
        payload: {'id': tempId, 'name': name},
      );
      _pendingCount++;
      notifyListeners();
      return;
    }

    // Do NOT block the UI. Fire and forget the API call.
    _syncNewCashbook(tempId, name);
  }

  Future<void> _syncNewCashbook(String tempId, String name) async {
    try {
      final res = await _apiService.createCashbook({'name': name});
      if (res['cashbook'] != null) {
        // Swap temp cashbook with official one
        final index = _cashbooks.indexWhere((c) => c.id == tempId);
        if (index != -1) {
          _cashbooks[index] = CashbookModel.fromMap(res['cashbook']);
          await _saveLocalBooks();
          notifyListeners();
        }
      }
    } catch (e) {
      print('Failed to add cashbook online, queuing offline: $e');
      _isOfflineMode = true;
      await _localStorageService.addPendingSyncAction(
        action: 'create_cashbook',
        payload: {'id': tempId, 'name': name},
      );
      _pendingCount++;
      notifyListeners();
    }
  }

  Future<void> updateCashbook(String id, String newName) async {
    // Optimistic update
    final index = _cashbooks.indexWhere((c) => c.id == id);
    if (index != -1) {
      final oldBook = _cashbooks[index];
      _cashbooks[index] = CashbookModel(
        id: oldBook.id,
        name: newName,
        createdAt: oldBook.createdAt,
        description: oldBook.description,
      );
      await _saveLocalBooks();
      notifyListeners();
    }

    if (_isOfflineMode) {
      await _localStorageService.addPendingSyncAction(
        action: 'update_cashbook',
        payload: {'name': newName},
        targetId: id,
      );
      _pendingCount++;
      notifyListeners();
      return;
    }

    // Do NOT block the UI. Fire and forget.
    _syncUpdateCashbook(id, newName);
  }

  Future<void> _syncUpdateCashbook(String id, String newName) async {
    try {
      final res = await _apiService.updateCashbook(id, {'name': newName});
      if (res['cashbook'] != null) {
        final index = _cashbooks.indexWhere((c) => c.id == id);
        if (index != -1) {
          _cashbooks[index] = CashbookModel.fromMap(res['cashbook']);
          await _saveLocalBooks();
          notifyListeners();
        }
      }
    } catch (e) {
      print('Failed to update cashbook online, queuing offline: $e');
      _isOfflineMode = true;
      await _localStorageService.addPendingSyncAction(
        action: 'update_cashbook',
        payload: {'name': newName},
        targetId: id,
      );
      _pendingCount++;
      notifyListeners();
    }
  }

  Future<void> deleteCashbook(String id) async {
    final bookIndex = _cashbooks.indexWhere((c) => c.id == id);
    if (bookIndex == -1) return;

    final deletedBook = _cashbooks[bookIndex];
    final associatedRecords = _records
        .where((r) => r.cashbookId == id)
        .toList();

    // Save backup state for local restore in Recovery Bin
    await RecoveryService.saveDeletedCashbook(deletedBook, associatedRecords);

    // Optimistic delete
    _cashbooks.removeWhere((c) => c.id == id);
    _records.removeWhere((r) => r.cashbookId == id);
    await _saveLocalBooks();
    await _saveLocalRecords();
    notifyListeners();

    if (_isOfflineMode) {
      await _localStorageService.addPendingSyncAction(
        action: 'delete_cashbook',
        payload: {'name': deletedBook.name},
        targetId: id,
      );
      _pendingCount++;
      notifyListeners();
      return;
    }

    // Do NOT block the UI. Fire and forget.
    _syncDeleteCashbook(id, deletedBook.name);
  }

  Future<void> _syncDeleteCashbook(String id, String name) async {
    try {
      await _apiService.deleteCashbook(id);
    } catch (e) {
      print('Failed to delete cashbook online, queuing offline: $e');
      _isOfflineMode = true;
      await _localStorageService.addPendingSyncAction(
        action: 'delete_cashbook',
        payload: {'name': name},
        targetId: id,
      );
      _pendingCount++;
      notifyListeners();
    }
  }

  // --- Records ---

  Future<void> addRecord(RecordModel record) async {
    final String tempId = record.id.isEmpty || record.id.startsWith('temp_')
        ? 'local_rec_${DateTime.now().millisecondsSinceEpoch}'
        : record.id;

    final newRecord = RecordModel(
      id: tempId,
      cashbookId: record.cashbookId,
      title: record.title,
      amount: record.amount,
      type: record.type,
      category: record.category,
      paymentMethod: record.paymentMethod,
      note: record.note,
      date: record.date,
      cashbookName: record.cashbookName,
    );

    // Optimistic insert
    _records.insert(0, newRecord);
    await _saveLocalRecords();

    // Trigger Notifications
    NotificationService().showTransactionNotification(
      amount: record.amount,
      isIncome: !record.isGiven,
      cashbook: record.cashbookName ?? 'Unknown',
    );
    // Reset inactivity timer since user added a transaction
    NotificationService().scheduleInactivityReminder();

    notifyListeners();

    if (_isOfflineMode) {
      await _localStorageService.addPendingSyncAction(
        action: 'create_record',
        payload: newRecord.toMap(),
      );
      _pendingCount++;
      notifyListeners();
      return;
    }

    // Do NOT block the UI. Fire and forget the API call.
    _syncNewRecord(tempId, newRecord);
  }

  Future<void> _syncNewRecord(String tempId, RecordModel newRecord) async {
    try {
      final res = await _apiService.createRecord(newRecord.toMap());
      if (res['record'] != null) {
        final index = _records.indexWhere((r) => r.id == tempId);
        if (index != -1) {
          var serverRecord = res['record'];
          serverRecord['cashbookName'] = newRecord.cashbookName;
          _records[index] = RecordModel.fromMap(serverRecord);
          await _saveLocalRecords();
          notifyListeners();
        }
      }
    } catch (e) {
      print('Failed to add record online, queuing offline: $e');
      _isOfflineMode = true;
      await _localStorageService.addPendingSyncAction(
        action: 'create_record',
        payload: newRecord.toMap(),
      );
      _pendingCount++;
      notifyListeners();
    }
  }

  Future<void> updateRecord(String id, Map<String, dynamic> data) async {
    // Optimistic update
    final index = _records.indexWhere((r) => r.id == id);
    if (index != -1) {
      final old = _records[index];
      _records[index] = RecordModel(
        id: old.id,
        cashbookId: old.cashbookId,
        title: data['title'] ?? old.title,
        amount: double.tryParse(data['amount']?.toString() ?? '') ?? old.amount,
        type: data['type'] ?? old.type,
        category: data['category'] ?? old.category,
        paymentMethod: data['paymentMethod'] ?? old.paymentMethod,
        note: data['note'] ?? old.note,
        date: data['transactionDate'] != null
            ? DateTime.parse(data['transactionDate'])
            : old.date,
        cashbookName: old.cashbookName,
      );
      await _saveLocalRecords();
      notifyListeners();
    }

    if (_isOfflineMode) {
      await _localStorageService.addPendingSyncAction(
        action: 'update_record',
        payload: data,
        targetId: id,
      );
      _pendingCount++;
      notifyListeners();
      return;
    }

    // Do NOT block the UI. Fire and forget.
    _syncUpdateRecord(id, data);
  }

  Future<void> _syncUpdateRecord(String id, Map<String, dynamic> data) async {
    try {
      final res = await _apiService.updateRecord(id, data);
      if (res['record'] != null) {
        final index = _records.indexWhere((r) => r.id == id);
        if (index != -1) {
          _records[index] = RecordModel.fromMap(res['record']);
          await _saveLocalRecords();
          notifyListeners();
        }
      }
    } catch (e) {
      print('Failed to update record online, queuing offline: $e');
      _isOfflineMode = true;
      await _localStorageService.addPendingSyncAction(
        action: 'update_record',
        payload: data,
        targetId: id,
      );
      _pendingCount++;
      notifyListeners();
    }
  }

  Future<void> deleteRecord(String id) async {
    // Save to recovery service first
    final recordIndex = _records.indexWhere((r) => r.id == id);
    if (recordIndex != -1) {
      await RecoveryService.saveDeletedRecord(_records[recordIndex]);
    }

    // Optimistic delete
    _records.removeWhere((record) => record.id == id);
    await _saveLocalRecords();
    notifyListeners();

    if (_isOfflineMode) {
      await _localStorageService.addPendingSyncAction(
        action: 'delete_record',
        payload: {},
        targetId: id,
      );
      _pendingCount++;
      notifyListeners();
      return;
    }

    // Do NOT block the UI. Fire and forget.
    _syncDeleteRecord(id);
  }

  Future<void> _syncDeleteRecord(String id) async {
    try {
      await _apiService.deleteRecord(id);
    } catch (e) {
      print('Failed to delete record online, queuing offline: $e');
      _isOfflineMode = true;
      await _localStorageService.addPendingSyncAction(
        action: 'delete_record',
        payload: {},
        targetId: id,
      );
      _pendingCount++;
      notifyListeners();
    }
  }

  // --- Helpers for Saving Cache ---

  Future<void> _saveLocalBooks() async {
    final List<Map<String, dynamic>> list = _cashbooks
        .map(
          (c) => {
            'id': c.id,
            'name': c.name,
            'createdAt': c.createdAt.toIso8601String(),
            'description': c.description,
          },
        )
        .toList();
    await _localStorageService.saveCashbooks(list);
  }

  Future<void> _saveLocalRecords() async {
    final List<Map<String, dynamic>> list = _records
        .map((r) => r.toMap())
        .toList();
    await _localStorageService.saveRecords(list);
  }

  // --- Background Synchronization Queue ---

  Future<void> syncOfflineQueue() async {
    if (_isSyncing) return;

    // Check guest bypass
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('auth_token') == 'offline_token') {
      return; // Guest mode stays purely offline
    }

    _isSyncing = true;
    notifyListeners();

    final queue = await _localStorageService.getPendingSyncQueue();
    print('Starting sync of ${queue.length} offline operations...');

    // Translation map for local cashbook IDs to server cashbook IDs
    final Map<String, String> cbIdTranslation = {};

    try {
      for (var actionItem in queue) {
        final String actionId = actionItem['id'];
        final String action = actionItem['action'];
        final Map<String, dynamic> payload = Map<String, dynamic>.from(
          actionItem['payload'],
        );
        final String? targetId = actionItem['targetId'];

        if (action == 'create_cashbook') {
          final localId = payload['id'];
          final name = payload['name'];

          final res = await _apiService.createCashbook({'name': name});
          if (res['cashbook'] != null) {
            final CashbookModel serverBook = CashbookModel.fromMap(
              res['cashbook'],
            );
            cbIdTranslation[localId] = serverBook.id;

            // Update local memory & cache
            final index = _cashbooks.indexWhere((c) => c.id == localId);
            if (index != -1) {
              _cashbooks[index] = serverBook;
            }
            // Update records that referenced this local cashbook ID
            for (int i = 0; i < _records.length; i++) {
              if (_records[i].cashbookId == localId) {
                final r = _records[i];
                _records[i] = RecordModel(
                  id: r.id,
                  cashbookId: serverBook.id,
                  title: r.title,
                  amount: r.amount,
                  type: r.type,
                  category: r.category,
                  paymentMethod: r.paymentMethod,
                  note: r.note,
                  date: r.date,
                  cashbookName: r.cashbookName,
                );
              }
            }
            await _localStorageService.removePendingSyncAction(actionId);
          }
        } else if (action == 'update_cashbook') {
          final realId = cbIdTranslation[targetId] ?? targetId!;
          await _apiService.updateCashbook(realId, {'name': payload['name']});
          await _localStorageService.removePendingSyncAction(actionId);
        } else if (action == 'delete_cashbook') {
          final realId = cbIdTranslation[targetId] ?? targetId!;
          await _apiService.deleteCashbook(realId);
          await _localStorageService.removePendingSyncAction(actionId);
        } else if (action == 'create_record') {
          final localCbId = payload['cashbookId'];
          // Translate cashbookId if it was a local temporary one
          if (cbIdTranslation.containsKey(localCbId)) {
            payload['cashbookId'] = cbIdTranslation[localCbId];
          } else {
            // Find cashbook by name to get correct server ID
            final book = _cashbooks.firstWhere(
              (c) => c.name == payload['cashbookName'],
              orElse: () =>
                  CashbookModel(id: '', name: '', createdAt: DateTime.now()),
            );
            if (book.id.isNotEmpty && !book.id.startsWith('local_cb_')) {
              payload['cashbookId'] = book.id;
            }
          }

          final localRecId = payload['id'];
          final res = await _apiService.createRecord(payload);
          if (res['record'] != null) {
            final RecordModel serverRecord = RecordModel.fromMap(res['record']);
            final index = _records.indexWhere((r) => r.id == localRecId);
            if (index != -1) {
              _records[index] = serverRecord;
            }
            await _localStorageService.removePendingSyncAction(actionId);
          }
        } else if (action == 'update_record') {
          await _apiService.updateRecord(targetId!, payload);
          await _localStorageService.removePendingSyncAction(actionId);
        } else if (action == 'delete_record') {
          await _apiService.deleteRecord(targetId!);
          await _localStorageService.removePendingSyncAction(actionId);
        }
      }

      // If we finished the loop successfully, save local files with mapped IDs
      await _saveLocalBooks();
      await _saveLocalRecords();

      final remainingQueue = await _localStorageService.getPendingSyncQueue();
      _pendingCount = remainingQueue.length;

      if (_pendingCount == 0) {
        _isOfflineMode = false;
        print('Offline synchronization fully completed successfully!');
        // Refresh with server to align perfectly
        await fetchData();
      }
    } catch (e) {
      print('Offline synchronization interrupted or failed: $e');
    } finally {
      _isSyncing = false;
      final currentQueue = await _localStorageService.getPendingSyncQueue();
      _pendingCount = currentQueue.length;
      notifyListeners();
    }
  }

  // --- Balance Getters ---

  double get totalGiven {
    return _records
        .where((record) => record.isGiven)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalReceived {
    return _records
        .where((record) => !record.isGiven)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get balance {
    return totalReceived - totalGiven;
  }

  void clear() {
    _records = [];
    _cashbooks = [];
    _error = null;
    _isOfflineMode = false;
    _pendingCount = 0;
    notifyListeners();
  }
}
