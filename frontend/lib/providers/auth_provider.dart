import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isAuthenticated = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId != null) {
      try {
        _currentUser = await ApiService.getUser(int.parse(userId));
        _isAuthenticated = true;
        notifyListeners();
      } catch (e) {
        logout();
      }
    }
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final result = await ApiService.register(
        username: username,
        email: email,
        password: password,
      );
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', result['user']['id'].toString());
      
      _currentUser = User.fromJson(result['user']);
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await ApiService.login(email: email, password: password);
      _currentUser = User.fromJson(result['user']);
      _isAuthenticated = true;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', result['user']['id'].toString());
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}