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

  Future<String?> sendOtp(String phone) async {
    _setLoading(true);
    _setError(null);
    try {
      final res = await _apiService.sendOtp(phone);
      _setLoading(false);
      print('OTP Sent: ${res['devOtp']}');
      return res['devOtp']?.toString();
    } catch (e) {
      // Auto-fallback to offline mode if server fails
      print('Server down, simulating OTP for offline mode: $e');
      _setLoading(false);
      return '1234'; // Dummy OTP to allow them to proceed offline
    }
  }

  Future<bool> resendOtp(String phone) async {
    _setLoading(true);
    _setError(null);
    try {
      final res = await _apiService.resendOtp(phone);
      _setLoading(false);
      print('OTP Resent: ${res['devOtp']}');
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  Future<Map<String, dynamic>?> verifyOtp(String phone, String otp) async {
    _setLoading(true);
    _setError(null);
    try {
      final res = await _apiService.verifyOtp(phone, otp);
      _setLoading(false);
      if (res['token'] != null) {
        return res; // Return the entire response so we know if isNewUser
      }
      return null;
    } catch (e) {
      // Auto-fallback to offline mode instead of completely blocking the user
      print("Server unavailable, auto-switching to offline mode for OTP verify: $e");
      await loginOffline();
      _setLoading(false);
      return {'token': 'offline_token', 'isNewUser': false};
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
    _setLoading(true);
    _setError(null);
    try {
      // Connect directly to live backend cloud API using a clean demo boss profile
      final res = await _apiService.googleLogin(
        googleId: 'mock_google_id_99999_demo',
        email: 'boss_demo@smartkhata.com',
        name: 'Demo Boss 👑',
        avatarUrl: 'https://lh3.googleusercontent.com/a/default-user=s96-c',
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
