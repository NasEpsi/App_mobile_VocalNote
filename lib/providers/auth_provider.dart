import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

/// Holds the current authentication state and persists the session.
class AuthProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();

  static const String _prefsKey = 'current_username';

  AppUser? _currentUser;
  bool _initialized = false;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _initialized;

  /// Restores a previous session (if any) from local storage.
  Future<void> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString(_prefsKey);
      if (username != null) {
        _currentUser = await _auth.getUserByUsername(username);
      }
    } catch (_) {
      _currentUser = null;
    }
    _initialized = true;
    notifyListeners();
  }

  Future<String?> register(String username, String password) async {
    final result = await _auth.register(username, password);
    if (result.isSuccess) {
      await _setSession(result.user!);
      return null;
    }
    return result.error;
  }

  Future<String?> login(String username, String password) async {
    final result = await _auth.login(username, password);
    if (result.isSuccess) {
      await _setSession(result.user!);
      return null;
    }
    return result.error;
  }

  Future<void> _setSession(AppUser user) async {
    _currentUser = user;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, user.username);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
    notifyListeners();
  }
}
