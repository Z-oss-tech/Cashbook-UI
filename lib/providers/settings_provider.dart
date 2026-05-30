import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  SharedPreferences? _prefs;

  bool _darkMode = false;
  bool _notifications = true;
  bool _biometricLock = false;
  
  String _userName = "SmartKhata User";
  String _userAvatar = "S";
  
  Locale _locale = const Locale('en');

  bool get darkMode => _darkMode;
  bool get notifications => _notifications;
  bool get biometricLock => _biometricLock;
  String get userName => _userName;
  String get userAvatar => _userAvatar;
  Locale get locale => _locale;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    
    _darkMode = _prefs?.getBool('darkMode') ?? false;
    _notifications = _prefs?.getBool('notifications') ?? true;
    _biometricLock = _prefs?.getBool('biometricLock') ?? false;
    
    _userName = _prefs?.getString('userName') ?? "SmartKhata User";
    if (_userName.isNotEmpty) {
      _userAvatar = _userName.substring(0, 1).toUpperCase();
    } else {
      _userAvatar = "U";
    }
    
    final String languageCode = _prefs?.getString('languageCode') ?? 'en';
    _locale = Locale(languageCode);

    notifyListeners();
  }

  void setDarkMode(bool value) {
    _darkMode = value;
    _prefs?.setBool('darkMode', value);
    notifyListeners();
  }

  void setNotifications(bool value) {
    _notifications = value;
    _prefs?.setBool('notifications', value);
    notifyListeners();
  }

  void setBiometricLock(bool value) {
    _biometricLock = value;
    _prefs?.setBool('biometricLock', value);
    notifyListeners();
  }
  
  void setUserName(String name) {
    _userName = name;
    _prefs?.setString('userName', name);
    if (name.isNotEmpty) {
      _userAvatar = name.substring(0, 1).toUpperCase();
    }
    notifyListeners();
  }
  
  void setLocale(Locale newLocale) {
    _locale = newLocale;
    _prefs?.setString('languageCode', newLocale.languageCode);
    notifyListeners();
  }
  
  Future<void> clearAllSettings() async {
    await _prefs?.clear();
    await _loadSettings();
  }
}
