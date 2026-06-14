import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsign;

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Set error state
  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> login(String username, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      final res = await _apiService.login(username, password);
      _setLoading(false);
      if (res['token'] != null) {
        return res;
      }
      return null;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      
      // If server is down, fallback to offline
      /*
      if (e.toString().contains('network_error') || e.toString().contains('unavailable') || e.toString().contains('busy')) {
        await loginOffline();
        return {'token': 'offline_token', 'isNewUser': false};
      }
      */
      return null;
    }
  }

  Future<Map<String, dynamic>?> register(String username, String password, {String? name, String? email}) async {
    _setLoading(true);
    _setError(null);
    try {
      final res = await _apiService.register(username, password, name: name, email: email);
      _setLoading(false);
      if (res['token'] != null) {
        return res;
      }
      return null;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      
      // If server is down, fallback to offline
      /*
      if (e.toString().contains('network_error') || e.toString().contains('unavailable') || e.toString().contains('busy')) {
        await loginOffline();
        return {'token': 'offline_token', 'isNewUser': false};
      }
      */
      return null;
    }
  }

  Future<bool> updateProfile(String name, String email) async {
    _setLoading(true);
    _setError(null);
    try {
      await _apiService.updateProfile(name: name, email: email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _setLoading(true);
    _setError(null);
    try {
      await _apiService.changePassword(currentPassword: currentPassword, newPassword: newPassword);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  Future<Map<String, dynamic>?> googleLogin() async {
    _setLoading(true);
    _setError(null);
    try {
      // Direct sign in attempt
      gsign.GoogleSignInAccount googleUser;
      try {
        await gsign.GoogleSignIn.instance.initialize(
          serverClientId: '756245615589-ir1pno90qig2uk9ad1fa45hgohg7bkfk.apps.googleusercontent.com',
        );
      } catch (_) {
        // Ignore initialization error if already initialized or if Web ID is wrong
      }

      googleUser = await gsign.GoogleSignIn.instance.authenticate();

      final res = await _apiService.googleLogin(
        googleId: googleUser.id,
        email: googleUser.email,
        name: googleUser.displayName,
        avatarUrl: googleUser.photoUrl,
      );

      _setLoading(false);
      return res;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return null;
    }
  }

  Future<Map<String, dynamic>?> bypassGoogleLoginForDemo() async {
    return bypassGoogleLoginForDemoWithArgs(
      googleId: 'mock_google_id_99999_demo',
      email: 'boss_demo@smartkhata.com',
      name: 'Demo Boss 👑',
      avatarUrl: 'https://lh3.googleusercontent.com/a/default-user=s96-c',
    );
  }

  Future<Map<String, dynamic>?> bypassGoogleLoginForDemoWithArgs({
    required String googleId,
    required String email,
    required String name,
    required String avatarUrl,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final res = await _apiService.googleLogin(
        googleId: googleId,
        email: email,
        name: name,
        avatarUrl: avatarUrl,
      );
      _setLoading(false);
      return res;
    } catch (e) {
      // If even the demo bypass fails because the server is completely down, log them in fully offline!
      print('Server completely unreachable. Falling back to Full Offline Mode.');
      await loginOffline();
      _setLoading(false);
      return {
        'user': {
          'name': 'Offline User',
          'email': 'offline@local.com',
        },
        'token': 'offline_token'
      };
    }
  }

  Future<void> loginOffline() async {
    _setLoading(true);
    _setError(null);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', 'offline_token');
      await prefs.setString('userName', 'Offline Guest');
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<bool> isOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') == 'offline_token';
  }

  Future<bool> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') != null;
  }

  Future<void> logout() async {
    await _apiService.clearToken();
    await LocalStorageService().clearAll();
    notifyListeners();
  }
}
