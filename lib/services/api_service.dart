import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use Localtunnel to securely bypass Windows Firewall so your real phone can connect instantly
  // static const String baseUrl = 'https://stupid-geckos-obey.loca.lt/api';
  
  // Local LAN IP for reliable development
  // static const String baseUrl = 'http://10.234.18.43:3000/api';
  
  // Live Production Server
  static const String baseUrl = 'https://cashbook-a3kn.onrender.com/api';

  static const String _tokenKey = 'auth_token';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Bypass-Tunnel-Reminder': 'true', // Required for Localtunnel API access
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- Auth ---

  Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await _post('/auth/login', {'username': username, 'password': password});
    if (res['token'] != null) {
      await saveToken(res['token']);
    }
    return res;
  }

  Future<Map<String, dynamic>> register(String username, String password, {String? name, String? email}) async {
    final res = await _post('/auth/register', {
      'username': username, 
      'password': password,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
    });
    if (res['token'] != null) {
      await saveToken(res['token']);
    }
    return res;
  }

  Future<Map<String, dynamic>> googleLogin({
    required String googleId,
    required String email,
    String? name,
    String? avatarUrl,
  }) async {
    final res = await _post('/auth/google', {
      'googleId': googleId,
      'email': email,
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    });
    if (res['token'] != null) {
      await saveToken(res['token']);
    }
    return res;
  }

  
  Future<Map<String, dynamic>> getCurrentUser() async {
    return await _get('/auth/me');
  }

  Future<Map<String, dynamic>> updateProfile({required String name, required String email}) async {
    return await _post('/auth/update-profile', {
      'name': name,
      'email': email,
    });
  }

  Future<Map<String, dynamic>> changePassword({required String currentPassword, required String newPassword}) async {
    return await _post('/auth/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  // --- Cashbooks ---

  Future<List<dynamic>> getCashbooks() async {
    final res = await _get('/cashbooks');
    return res is List ? res : (res['cashbooks'] ?? []);
  }

  Future<Map<String, dynamic>> createCashbook(Map<String, dynamic> data) async {
    return await _post('/cashbooks', data);
  }

  Future<Map<String, dynamic>> getCashbookSummary(String id) async {
    return await _get('/cashbooks/$id/summary');
  }

  Future<Map<String, dynamic>> updateCashbook(String id, Map<String, dynamic> data) async {
    return await _put('/cashbooks/$id', data);
  }

  Future<void> deleteCashbook(String id) async {
    await _delete('/cashbooks/$id');
  }

  // --- Records ---

  Future<List<dynamic>> getRecords() async {
    final res = await _get('/records');
    return res is List ? res : (res['records'] ?? []);
  }

  Future<Map<String, dynamic>> createRecord(Map<String, dynamic> data) async {
    return await _post('/records', data);
  }

  Future<Map<String, dynamic>> updateRecord(String id, Map<String, dynamic> data) async {
    return await _put('/records/$id', data);
  }

  Future<void> deleteRecord(String id) async {
    await _delete('/records/$id');
  }

  // --- Base HTTP Methods ---

  Future<dynamic> _get(String path) async {
    int retries = 2;
    while (retries > 0) {
      try {
        final response = await http
            .get(Uri.parse('$baseUrl$path'), headers: await _getHeaders())
            .timeout(const Duration(seconds: 5));
        
        if (response.statusCode == 502 || response.statusCode == 503 || response.statusCode == 504) {
          retries--;
          if (retries == 0) return _handleResponse(response);
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
        
        return _handleResponse(response);
      } on SocketException {
        retries--;
        if (retries == 0) throw Exception('network_error: Connection failed. Check your network.');
        await Future.delayed(const Duration(seconds: 3));
      } on TimeoutException {
        retries--;
        if (retries == 0) throw Exception('network_error: Connection timed out. Please try again.');
        await Future.delayed(const Duration(seconds: 3));
      } catch (e) {
        if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
          retries--;
          if (retries == 0) throw Exception('network_error: Connection failed.');
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
        rethrow;
      }
    }
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    int retries = 2;
    while (retries > 0) {
      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl$path'),
              headers: await _getHeaders(),
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 5));
        
        if (response.statusCode == 502 || response.statusCode == 503 || response.statusCode == 504) {
          retries--;
          if (retries == 0) return _handleResponse(response);
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
        
        return _handleResponse(response);
      } on SocketException {
        retries--;
        if (retries == 0) throw Exception('network_error: Connection failed. Check your network.');
        await Future.delayed(const Duration(seconds: 3));
      } on TimeoutException {
        retries--;
        if (retries == 0) throw Exception('network_error: Connection timed out. Please try again.');
        await Future.delayed(const Duration(seconds: 3));
      } catch (e) {
        if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
          retries--;
          if (retries == 0) throw Exception('network_error: Connection failed.');
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
        rethrow;
      }
    }
  }

  Future<dynamic> _put(String path, Map<String, dynamic> body) async {
    int retries = 2;
    while (retries > 0) {
      try {
        final response = await http
            .put(
              Uri.parse('$baseUrl$path'),
              headers: await _getHeaders(),
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 5));
        
        if (response.statusCode == 502 || response.statusCode == 503 || response.statusCode == 504) {
          retries--;
          if (retries == 0) return _handleResponse(response);
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
        
        return _handleResponse(response);
      } on SocketException {
        retries--;
        if (retries == 0) throw Exception('network_error: Connection failed. Check your network.');
        await Future.delayed(const Duration(seconds: 3));
      } on TimeoutException {
        retries--;
        if (retries == 0) throw Exception('network_error: Connection timed out. Please try again.');
        await Future.delayed(const Duration(seconds: 3));
      } catch (e) {
        if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
          retries--;
          if (retries == 0) throw Exception('network_error: Connection failed.');
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
        rethrow;
      }
    }
  }

  Future<dynamic> _delete(String path) async {
    int retries = 2;
    while (retries > 0) {
      try {
        final response = await http
            .delete(Uri.parse('$baseUrl$path'), headers: await _getHeaders())
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 204) return null;
        
        if (response.statusCode == 502 || response.statusCode == 503 || response.statusCode == 504) {
          retries--;
          if (retries == 0) return _handleResponse(response);
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
        
        return _handleResponse(response);
      } on SocketException {
        retries--;
        if (retries == 0) throw Exception('network_error: Connection failed. Check your network.');
        await Future.delayed(const Duration(seconds: 3));
      } on TimeoutException {
        retries--;
        if (retries == 0) throw Exception('network_error: Connection timed out. Please try again.');
        await Future.delayed(const Duration(seconds: 3));
      } catch (e) {
        if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
          retries--;
          if (retries == 0) throw Exception('network_error: Connection failed.');
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
        rethrow;
      }
    }
  }

  Future<Map<String, dynamic>> getLatestAppUpdate() async {
    try {
      return await _get('/updates/latest');
    } catch (e) {
      if (e.toString().contains('404')) {
        return {'updateAvailable': false};
      }
      rethrow;
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      final json = jsonDecode(response.body);
      
      // Unwrap the 'data' field if the API wraps responses (e.g. from ok() function)
      if (json is Map<String, dynamic> && json.containsKey('data')) {
        return json['data'];
      }
      
      return json;
    } else {
      // Clean up server gateway errors (502, 503, 504) commonly caused by free tier sleeping containers
      if (response.statusCode == 502 || response.statusCode == 503 || response.statusCode == 504) {
        throw Exception('The cloud server is temporarily busy. Please try again in a few seconds.');
      }

      String? extractedError;
      try {
        final errJson = jsonDecode(response.body);
        if (errJson is Map<String, dynamic>) {
          extractedError = errJson['message'] ?? errJson['error'] ?? errJson['msg'];
        }
      } catch (_) {
        // Ignore JSON parsing errors
      }

      if (extractedError != null) {
        throw Exception(extractedError);
      }

      throw Exception('Server error (${response.statusCode}). Please try again.');
    }
  }
}
